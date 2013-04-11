package FindmJob::Scrape::SmashingMagazine;

use Moo;
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
    my $resp = $self->get('http://jobs.smashingmagazine.com/rss/all/all');
    my $data = XMLin($resp->decoded_content);
    my $i = 0;
    foreach my $item ( @{$data->{channel}->{item}} ) {
        $i++;
        last if $i > 30; # that RSS contains ALL, even 5 months old

        my $link = $item->{link};
        my $is_inserted = $job_rs->is_inserted_by_url($link);
        next if $is_inserted and not $self->opt_update;
        my $row = $self->on_single_page($item);
        next unless $row;
        $row->{location_id} = $self->get_location_id_from_text($row->{location}) if $row->{location};
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
    return unless $content =~ 'job-entry';
    $content =~ s/(\<\/?)article/${1}div/g;
    my $tree = HTML::TreeBuilder->new_from_content($content);
 #   try {
        my $entry = $tree->look_down(_tag => 'div', class => qr'post job-entry');

        my $title = $entry->look_down(_tag => 'h2')->as_trimmed_text;

        my %data;
        my $postmetadata = $entry->look_down(_tag => 'ul', class => qr'postmetadata');
        my @lis = $postmetadata->look_down(_tag => 'li');
        foreach my $li (@lis) {
            my $class = $li->attr('class');
            next unless $class;
            if ($class eq 'author') {
                foreach my $item_r ($li->content_refs_list) {
                    next unless ref $$item_r; # we don't change plain text
                    my $h = $$item_r;
                    my $tag = $h->{_tag};
                    if ($tag eq 'a') {
                        $data{company} = $h->as_trimmed_text;
                        $h->detach();
                    }
                }
                my $text = $li->as_trimmed_text;
                if ($data{company}) {
                    $data{location} = $text;
                } else {
                    ($data{company}, $data{location}) = ($text =~ /^([^\(]+)\s+(.*?)$/);
                }
                $data{location} =~ s/^\(|\)$//g;
            } elsif ($class eq 'tags') {
                $data{type} = $li->as_trimmed_text;
            }
        }

        foreach my $item_r ($entry->content_refs_list) {
            next unless ref $$item_r; # we don't change plain text
            my $h = $$item_r;
            my $tag = $h->{_tag};
            if ($tag eq 'h2') {
                $h->detach();
            }
            if ($tag eq 'ul' and $h->attr('class') and $h->attr('class') =~ 'postmetadata') {
                $h->detach();
            }
        }

        my $desc = $self->format_tree_text($entry);
        $desc =~ s/\<img[^\>]+\>//isg; # no image
        $desc =~ s/^\s+|\s+$//g; # remove space

        my @tags = $self->get_extra_tags_from_desc($title);
        push @tags, $self->get_extra_tags_from_desc($desc);

        my $row = {
            source_url => $link,
            title => $title,
            company => {
                name => $data{company},
            },
            contact   => '',
            posted_at => human_to_db_datetime($item->{'pubDate'}),
            description => $desc,
            location => $data{location},
            type     => $data{type},
            extra    => '',
            tags     => ['smashingmagazine', @tags],
        };

#    } catch {
#        $self->log_fatal($_);
#    }
    $tree = $tree->delete;

    return $row;
}

1;