package FindmJob::Scrape::37Signals;

use Moose;
use namespace::autoclean;

with 'FindmJob::Scrape::Role';

use XML::Simple 'XMLin';
use HTML::TreeBuilder;
use Try::Tiny;
use JSON::XS 'encode_json';
use FindmJob::DateUtils 'human_to_db_datetime';

sub run {
    my ($self) = @_;

    my $schema = $self->schema;
    my $job_rs = $schema->resultset('Job');
    my $resp = $self->get('http://jobs.37signals.com/jobs.rss');
    my $data = XMLin($resp->decoded_content);
    foreach my $item ( @{$data->{channel}->{item}} ) {
        my $link = $item->{link};
        my $is_inserted = $job_rs->is_inserted_by_url($link);
        next if $is_inserted and not $self->opt_update;
        my $row = $self->on_single_page($item);
        next unless $row;
        if ( $is_inserted and $self->opt_update ) {
            $job_rs->update_job($row);
        } else {
            $job_rs->create_job($row);
        }
    }
}

sub on_single_page {
    my ($self, $item) = @_;

    my $link = $item->{link};
    my $resp = $self->get($link);
    my $content = $resp->decoded_content;
    return if $content =~ /Job listing not found/;
    my $tree = HTML::TreeBuilder->new_from_content($content);
 #   try {
        my $jobdetail = $tree->look_down(_tag => 'div', class => 'listing-container');
        my $hed = $tree->look_down(_tag => 'div', class => 'listing-header');

        my $title = $hed->look_down(_tag => 'h1')->as_trimmed_text;
        my $location = $hed->look_down(_tag => 'span', class => 'location')->as_trimmed_text;
        $location =~ s/^Location\:\s*//;
        my $company = $hed->look_down(_tag => 'span', class => 'company')->as_trimmed_text;
        my $website = $hed->look_down(_tag => 'a');
        $website = $website->attr('href') if $website;

        my $apply = $self->format_tree_text( $tree->look_down(_tag => 'div', class => qr'apply') );
        $apply =~ s/\s*Apply for this position\s*//;

        foreach my $item_r ($jobdetail->content_refs_list) {
            next unless ref $$item_r; # we don't change plain text
            my $h = $$item_r;
            my $tag = $h->{_tag};
            if ($tag eq 'div' and $h->attr('id') and $h->attr('id') eq 'hed') {
                $h->detach();
            }
            if ($tag eq 'div' and $h->attr('class') and $h->attr('class') =~ 'apply') {
                $h->detach();
            }
            # <img alt="apply" class="analytic" data-analyticurl="/analytics/jobapply/16890" id="applyanalytic" />
            if ($tag eq 'img' and $h->attr('id') and $h->attr('id') eq 'applyanalytic') {
                $h->detach();
            }
        }

        my $desc = $self->format_tree_text($jobdetail);

        my @tags = $self->get_extra_tags_from_desc($title);
        push @tags, $self->get_extra_tags_from_desc($desc);

        my $row = {
            source_url => $link,
            title => $title,
            company => {
                name => $company,
                website => $website,
            },
            contact   => $apply,
            posted_at => human_to_db_datetime($item->{'pubDate'}),
            description => $desc,
            location => $location,
            type     => '',
            extra    => '',
            tags     => ['37signals', @tags],
        };

#    } catch {
#        $self->log_fatal($_);
#    }
    $tree = $tree->delete;

    return $row;
}

__PACKAGE__->meta->make_immutable;

1;