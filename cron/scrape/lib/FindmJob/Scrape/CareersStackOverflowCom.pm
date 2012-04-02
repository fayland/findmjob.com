package FindmJob::Scrape::CareersStackOverflowCom;

use Moose;
with 'FindmJob::Scrape::Role';
with 'FindmJob::Scrape::Role::TextFormatter';

use XML::Simple 'XMLin';
use HTML::TreeBuilder;
use Try::Tiny;
use JSON::XS 'encode_json';

sub run {
    my ($self) = @_;

    my $schema = $self->schema;
    my $job_rs = $schema->resultset('Job');
    my $resp = $self->get('http://careers.stackoverflow.com/jobs/feed');
    my $data = XMLin($resp->decoded_content);
    foreach my $item ( @{$data->{channel}->{item}} ) {
        my $link = $item->{link};
        my $is_inserted = $job_rs->is_inserted_by_url($link);
        next if $is_inserted and not $self->opt_update;
        my $row = $self->on_single_page($item);
        if ( $is_inserted and $self->opt_update ) {
            $self->schema->resultset('Job')->update_job($row);
        } else {
            $self->schema->resultset('Job')->create_job($row);
        }
    }
}

sub on_single_page {
    my ($self, $item) = @_;

    my $link = $item->{link};
    my $resp = $self->get($link);
    my $content = $resp->decoded_content;
    $content =~ s/\<span checked\>/ X /g; # for Joel Test
    my $tree = HTML::TreeBuilder->new_from_content($content);
 #   try {
        my $jobdetail = $tree->look_down(_tag => 'div', class => 'jobdetail');
        my $hed = $jobdetail->look_down(_tag => 'div', id => 'hed');

        my $title = $hed->look_down(_tag => 'h1')->as_trimmed_text;
        my $location = $hed->look_down(_tag => 'span', class => 'location')->as_trimmed_text;
        my $byline = $hed->look_down(_tag => 'p', id => 'byline');
        my $company = $byline->look_down(_tag => 'a', target => '_blank');

        my @tags = $hed->look_down(_tag => 'a', class => 'post-tag');

        my $apply = $jobdetail->look_down(_tag => 'div', class => qr'apply')->as_trimmed_text;
        $apply =~ s/\s*How to apply\s*//;

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
        }

        my $desc = $self->formatter->format($jobdetail);
        $desc =~ s/^\s+|\s+$//g;
        $desc =~ s/\[IMAGE\]/\n/g;
        $desc =~ s/\n{3,}/\n\n/g;
        $desc =~ s/\xA0/ /g;
        $desc =~ s/\s*apply\s*$//is;
        $desc =~ s/^\s*Job Description\s*\-+\s*//sg;

        my $row = {
            source_url => $link,
            title => $title,
            company => {
                name => $company->as_trimmed_text,
                website => $company->attr('href'),
            },
            contact   => $apply,
            posted_at => substr($item->{'a10:updated'}, 0, 10),
            description => $desc,
            location => $location,
            type     => '',
            extra    => '',
        };

#    } catch {
#        $self->log_fatal($_);
#    }
    $tree = $tree->delete;

    return $row;
}

1;