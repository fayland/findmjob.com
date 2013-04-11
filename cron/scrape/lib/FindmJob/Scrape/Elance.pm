package FindmJob::Scrape::Elance;

use Moo;
with 'FindmJob::Scrape::Role';

use Try::Tiny;
use Data::Dumper;
use FindmJob::DateUtils 'human_to_db_datetime';
use Encode;
use XML::Simple 'XMLin';
use HTML::TreeBuilder;
use JSON::XS;

sub run {
    my ($self) = @_;

    my $schema = $self->schema;
    my $job_rs = $schema->resultset('Freelance');
    my @urls = ('https://www.elance.com/php/search/main/resultsproject.php?matchType=project&rss=1&sortBy=timelistedSort&sortOrder=1&statusFilter=10037');

    # set socks proxy (Tor)
    my $config = $self->config;
    $self->ua->proxy(['http', 'https'], $config->{scrape}->{proxy})
        if $config->{scrape}->{proxy};

    foreach my $url (@urls) {
        my $resp = $self->get($url);
        my $data = XMLin($resp->decoded_content);
        foreach my $item ( @{$data->{channel}->{item}} ) {
            my $description = $item->{description};

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
}

sub on_single_page {
    my ($self, $item) = @_;

    my $link = $item->{link};
    my $resp = $self->get($link); sleep 3;
    return unless $resp->is_success;
    return unless $resp->decoded_content =~ /\<\/html\>/i;
    my $tree = HTML::TreeBuilder->new_from_content($resp->decoded_content);

    my $title = $tree->look_down(_tag => 'h1')->look_down(_tag => 'div', class => 'left')->as_trimmed_text;
    my $jobDescText = $tree->look_down(_tag => 'p', id => 'jobDescText');
    my $desc = $self->format_tree_text($jobDescText);
    $desc =~ s{\s*<a href="javascript:loginReturn.*?$}{}sg;

    my @tags = ('elance', 'freelance');
    my $jobDetailTags = $tree->look_down(_tag => 'div', id => 'jobDetailTags');
    my @sets =  $jobDetailTags ? $jobDetailTags->look_down(_tag => 'a', href => qr'/r/contractors/') : ();
    foreach my $h (@sets) {
         push @tags, $h->as_trimmed_text;
    }
    push @tags, $self->get_extra_tags_from_desc($title);
    push @tags, $self->get_extra_tags_from_desc($desc);
    @tags = grep { length($_) } @tags;

    my $row = {
        source_url => $link,
        title => $title,
        contact   => '',
        posted_at => human_to_db_datetime($item->{'pubDate'}),
        description => $desc,
        type  => '',
        extra => '',
        tags  => \@tags
    };

    $tree = $tree->delete;
    return $row;
}

1;