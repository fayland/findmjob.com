package FindmJob::Search;

use Moo;
use Sphinx::Search;
use FindmJob::Basic;

has 'es' => (is => 'lazy');
sub _build_es {
    return FindmJob::Basic->elasticsearch;
}

sub search_job {
    my $self = shift;
    my %args = @_ % 2 ? %{$_[0]} : @_;

    my $rows = $args{rows} || 12;
    my $page = $args{page};
    $page = 1 unless $page and $page =~ /^\d+$/;
    my $q    = $args{'q'};
    my $loc  = $args{'loc'};
    my $tbl  = $args{'tbl'};

    my $es = $self->es;

    my $body = {};
    $body->{from} = ($page - 1) * $rows;
    $body->{size} = $rows;
    if ($args{sort} and $args{sort} =~ /(date|time)/) {
        $body->{sort} = { "inserted_at" => { order => "desc" } };
    }

    if ($q and $loc) {
        $body->{query}->{bool}->{must} =  [
                { match => { '_all' => $q } },
                { match => { 'location' => $loc } }
            ];

    } elsif ($q) {
        $body->{query}->{match} = { '_all' => $q };
    } elsif ($loc) {
        $body->{query}->{match} = { 'location' => $loc };
    }

    my $search = { index => 'findmjob', body => $body };
    if ($tbl and ($tbl eq 'job' or $tbl eq 'freelance')) {
        $search->{type} = $tbl;
    }

    my $results = $es->search($search);
    return $results->{hits};
}

=pod

has 'sphinx' => (is => 'lazy');
sub _build_sphinx {
    my $sph = Sphinx::Search->new;
    $sph->SetServer('localhost', 9312);
    return $sph;
}

sub search_job {
    my $self = shift;
    my %args = @_ % 2 ? %{$_[0]} : @_;

    my $rows = $args{rows} || 12;
    my $page = $args{page};
    $page = 1 unless $page and $page =~ /^\d+$/;
    my $q    = $args{'q'};
    my $loc  = $args{'loc'};
    my $tbl  = $args{'tbl'};

    my $sph = $self->sphinx;
    $sph->SetLimits(($page - 1) * $rows, $rows, 800);
    $sph->SetMatchMode(SPH_MATCH_EXTENDED2);
    if ($args{sort} and $args{sort} =~ /(date|time)/) {
        $sph->SetSortMode(SPH_SORT_ATTR_DESC, 'inserted_at');
    } else {
        $sph->SetSortMode(SPH_SORT_RELEVANCE);
    }

    my @query;
    if ($q) {
        my @k = split(/\s+/, $q);
        @k = map { $sph->EscapeString($_) } @k;
        @k = map { '"' . $_ . '"' } @k;
        push @query, '@* (' . join(' & ', @k) . ')'; # @* (Perl & Python)
    }
    if ($loc) {
        push @query, '@location "' . $sph->EscapeString($loc) . '"';
    }
    if ($tbl and ($tbl eq 'job' or $tbl eq 'freelance')) {
        push @query, '@tbl ' . "'$tbl'";
    }
    my $ret = $sph->Query(join(' & ', @query));
    return $ret;
}

=cut

1;