package FindmJob::Scrape::JobsGithubCom;

use Moose;
with 'FindmJob::Scrape::Role';
with 'FindmJob::Scrape::Role::TextFormatter';

use XML::Simple 'XMLin';
use HTML::TreeBuilder;
use Try::Tiny;
use Data::Dumper;

sub run {
    my ($self) = @_;

    my $schema = $self->schema;
    my $job_rs = $schema->resultset('Job');
    my $resp = $self->get('https://jobs.github.com/positions.atom');
    my $data = XMLin($resp->decoded_content, KeyAttr => []);
    foreach my $item ( @{$data->{entry}} ) {
        my $link = $item->{link}->{href};
        my $is_inserted = $job_rs->is_inserted_by_url($link);
        next if $is_inserted;
        $self->on_single_page($item);
    }
}

sub on_single_page {
    my ($self, $item) = @_;

    my $link = $item->{link}->{href};
    my $resp = $self->get($link);
    my $tree = HTML::TreeBuilder->new_from_content($resp->decoded_content);
 #   try {
        my $title = $tree->look_down(_tag => 'h1')->as_trimmed_text;
        my $supertitle = $tree->look_down(_tag => 'p', class => 'supertitle')->as_trimmed_text;
        my ($type, $location) = split(/\s*\/\s*/, $supertitle, 2);

        my $desc = $tree->look_down(_tag => 'div', class => qr'column main');
        $desc = $self->formatter->format($desc);
        $desc =~ s/^\s+|\s+$//g;
        $desc =~ s/\xA0/ /g;

        my $siderbar = $tree->look_down(_tag => 'div', class => qr'column sidebar');
        my $contact  = $siderbar->look_down(_tag => 'div', class => qr'module highlighted')->as_trimmed_text;
        $contact =~ s/\s*How to apply\s*//;
        my $company  = $siderbar->look_down(_tag => 'div', class => qr'module logo')->as_trimmed_text;
        $company =~ s/\s*\d+other jobs\s*//;

        my $row = {
            source_url => $link,
            title => $title,
            company => {
                name => $company
            },
            contact   => $contact,
            posted_at => substr($item->{'updated'}, 0, 10),
            description => $desc,
            location => $location,
            type     => $type,
            extra    => '',
        };
        $self->schema->resultset('Job')->create_job($row);
#    } catch {
#        $self->log_fatal($_);
#    }
    $tree = $tree->delete;
}

1;