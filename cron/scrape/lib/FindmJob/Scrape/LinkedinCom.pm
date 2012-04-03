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
        request_url         => 'http://api.linkedin.com/v1/job-search:(jobs:(id,customer-job-code,active,posting-date,expiration-date,posting-timestamp,expiration-timestamp,company:(id,name),position:(title,location,job-functions,industries,job-type,experience-level),skills-and-experience,description-snippet,description,salary,job-poster:(id,first-name,last-name,headline),referral-bonus,site-job-url,location-description))?format=json&count=20&sort=DD',
        access_token        => $token,
        access_token_secret => $secret,
    );

    my $data = $json->decode( $job_json );
    foreach my $r (@{$data->{jobs}->{values}}) {
        my $id   = $r->{id};

        my $link = 'http://www.linkedin.com/jobs?viewJob=&jobId=' . $id;
        my $is_inserted = $job_rs->is_inserted_by_url($link);
        next if $is_inserted and not $self->opt_update;

        my $desc = $self->format_text(delete $r->{description});

        # some row return company->id, others just return name
        my $company;
        if ($r->{company}->{id}) {
            my $li_cid = $r->{company}->{id};
            $company = $schema->resultset('Company')->get_by_ref("linkedin-$li_cid");
            unless ($company) {
                $job_json = $li->request(
                    request_url         => 'http://api.linkedin.com/v1/companies/' . $li_cid . ':(id,name,universal-name,email-domains,company-type,ticker,website-url,industry,status,logo-url,square-logo-url,blog-rss-url,twitter-id,employee-count-range,specialties,locations:(description,is-headquarters,is-active,address:(street1,street2,city,state,postal-code,country-code,region-code),contact-info:(phone1,phone2,fax)),description,stock-exchange,founded-year,end-year)?format=json',
                    access_token        => $token,
                    access_token_secret => $secret,
                );
                sleep 5;
                my $cmpy = $json->decode( $job_json );
                # get or create
                $company = $schema->resultset('Company')->get_by_website($cmpy->{'websiteUrl'})
                    if $cmpy->{'websiteUrl'};
                if ($company) {
                    delete $cmpy->{'websiteUrl'};
                    $company->update( {
                        name => delete $cmpy->{name},
                        ref  => "linkedin-$li_cid",
                        extra => $json->encode($cmpy),
                    } );
                } else {
                    $company = $schema->resultset('Company')->create( {
                        name => delete $cmpy->{name},
                        website => delete $cmpy->{'websiteUrl'},
                        ref  => "linkedin-$li_cid",
                        extra => $json->encode($cmpy),
                    } );
                }
            }
        } else {
            $company = $schema->resultset('Company')->get_or_create( {
                name => $r->{company}->{name}
            } );
        }

        my @tags =  map { $_->{name} } @{$r->{position}->{jobFunctions}->{values}};
        push @tags, map { $_->{name} } @{$r->{position}->{industries}->{values}};
        my $pd = $r->{postingDate};
        my $postingDate = sprintf('%04d-%02d-%02d', $pd->{year}, $pd->{month}, $pd->{day});

        my $row = {
            source_url => $link,
            title => delete $r->{position}->{title},
            company_id => $company->id,
            contact   => '',
            posted_at => $postingDate,
            description => $desc,
            location => $r->{position}->{location}->{name},
            type     => $r->{position}->{jobType}->{name},
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