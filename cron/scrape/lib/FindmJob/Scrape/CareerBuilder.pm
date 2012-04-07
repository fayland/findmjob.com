package FindmJob::Scrape::CareerBuilder;

use Moose;
with 'FindmJob::Scrape::Role';
with 'FindmJob::Scrape::Role::TextFormatter';

use Try::Tiny;
use Data::Dumper;
use XML::Simple 'XMLin';
use FindmJob::DateUtils 'human_to_db_datetime';
use Encode;
use JSON::XS ();
use HTML::Entities;

sub run {
    my ($self) = @_;

    my $schema = $self->schema;
    my $job_rs = $schema->resultset('Job');
    my $json = JSON::XS->new->utf8;

    my $config = $self->config;
    my $api = $config->{api}->{CareerBuilder};

    my $url = "http://api.careerbuilder.com/v1/jobsearch?DeveloperKey=$api->{key}&OrderBy=Date&OrderDirection=DESC";
    my $resp = $self->ua->get($url);
    my $data = XMLin($resp->decoded_content, SuppressEmpty => '');
    foreach my $item (@{ $data->{Results}->{JobSearchResult} }) {
        my $link = 'http://www.careerbuilder.com/JobSeeker/Jobs/JobDetails.aspx?Job_DID=' . $item->{DID};
        my $is_inserted = $job_rs->is_inserted_by_url($link);
        next if $is_inserted and not $self->opt_update;

        # we need more stuff so we dig into it
        $url  = $item->{JobServiceURL};
        $resp = $self->ua->get($url);
        sleep 3;
        my $r = XMLin($resp->decoded_content, SuppressEmpty => '');
        $r = $r->{Job};
        next unless $r and $r->{BeginDate};

        my @tags = split(/\,\s+/, delete $r->{Categories});

        my $desc = decode_entities(delete $r->{JobDescription});
        $desc = $self->format_text($desc);
        my $JobRequirements = decode_entities(delete $r->{JobRequirements});
        $JobRequirements = $self->format_text($JobRequirements);
        $r->{JobRequirements} = $JobRequirements;

        my $row = {
            source_url => $link,
            title => delete $r->{JobTitle},
            company => {
                name => delete $r->{Company},
                ref  => "careerbuilder-" . $r->{CompanyDID},
                extra => $json->encode({
                    CompanyImageURL => delete $r->{CompanyImageURL},
                }),
            },
            contact   => '',
            posted_at => human_to_db_datetime(delete $r->{BeginDate}),
            description => $desc,
            location => join(', ', grep { length($_) } (delete $r->{LocationCity}, delete $r->{LocationState}, delete $r->{LocationCountry})),
            type     => delete $r->{EmploymentType},
            extra    => $json->encode($r),
            tags     => ['careerbuilder', @tags],
        };
        if ( $is_inserted and $self->opt_update ) {
            $self->schema->resultset('Job')->update_job($row);
        } else {
            $self->schema->resultset('Job')->create_job($row);
        }
    }
}

1;