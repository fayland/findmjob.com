package FindmJob::Scrape::JobsGithubCom;

use Moose;
with 'FindmJob::Scrape::Role';
with 'FindmJob::Scrape::Role::TextFormatter';

use Try::Tiny;
use Data::Dumper;
use JSON::XS qw/encode_json decode_json/;
use FindmJob::DateUtils 'human_to_db_date';

sub run {
    my ($self) = @_;

    my $schema = $self->schema;
    my $job_rs = $schema->resultset('Job');

    my $resp = $self->get('https://jobs.github.com/positions.json');
    my $data = decode_json($resp->decoded_content);
    foreach my $item (@$data) {
        my $link = $item->{url};

        my $is_inserted = $job_rs->is_inserted_by_url($link);
        next if $is_inserted and not $self->opt_update;
        my $row = {
            source_url => $link,
            title => $item->{title},
            company => {
                name => $item->{company},
                website => $item->{company_url},
            },
            contact   => $item->{how_to_apply},
            posted_at => human_to_db_date($item->{created_at}),
            description => $item->{description},
            location => $item->{location},
            type     => $item->{type},
            extra    => encode_json({
                company_logo => $item->{company_logo},
            }),
        };
        if ( $is_inserted and $self->opt_update ) {
            $self->schema->resultset('Job')->update_job($row);
        } else {
            $self->schema->resultset('Job')->create_job($row);
        }
    }
}

1;