package FindmJob::Scrape::ElanceCom;

use Moose;
with 'FindmJob::Scrape::Role';
with 'FindmJob::Scrape::Role::TextFormatter';

use Try::Tiny;
use Data::Dumper;
use JSON::XS qw/encode_json decode_json/;
use FindmJob::DateUtils 'human_to_db_datetime';
use Encode;

sub run {
    my ($self) = @_;

    my $schema = $self->schema;
    my $job_rs = $schema->resultset('Job');
    my $json = JSON::XS->new->utf8;

    my $config = $self->config;
    my $api = $config->{api}->{elance};

    # read the token from script/oneoff/elance.token.txt
    my $root = $self->root;
    my $file = $root . "/script/oneoff/elance.token.txt";
    open(my $fh, '<', $file) or die "Can't get $file";
    my $line = <$fh>;
    close($fh);
    chomp($line);
    my ($access_token, $expires_in, $token_type, $refresh_token) = split(/\,/, $line);

    # refresh it if it's near expiry
    if ($expires_in < time() - 86400) {
        my $resp = $self->ua->post('https://www.elance.com/api2/oauth/token', [
            refresh_token => $refresh_token,
            grant_type => 'refresh_token',
            client_id  => $api->{key},
            client_secret => $api->{secret},
        ]);
        my $d = decode_json($resp->decoded_content);
        if ($d->{errors}) {
            die Dumper(\$d);
        }
        $d = $d->{data};
        open(my $fh, '>', $file);
        print $fh join(',', $d->{access_token}, $d->{expires_in}, $d->{token_type}, $d->{refresh_token}, $d->{scope});
        close($fh);
        $access_token = $d->{access_token};
    }

    my $url = "http://api.elance.com/api2/jobs?access_token=$access_token&sortCol=startDate&sortOrder=desc";
    my $resp = $self->ua->get($url);
    my $data = $json->decode( $resp->decoded_content );
    foreach my $item (values %{$data->{data}->{pageResults}}) {
        next unless ref $item eq 'HASH';
        my $link = $item->{jobURL};
        my $is_inserted = $job_rs->is_inserted_by_url($link);
        next if $is_inserted and not $self->opt_update;

        next unless $item->{budgetMin} and $item->{budgetMin} >= 500; # only scrape those more than 500$

        # we need more stuff so we dig into it
        my $jobId = $item->{jobId};
        $url = "http://api.elance.com/api2/jobs/$jobId?access_token=$access_token";
        $resp = $self->ua->get($url);
        $data = $json->decode( $resp->decoded_content );
        sleep 3;
        my $r = $data->{data}->{jobData};

        my @tags =  split(/\,\s+/, delete $r->{skillTags});
        push @tags, delete $r->{subcategory};

        my $row = {
            source_url => $link,
            title => delete $r->{name},
            company => {
                name => "Elance $r->{category}",
            },
            contact   => '',
            posted_at => human_to_db_datetime(delete $r->{postedDate}),
            description => delete $r->{description},
            location => delete $r->{location},
            type     => '',
            extra    => $json->encode($r),
            tags     => ['elance', @tags],
        };
        if ( $is_inserted and $self->opt_update ) {
            $self->schema->resultset('Job')->update_job($row);
        } else {
            $self->schema->resultset('Job')->create_job($row);
        }
    }
}

1;