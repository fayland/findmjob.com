package FindmJob::Scrape::Freelancer;

use Moo;
with 'FindmJob::Scrape::Role';

use Try::Tiny;
use FindmJob::DateUtils 'human_to_db_datetime';
use JSON::XS qw/encode_json decode_json/;
use Data::Dumper;
use HTML::TreeBuilder;

sub run {
    my ($self) = @_;

    my $schema = $self->schema;
    my $job_rs = $schema->resultset('Freelance');
    my $json = JSON::XS->new->utf8;

    # set socks proxy (Tor)
    my $config = $self->config;
    $self->ua->proxy('http', $config->{scrape}->{proxy})
        if $config->{scrape}->{proxy};

    my @keywords = ('Perl', 'Python', 'PHP', 'Ruby-on-Rails', 'Java', 'Javascript', 'Scraping', 'MySQL');
    foreach my $keyword (@keywords) {
        $self->log_debug("# [Freelancer] working on $keyword");
        my $url = "https://api.freelancer.com/Project/Search.json?jobs[]=" . $keyword . '&nonpublic=0';
        my $res = $self->get($url);
        my $data = $json->decode( $res->decoded_content );
        foreach my $item ( @{$data->{projects}->{items}} ) {
            my $link = delete $item->{url};
            my $is_inserted = $job_rs->is_inserted_by_url($link);
            if ($is_inserted and not $item->{opened}) {
                # got it deleted
                $job_rs->search({ source_url => $link })->delete;
            }
            next if $is_inserted and not $self->opt_update;
            next unless $item->{opened};
            delete $item->{opened}; delete $item->{pending}; delete $item->{rejected}; delete $item->{frozen}; delete $item->{closed};
            delete $item->{formatedStateDesc}; delete $item->{formatedState};
            delete $item->{jobsDetails}; delete $item->{short_descr_html}; delete $item->{closeDate};
            delete $item->{end_date}; delete $item->{files}; delete $item->{start_date};
            delete $item->{closeDate};

            $item->{currency} = $item->{currencyDetails}->{code};
            delete $item->{currencyDetails};

            my $desc = delete $item->{short_descr};
            my $html_desc = $self->get_desc_from_html($link);
            $desc = $html_desc if $html_desc;

            my @tags = @{delete $item->{jobs}};
            push @tags, $self->get_extra_tags_from_desc($item->{name});
            push @tags, $self->get_extra_tags_from_desc($desc);

            my $row = {
                source_url => $link,
                title => delete $item->{name},
                contact   => '',
                posted_at  => human_to_db_datetime(delete $item->{start_unixtime}),
                expired_at => human_to_db_datetime(delete $item->{end_unixtime}),
                description => $desc,
                type     => delete $item->{budgetPeriod},
                extra    => $json->encode($item),
                tags     => ['freelancer', @tags],
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

sub get_desc_from_html {
    my ($self, $url) = @_;

    my $resp = $self->get($url);
    return unless $resp->is_success;
    my $content = $resp->decoded_content;
    return unless $content =~ /\<\/html\>/i;
    return if $content =~ m{<h1>Project Deleted</h1>};

    my $desc;
    my $tree = HTML::TreeBuilder->new_from_content($content);
    try {
        my $ns_description = $tree->look_down(_tag => 'div', class => 'span8 margin-t20');

        my @sets =  $ns_description->look_down(_tag => 'a', href => qr'../jobs/');
        foreach my $h (@sets) {
             my ($cw) = ($h->attr('href') =~ '/jobs/([^\/]+)');
             $h->replace_with_content( $h->as_trimmed_text );
        }

        @sets =  $tree->look_down(_tag => 'a', class => 'tag');
        foreach my $h (@sets) {
            $h->detach();
        }

        $desc = $self->format_tree_text($ns_description);
        $desc =~ s/^Project Description:\s*//s;
        $desc =~ s/See more\:[\s\,]+$//s;
    } catch {
       $self->log_fatal($_);
    };
    $tree = $tree->delete;

    return $desc;
}


1;