package FindmJob::Scrape::html5Jobs;

use Moo;
with 'FindmJob::Scrape::Role';

use XML::Simple 'XMLin';
use HTML::TreeBuilder;
use Try::Tiny;
use JSON::XS 'encode_json';
use FindmJob::DateUtils 'human_to_db_datetime';
use Encode;

sub run {
    my ($self) = @_;

    my $schema = $self->schema;
    my $job_rs = $schema->resultset('Job');
    my $resp = $self->get('http://www.html5jobs.net/jobs/latest/feed/rss/');
    my $data = XMLin($resp->decoded_content);
    foreach my $item ( @{$data->{channel}->{item}} ) {
        my $link = $item->{link};
        my $is_inserted = $job_rs->is_inserted_by_url($link);
        next if $is_inserted and not $self->opt_update;
        my $row = $self->on_single_page($item);
        if ( $is_inserted and $self->opt_update ) {
            $job_rs->update_job($row);
        } else {
            $job_rs->create_job($row);
        }
    }
}

sub on_single_page {
    my ($self, $item) = @_;

    my $row;
    my $link = $item->{link};
    my $resp = $self->get($link);
    my $tree = HTML::TreeBuilder->new_from_content( decode_utf8($resp->content) );
    try {
        my $data;
        my $title = $tree->look_down(_tag => 'h2');
        $title->look_down(_tag => 'small')->detach();
        my $company = $title->look_down(_tag => 'strong');
        if (my $website_tag = $company->look_down(_tag => 'a')) {
            $data->{website} = $website_tag->attr('href');
            $data->{company_name} = $website_tag->as_trimmed_text;
        } else {
            $data->{company_name} = $company->as_trimmed_text;
        }
        $company->detach();
        $title = $title->as_trimmed_text;

        my $location = $tree->look_down(_tag => 'h5');
        my $date_div = $location->look_down(_tag => 'span');
        my $date = $date_div->as_trimmed_text;
        $date_div->detach();
        $location = $location->as_trimmed_text; $location =~ s/\,\s*/\, /g;

        my $desc = $tree->look_down(_tag => 'div', class => qr/well/); # the first well
        $desc = $self->format_tree_text($desc);

        my @tags = ('python', 'html5', 'html5jobs.net');
        push @tags, $self->get_extra_tags_from_desc($title);
        push @tags, $self->get_extra_tags_from_desc($desc);

        my @attrs = $tree->look_down(_tag => 'p', sub {
            $_[0]->look_down(_tag => 'div', class => qr/lead/)
        });
        foreach my $x (@attrs) {
            my $zz = $x->look_down(_tag => 'div', class => qr/lead/);
            my $ttl = $zz->as_trimmed_text; $zz->detach();
            my $vvv = $x->as_trimmed_text;
            $data->{$ttl} = $vvv;
            push @tags, 'telecommute' if $ttl =~ /Telecommute/i and $vvv =~ /Yes/i;
        }
        my $apply_p = $tree->look_down(_tag => 'p', class => qr/lead/);
        my $contact = $self->format_tree_text( $apply_p->right() );
        $contact =~ s/ application form below//;

        $row = {
            source_url => $link,
            title => $title,
            company => {
                name => delete $data->{company_name},
                website => delete $data->{website} || '',
            },
            contact   => $contact,
            posted_at => human_to_db_datetime($date),
            description => $desc,
            location => $location || '',
            type  => delete $data->{'Work Schedule'} || '',
            extra => encode_json($data),
            tags  => \@tags
        };

    } catch {
        $self->log_fatal($_);
    };
    $tree = $tree->delete;

    return $row;
}

1;