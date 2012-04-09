package FindmJob::Scrape::oDesk;

use Moose;
with 'FindmJob::Scrape::Role';

use Try::Tiny;
use Data::Dumper;
use JSON::XS qw/encode_json decode_json/;
use FindmJob::DateUtils 'human_to_db_date';
use Encode;

sub run {
    my ($self) = @_;

    my $schema = $self->schema;
    my $job_rs = $schema->resultset('Job');
    my $json = JSON::XS->new->utf8;

    my $resp = $self->get('https://www.odesk.com/api/profiles/v1/search/jobs.json');
    my $data = $json->decode( decode('utf8', $resp->content) );
    foreach my $item (@{$data->{jobs}->{job}}) {
        # engagement_weeks must be more than "Ongoing / More than 6 months" or "3 to 6 months"
        next unless ( $item->{engagement_weeks} =~ /6 month/ or $item->{engagement_weeks} =~ /Ongoing/ );
        next unless $item->{op_comm_status} =~ /Active/;
        next unless $item->{op_is_viewable} == 1;

        foreach my $key (keys %$item) {
            if (grep { $key eq $_ } (qw/op_comm_status op_desc_digest candidates_total_active search_status/)) {
                delete $item->{$key};
            }
            delete $item->{$key} if $key =~ /op_pref/ or $key =~ /interviewees/ or $key =~ /op_is/
                or $key =~ /op_avg/ or $key =~ /op_low/ or $key =~ /op_high/;
        }

        my $link = "https://www.odesk.com/jobs/" . $item->{ciphertext};

        my @tags = split(/,\s*/, delete $item->{op_required_skills});

        my $desc = $self->format_text(delete $item->{op_description});

        my $is_inserted = $job_rs->is_inserted_by_url($link);
        next if $is_inserted and not $self->opt_update;
        my $row = {
            source_url => $link,
            title => delete $item->{op_title},
            company => {
                name => "oDesk $item->{job_category_level_one}",
            },
            contact   => '',
            posted_at => human_to_db_date($item->{date_posted}) . ' ' . $item->{op_time_posted},
            description => $desc,
            location => delete $item->{op_country},
            type     => delete$item->{op_engagement},
            extra    => $json->encode($item),
            tags     => ['odesk', @tags],
        };
        if ( $is_inserted and $self->opt_update ) {
            $self->schema->resultset('Job')->update_job($row);
        } else {
            $self->schema->resultset('Job')->create_job($row);
        }
    }
}

1;