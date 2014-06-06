package FindmJob::Scrape::PythonWeekly;

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
    my $resp = $self->get('http://jobs.pythonweekly.com/feed/');
    my $data = XMLin($resp->decoded_content);
    foreach my $item ( @{$data->{channel}->{item}} ) {
        my $link = $item->{link};
        my $is_inserted = $job_rs->is_inserted_by_url($link);
        next if $is_inserted and not $self->opt_update;
        my $row = $self->on_single_page($item);
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

    my $row;
    my $link = $item->{link};
    my $resp = $self->get($link);
    my $content = $resp->decoded_content;
    $content =~ s/\&ndash\;/\-/;
    my $tree = HTML::TreeBuilder->new_from_content($content);
    try {
        my $data;
        my $title = $tree->look_down(_tag => 'h1');
        my $job_type = $title->look_down(_tag => 'span', class => 'type');
        if ($job_type) {
            $data->{job_type} = $job_type->as_trimmed_text;
            $job_type->detach();
        }
        $title = $title->as_trimmed_text;

        my $section_header = $tree->look_down(_tag => 'div', class => 'section_header');
        my $header_meta = $section_header->look_down(_tag => 'p', class => 'meta');

        my $company = $header_meta->look_down(_tag => 'a');
        if ($company) {
            $data->{company_website} = $company->attr('href');
            $data->{company_name} = $company->as_trimmed_text;
            $company->detach();
            $data->{location} = $header_meta->as_trimmed_text;
            $data->{location} =~ s/^\s*\-\s*//;
        } else {
            my $_x = $header_meta->as_trimmed_text;
            ($data->{company_name}, $data->{location}) = split(/\s*\-\s*/, $_x);
        }

        my $section_content = $tree->look_down(_tag => 'div', class => 'section_content');
        $section_content->look_down(_tag => 'h2')->detach();
        $section_content->look_down(_tag => 'p', class => 'meta')->detach();
        my $desc = $self->format_tree_text($section_content);
        $desc =~ s/\s*Related Jobs(.*?)$//s;

        my @tags = ('python', 'pythonweekly');
        push @tags, $self->get_extra_tags_from_desc($title);
        push @tags, $self->get_extra_tags_from_desc($desc);

        $row = {
            source_url => $link,
            title => $title,
            company => {
                name => delete $data->{company_name},
                website => delete $data->{company_website} || '',
            },
            contact   => '',
            posted_at => human_to_db_datetime($item->{'pubDate'}),
            description => $desc,
            location => delete $data->{location} || '',
            type  => delete $data->{'job_type'} || '',
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