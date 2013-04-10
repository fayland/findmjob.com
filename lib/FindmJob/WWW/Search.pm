package FindmJob::WWW::Search;

use Mojo::Base 'Mojolicious::Controller';
use FindmJob::Search;

sub search {
    my $self = shift;

    my $schema = $self->schema;

    my ($p) = ($self->req->url->path =~ m{/p\.(\d+)(/|$)});
    $p = 1 unless $p and $p =~ /^\d+$/;
    my $rows = 12;

    my $q = $self->param('q');
    my $loc = $self->param('loc') || '';
    my $by  = $self->param('by') || 'relevance';
    my $rest_url = $self->stash('rest');
    my ($filename) = ($rest_url =~ m{/([^/]+).html$});
    if ($filename) {
        $filename =~ s/\_by\_(date|relevance)$// and $by = $1;
        $filename =~ s/(^|\_)in\_(\w+)$// and $loc = $2;
        $q = $filename;
    }
    $self->stash('q'    => $q);
    $self->stash('loc'  => $loc);
    $self->stash('sort' => $by);

    my $search = FindmJob::Search->new;
    my $ret = $search->search_job( {
        'q'  => $q,
        loc  => $loc,
        sort => $by,
        rows => $rows,
        page => $p,
    } );
    if ($ret->{total}) {
        my $schema = FindmJob::Basic->schema;

        my @ids    = map { $_->{id} } @{$ret->{matches}};
        my @jobids = map { $_->{id} } grep { $_->{tbl} eq 'job' } @{$ret->{matches}};
        my @freelance_ids = map { $_->{id} } grep { $_->{tbl} eq 'freelance' } @{$ret->{matches}};

        my %ids;
        if (@jobids) {
            my @jobs   = $schema->resultset('Job')->search( {
                id => { 'IN', \@jobids }
            } )->all;
            %ids = map { $_->id => $_ } @jobs;
        }
        if (@freelance_ids) {
            my @jobs   = $schema->resultset('Freelance')->search( {
                id => { 'IN', \@freelance_ids }
            } )->all;
            map { $ids{$_->id} = $_ } @jobs;
        }

        my @jobs = map { $ids{$_} } @ids;
        $self->stash(jobs => \@jobs);

        # pager
        my $pager = Data::Page->new();
        $pager->total_entries($ret->{total});
        $pager->entries_per_page($rows);
        $pager->current_page($p);
        $self->stash(pager => $pager);
    }

    $self->render(template => 'search');
}

1;