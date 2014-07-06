package FindmJob::Scrape::oDesk;

use Moo;
with 'FindmJob::Scrape::Role';

use Try::Tiny;
use Data::Dumper;
use JSON::XS qw/encode_json decode_json/;
use FindmJob::DateUtils 'human_to_db_datetime';
use FindmJob::Utils qw/file_get_contents/;
use Encode;
use LWP::Authen::OAuth;

sub run {
    my ($self) = @_;

    my $schema = $self->schema;
    my $job_rs = $schema->resultset('Freelance');
    my $json = JSON::XS->new->utf8;

    my $config = $self->config;
    $config = $config->{api}->{odesk};

    my $token_content = file_get_contents("/findmjob.com/script/oneoff/odesk.token.txt");
    my ($access_token, $access_secret) = split(':', $token_content);
    die unless $access_token and $access_secret;

    my $ua = LWP::Authen::OAuth->new(
        oauth_consumer_key => $config->{key},
        oauth_consumer_secret => $config->{secret},
        oauth_token => $access_token,
        oauth_token_secret => $access_secret,
    );

    my @keywords = ('perl', 'python', 'php', 'ruby', 'java', 'mysql', 'scraping');
    foreach my $keyword (@keywords) {
        $self->log_debug("# [oDesk] working on $keyword");
        my $res = $ua->get('https://www.odesk.com/api/profiles/v2/search/jobs.json?q=' . $keyword . '&sort=create_time desc');
        my $data = $json->decode( decode('utf8', $res->content) );
        foreach my $item (@{$data->{jobs}}) {
            my $link = delete $item->{url};
            my $is_inserted = $job_rs->is_inserted_by_url($link);
            if ($is_inserted and $item->{job_status} ne 'Open') {
                # got it deleted
                $job_rs->search({ source_url => $link })->delete;
            }
            next if $is_inserted and not $self->opt_update;
            next if $item->{job_status} ne 'Open';
            delete $item->{job_status};

            my $desc = delete $item->{snippet};

            my @tags = @{delete $item->{skills}};
            push @tags, $self->get_extra_tags_from_desc($item->{title});
            push @tags, $self->get_extra_tags_from_desc($desc);

            my $title = delete $item->{title};
            if (length($title) > 128) {
                $title = substr($title, 0, 125) . '...';
            }

            try {
                $res = $ua->get("https://www.odesk.com/api/profiles/v1/jobs/" . $item->{id} . ".json");
                sleep 2;
                my $data2 = $json->decode( decode('utf8', $res->content) );
                if (exists $data2->{profile} and exists $data2->{profile}->{candidates} and ref($data2->{profile}->{candidates}->{candidate}) eq 'ARRAY') {
                    my @x = @{$data2->{profile}->{candidates}->{candidate}};
                    @x = map { "https://www.odesk.com/o/profiles/users/_" . $_->{ciphertext} } @x;
                    $schema->resultset('PeopleUrl')->insert_urls(@x);
                }
                $item->{data} = $data2->{profile} if exists $data2->{profile};
            } catch {
                warn "$_\n";
            };

            my $row = {
                source_url => $link,
                title => $title,
                contact   => '',
                posted_at  => human_to_db_datetime(delete $item->{date_created}),
                description => $desc,
                type     => delete $item->{job_type},
                extra    => $json->encode($item),
                tags     => ['odesk', @tags],
            };
            if ( $is_inserted and $self->opt_update ) {
                $job_rs->update_job($row);
            } else {
                $job_rs->create_job($row);
            }
        }

        sleep 5;
    }
}

1;