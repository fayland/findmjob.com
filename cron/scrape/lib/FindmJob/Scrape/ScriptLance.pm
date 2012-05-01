package FindmJob::Scrape::ScriptLance;

use Moose;
use namespace::autoclean;

with 'FindmJob::Scrape::Role';

use XML::Simple 'XMLin';
use HTML::TreeBuilder;
use Try::Tiny;
use FindmJob::DateUtils 'human_to_db_datetime';
use List::Util 'shuffle';
use JSON::XS qw/encode_json/;

sub run {
    my ($self) = @_;

    my $schema = $self->schema;
    my $job_rs = $schema->resultset('Freelance');

    my $url = 'http://www.scriptlance.com/rss/projects.xml';
    {
        $self->log_debug("# get $url");
        my $resp = $self->get($url);
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
}

sub on_single_page {
    my ($self, $item) = @_;

    my $link = $item->{link};
    $self->log_debug("# get $link");
    my $resp = $self->get($link); sleep 3;
    return unless $resp->is_success;
    return unless $resp->decoded_content =~ /\<\/html\>/i;
    my $tree = HTML::TreeBuilder->new_from_content($resp->decoded_content);
 #   try {
        my $data;

        my $budget_amount = $tree->look_down(_tag => 'div', class => 'budget_amount');
        $budget_amount = $budget_amount->as_trimmed_text if $budget_amount;
        my $max_budget = 0;
        (undef, $max_budget) = ($budget_amount =~ /(\-|\$)(\d+)$/) if $budget_amount;
        unless ($max_budget and $max_budget >= 500) {
            $tree = $tree->delete;
            return;
        }

        my $head = $tree->look_down(_tag => 'div', class => 'head');

        my $title = $head->look_down(_tag => 'div', class => 'title')->as_trimmed_text;

        my @_tags;
        my $items = $tree->look_down(_tag => 'div', class => 'items');
        my @lis   = $items->look_down(_tag => 'li');
        foreach my $li (@lis) {
            my $name = $li->look_down(class => qr'itemname')->as_trimmed_text; $name =~ s/\:$//;
            my $cont = $li->look_down(class => qr'itemcont');
            if ($name =~ /Description/i) {
                $data->{description} = $self->format_tree_text($cont);
            } elsif ($name =~ /Tags/) {
                @_tags = $cont->look_down(_tag => 'a');
                @_tags = map { $_->as_trimmed_text } @_tags;
            } else {
                $data->{$name} = $cont->as_trimmed_text;
            }
        }

        my $desc = delete $data->{description};
        my @tags = ('scriptlance', 'telecommute');
        push @tags, $self->get_extra_tags_from_desc($title);
        push @tags, $self->get_extra_tags_from_desc($desc);
        push @tags, @_tags;

        $data->{'Bidding Ends'} =~ s/\s*\(.*?\)$//;
        $data->{"Project Creator"} =~ s/\s*\(.*?\)$//;

        my $row = {
            source_url => $link,
            title => $title,
            company => {
                name => "ScriptLance",
                website => "http://www.scriptlance.com/",
            },
            contact   => '',
            posted_at  => human_to_db_datetime(delete $data->{'Posted'}),
            expired_at => human_to_db_datetime(delete $data->{'Bidding Ends'}),
            description => $desc,
            location => 'Anywhere',
            type  => '',
            extra => encode_json($data),
            tags  => \@tags
        };
#    } catch {
#        $self->log_fatal($_);
#    }
    $tree = $tree->delete;

    return $row;
}

__PACKAGE__->meta->make_immutable;

1;