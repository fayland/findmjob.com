package FindmJob::Scrape::CareerBuilder;

use Moose;
use namespace::autoclean;

with 'FindmJob::Scrape::Role';

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

        my $desc = decode_entities(delete $r->{JobDescription});
        $desc = $self->format_text($desc);
        my $JobRequirements = decode_entities(delete $r->{JobRequirements});
        $JobRequirements = $self->format_text($JobRequirements);
        $r->{JobRequirements} = $JobRequirements;

        my @tags = $self->get_extra_tags_from_desc($r->{JobTitle});
        push @tags, $self->get_extra_tags_from_desc($desc);
        push @tags, $self->get_extra_tags_from_desc($r->{JobRequirements});

        ## we really don't want follow some industries, mainly I want to do the IT jobs I think
        ## and only when there is no tags we loved
        unless (@tags) {
            # 'Other' is usually bad as we found
            my @bad_industries = ('Restaurant - Food Service', 'Retail', 'Real Estate', 'Automotive', 'Other', 'Skilled Labor - Trades', 'Transportation', 'Admin - Clerical', 'Health Care', 'Nurse', 'Professional Services', 'Accounting', 'Customer Service', 'Business Development', 'Banking', 'Executive', 'Legal', 'Construction', 'Hospitality - Hotel', 'Management', 'Manufacturing');
            my %bad_industries = map { $_ => 1 } @bad_industries;
            my @categories = split(/\,\s*/, $r->{Categories});
            @categories = grep { not $bad_industries{$_} } @categories;
            next unless @categories;
        }

        push @tags, split(/\,\s*/, $r->{Categories});

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
            posted_at  => human_to_db_datetime(delete $r->{BeginDate}),
            expired_at => human_to_db_datetime(delete $r->{EndDate}),
            description => $desc,
            location => join(', ', grep { length($_) } (delete $r->{LocationCity}, delete $r->{LocationState}, delete $r->{LocationCountry})),
            type     => delete $r->{EmploymentType},
            extra    => $json->encode($r),
            tags     => ['careerbuilder', @tags],
        };
        if ( $is_inserted and $self->opt_update ) {
            $job_rs->update_job($row);
        } else {
            $job_rs->create_job($row);
        }
    }
}

__PACKAGE__->meta->make_immutable;

1;