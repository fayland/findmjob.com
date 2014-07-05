package FindmJob::Scrape::CrunchBoard;

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
    $self->ua->proxy('http', 'socks://127.0.0.1:9050');
    my $resp = $self->get('http://feeds.feedburner.com/CrunchboardJobs?format=xml');
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
    return unless $content =~ 'itsthetablejobfrm';
    my $tree = HTML::TreeBuilder->new_from_content($content);
 #   try {
        my $entry = $tree->look_down(_tag => 'div', id => 'itsthetablejobfrm');

        my $title = $entry->look_down(_tag => 'h3')->as_trimmed_text;

        my %data; my %extra;
        my $table = $entry->look_down(_tag => 'table', style => qr'border:solid');
        foreach my $tr ($table->content_list) {
            my @tds = $tr->content_list;
            next unless @tds == 2;

            my $t = $tds[0]->as_trimmed_text;
            my $v = $tds[1]->as_trimmed_text;
            if ($t eq 'Company Name:') {
                $data{company} = $v;
            } elsif ($t eq 'City:') {
                $data{city} = $v;
            } elsif ($t eq 'Country:') {
                $data{country} = $v;
            } elsif ($t eq 'Description:') {
                $data{desc} = $self->format_tree_text($tds[1]);
            } elsif ($t eq 'Job Type:') {
                $data{type} = $v;
            } else {
                $extra{$t} = $v;
            }
        }
        my $desc = delete $data{desc};
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
            location => join(', ', $data{city}, $data{country}),
            type     => $data{type},
            extra    => encode_json(\%extra),
            tags     => ['crunchboard', @tags],
        };

#    } catch {
#        $self->log_fatal($_);
#    }
    $tree = $tree->delete;

    return $row;
}

1;