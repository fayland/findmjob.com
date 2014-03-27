package FindmJob::Scrape::Punchgirls;

use Moo;
with 'FindmJob::Scrape::Role';

use HTML::TreeBuilder;
use Try::Tiny;
use JSON::XS 'encode_json';
use Encode;

sub run {
    my ($self) = @_;

    my $schema = $self->schema;
    my $job_rs = $schema->resultset('Job');
    my $resp = $self->get('https://jobs.punchgirls.com/search?query=All+posts');
    my $c = $resp->decoded_content; $c =~ s/<section/<div/g; $c =~ s{</section>}{</div>}g;
    my $tree = HTML::TreeBuilder->new_from_content($c);
    my @sections = $tree->look_down(_tag => 'div', class => qr'listing-item');
    foreach my $sec (@sections) {
        my $link_source = $sec->look_down(_tag => 'a', href => qr'post_id=');
        die unless $link_source;
        my $link = 'https://jobs.punchgirls.com' . $link_source->attr('href');
        my $is_inserted = $job_rs->is_inserted_by_url($link);
        next if $is_inserted and not $self->opt_update;

        my $row;
        {
            my $title = $link_source->as_trimmed_text;
            my $company = $sec->look_down(_tag => 'a', href => qr'company');
            $company = $company->as_trimmed_text if $company;

            my $desc = $sec->look_down(_tag => 'p', class => qr'description');
            $desc = $self->format_tree_text($desc);

            my @lis = $sec->look_down(_tag => 'li');

            my ($tag_li) = grep { $_->as_HTML =~ /fa-tags/ } @lis;
            my $tag_text = $tag_li ? $tag_li->as_trimmed_text : '';
            my @tags = split(/\s*\,\s*/, $tag_text);
            push @tags, $self->get_extra_tags_from_desc($title);
            push @tags, $self->get_extra_tags_from_desc($desc);

            @lis = map { $_->as_trimmed_text } @lis;
            @lis = grep { /\w/ } @lis;

            my $post_date;
            my %months = ('Jan' => 1, 'Feb' => 2, 'Mar' => 3, 'Apr' => 4, 'May' => 5, 'Jun' => 6, 'Jul' => 7,
                          'Aug' => 8, 'Sep' => 9, 'Oct' => 10, 'Nov' => 11, 'Dec' => 12);
            my ($post_date_text) = grep { /Posted/ } @lis;
            if ($post_date_text =~ /(\d+)\s+(\w{3})/) {
                my @d = localtime();
                $post_date = sprintf('%04d-%02d-%02d', $d[5] + 1900, $months{ucfirst(lc($2))}, $1);
            }

            my $location = $lis[2] !~ /Posted/ ? $lis[2] : '';
            my $data = {};
            $data->{telecommute} = 1 if grep { $_ =~ /Anywhere/ } @lis;
            push @tags, 'telecommute' if $data->{telecommute};

            my $contact = 'https://jobs.punchgirls.com' . $sec->look_down(_tag => 'a', href => qr'apply')->attr('href');

            $row = {
                source_url => $link,
                title => $title,
                company => {
                    name => $company,
                    website => '',
                },
                posted_at => $post_date,
                description => $desc,
                contact => $contact,
                location => $location || '',
                extra => encode_json($data),
                tags  => \@tags
            };
        }
        print Dumper(\$row); next;

        $row->{location_id} = $self->get_location_id_from_text($row->{location}) if $row->{location};
        if ( $is_inserted and $self->opt_update ) {
            $job_rs->update_job($row);
        } else {
            $job_rs->create_job($row);
        }

    }
    $tree = $tree->delete;
}

1;