package FindmJob::Scrape::JobsPerlOrg;

use Moose;
with 'FindmJob::Scrape::Role';
with 'FindmJob::Scrape::Role::TextFormatter';

use XML::Simple 'XMLin';
use HTML::TreeBuilder;
use Try::Tiny;
use JSON::XS 'encode_json';
use FindmJob::DateUtils 'human_to_db_datetime';

sub run {
    my ($self) = @_;

    my $schema = $self->schema;
    my $job_rs = $schema->resultset('Job');
    my $resp = $self->get('http://jobs.perl.org/rss/standard.rss');
    my $data = XMLin($resp->decoded_content);
    foreach my $item ( @{$data->{item}} ) {
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
    my $tree = HTML::TreeBuilder->new_from_content($resp->decoded_content);
 #   try {
        my $data;
        my $title = $tree->look_down(_tag => 'h1')->as_trimmed_text;
        my @trs = $tree->look_down(_tag => 'tr', sub { $_[0]->look_down(_tag => 'a', sub { defined($_[0]->attr('name')) }) });
        foreach my $tr (@trs) {
            my @tds = $tr->look_down(_tag => 'td');
            next if @tds > 2;
            my $k = $tr->look_down(_tag => 'a')->attr('name');
            my $v;
            if ( grep { $k eq $_ } ('description', 'skills_desired', 'skills_required') ) {
                $v = $self->format_tree_text($tds[1]);
            } else {
                $v = $tds[1]->as_trimmed_text;
            }
            $v =~ s/\xA0/ /g;
            $data->{$k} = $v;
        }

        $data->{website} = 'http://' . $data->{website} unless $data->{website} and $data->{website} =~ /^http\:/;
        my @tags = ('perl');
        push @tags, 'telecommute' if $data->{onsite} eq 'no' or $data->{onsite} eq 'some';

        delete $data->{posted_on};
        my $row = {
            source_url => $link,
            title => $title,
            company => {
                name => delete $data->{company_name},
                website => delete $data->{website},
            },
            contact   => delete $data->{contact},
            posted_at => human_to_db_datetime($item->{'dc:date'}),
            description => delete $data->{description},
            location => delete $data->{location},
            type  => delete $data->{hours} || '',
            extra => encode_json($data),
            tags  => \@tags
        };

#    } catch {
#        $self->log_fatal($_);
#    }
    $tree = $tree->delete;

    return $row;
}

1;