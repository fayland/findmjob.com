package FindmJob::Scrape::Github;

use Moo;
with 'FindmJob::Scrape::Role';

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

    # set socks proxy (Tor)
    my $config = $self->config;
    $self->ua->proxy(['http', 'https'], $config->{scrape}->{proxy})
        if $config->{scrape}->{proxy};

    my $resp = $self->get('https://jobs.github.com/positions.json');
    my $data = $json->decode( decode('utf8', $resp->content) );
    foreach my $item (@$data) {
        my $link = $item->{url};

        my $is_inserted = $job_rs->is_inserted_by_url($link);
        next if $is_inserted and not $self->opt_update;

        my $desc = $self->format_text($item->{description});

        my @tags = $self->get_extra_tags_from_desc($item->{title});
        push @tags, $self->get_extra_tags_from_desc($desc);

        my $row = {
            source_url => $link,
            title => $item->{title},
            company => {
                name => $item->{company},
                website => $item->{company_url},
            },
            contact   => $item->{how_to_apply},
            posted_at => human_to_db_datetime($item->{created_at}),
            description => $desc,
            location => $item->{location},
            type     => $item->{type},
            extra    => $json->encode({
                company_logo => $item->{company_logo},
            }),
            tags     => ['github', @tags],
        };
        $row->{location_id} = $self->get_location_id_from_text($row->{location}) if $row->{location};
        if ( $is_inserted and $self->opt_update ) {
            $job_rs->update_job($row);
        } else {
            $job_rs->create_job($row);
        }
    }
}

1;