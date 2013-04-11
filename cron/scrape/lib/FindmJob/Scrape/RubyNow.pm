package FindmJob::Scrape::RubyNow;

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
    my $resp = $self->get('http://feeds.feedburner.com/jobsrubynow?format=xml');
    my $data = XMLin($resp->decoded_content);
    foreach my $item ( @{$data->{channel}->{item}} ) {
        my $link = $item->{'feedburner:origLink'};
        $link =~ s/\?source=4$//;

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

    my $link = $item->{'feedburner:origLink'};
    $link =~ s/\?source=4$//;

    my $resp = $self->get($link);
    my $content = $resp->decoded_content;
    return if $content =~ 'Job is not available';
    my $tree = HTML::TreeBuilder->new_from_content($content);
 #   try {
        my %data;

        my $entry = $tree->look_down(_tag => 'div', id => 'job');
        my $h2 = $entry->look_down(_tag => 'h2');

        foreach my $item_r ($h2->content_refs_list) {
            next unless ref $$item_r; # we don't change plain text
            my $h = $$item_r;
            my $tag = $h->{_tag};
            if ($tag eq 'a') {
                $data{website} = $h->attr('href');
            } elsif ($tag eq 'span' and $h->attr('style') and $h->attr('style') =~ /gray/) {
                $h->replace_with("FINDMJOB.COM");
            }
        }
        my ($title, $company) = split(/\s*FINDMJOB.COM\s*/, $h2->as_trimmed_text);
        my $location = $entry->look_down(_tag => 'h3', id => 'location')->as_trimmed_text;

        my $description = $entry->look_down(_tag => 'div', id => 'info');
        my $desc = $self->format_tree_text($description);

        my @tags = $self->get_extra_tags_from_desc($title);
        push @tags, $self->get_extra_tags_from_desc($desc);

        my $type = '';
        $desc =~ s/Work hours\:\s*(.*?)(\n|$)//is and $type = $1;
        push @tags, 'telecommute' if $desc =~ /Telecommute\:/;

        my $row = {
            source_url => $link,
            title => $title,
            company => {
                name => $company,
                $data{website} ? (website => $data{website}) : (),
            },
            contact   => '',
            posted_at => human_to_db_datetime($item->{'pubDate'}),
            description => $desc,
            location => $location,
            type     => $type,
            extra    => '',
            tags     => ['rubynow', 'Ruby', @tags],
        };
#    } catch {
#        $self->log_fatal($_);
#    }
    $tree = $tree->delete;

    return $row;
}

1;