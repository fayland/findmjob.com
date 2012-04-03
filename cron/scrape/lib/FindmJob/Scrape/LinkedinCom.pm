package FindmJob::Scrape::LinkedinCom;

use Moose;
with 'FindmJob::Scrape::Role';
with 'FindmJob::Scrape::Role::TextFormatter';

use Try::Tiny;
use Data::Dumper;
use JSON::XS qw/encode_json decode_json/;
use FindmJob::DateUtils 'human_to_db_datetime';
use Encode;
use WWW::LinkedIn;

sub run {
    my ($self) = @_;

    # read the token from script/oneoff/linkedin.token.txt
    my $root = $self->root;
    my $file = $root . "/script/oneoff/linkedin.token.txt";
    open(my $fh, '<', $file) or die "Can't get $file";
    my $line = <$fh>;
    close($fh);
    chomp($line);
    my ($_x, $_x2, $token, $secret) = split(/\|/, $line);

    my $schema = $self->schema;
    my $job_rs = $schema->resultset('Job');
    my $json = JSON::XS->new->utf8;

    my $config = $self->config;
    my $api = $config->{api}->{linkedin};
    my $li = WWW::LinkedIn->new(
        consumer_key    => $api->{key},
        consumer_secret => $api->{secret},
    );
    my $job_json = $li->request(
        request_url         => 'http://api.linkedin.com/v1/job-search?format=json',
        access_token        => $token,
        access_token_secret => $secret,
    );

    my $data = $json->decode( $job_json );
    foreach my $item (@{$data->{jobs}->{values}}) {
        my $id   = $item->{id};

        my $link = 'http://www.linkedin.com/jobs?viewJob=&jobId=' . $id;
        my $is_inserted = $job_rs->is_inserted_by_url($link);
        next if $is_inserted and not $self->opt_update;

        $job_json = $li->request(
            request_url         => 'http://api.linkedin.com/v1/jobs/' . $id . ':(id,customer-job-code,active,posting-date,expiration-date,posting-timestamp,company:(id,name),position:(title,location,job-functions,industries,job-type,experience-level),skills-and-experience,description,salary,job-poster:(id,first-name,last-name,headline),referral-bonus,site-job-url,location-description)?format=json',
            access_token        => $token,
            access_token_secret => $secret,
        );
        my $r = $json->decode( $job_json );

        my $desc = $self->format_text(delete $r->{description});
        my $company = $r->{company}->{id};

        my @tags = map { $_->{name} } @{$r->{position}->{jobFunctions}->{values}};
        my $pd = $r->{postingDate};
        my $postingDate = sprintf('%04d-%02d-%02d', $pd->{year}, $pd->{month}, $pd->{day});

        my $row = {
            source_url => $link,
            title => delete $r->{title},
            company => {
                name => $r->{company}->{name},
                website => $item->{company_url},
            },
            contact   => '',
            posted_at => $postingDate,
            description => $desc,
            location => $r->{location}->{name},
            type     => $r->{jobType}->{name},
            extra    => $json->encode($r),
            tags     => ['linkedin', @tags],
        };
        if ( $is_inserted and $self->opt_update ) {
            $self->schema->resultset('Job')->update_job($row);
        } else {
            $self->schema->resultset('Job')->create_job($row);
        }
    }
}

1;