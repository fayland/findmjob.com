package FindmJob::Search;

use Moose;
use namespace::autoclean;
use Sphinx::Search;
use FindmJob::Basic;

has 'sphinx' => (is => 'ro', isa => 'Sphinx::Search', lazy_build => 1);
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

    my $sph = $self->sphinx;
    $sph->SetLimits(($page - 1) * $rows, $rows, 800);
    $sph->SetMatchMode(SPH_MATCH_EXTENDED2);
    if ($args{order} and $args{order} =~ /(date|time)/) {
        $sph->SetSortMode(SPH_SORT_ATTR_DESC, 'inserted_at');
    } else {
        $sph->SetSortMode(SPH_SORT_RELEVANCE);
    }

    my @k = split(/\s+/, $q);
    @k = map { $sph->EscapeString($_) } @k;
    @k = map { '"' . $_ . '"' } @k;
    my @query = ('@* (' . join(' & ', @k) . ')'); # @* (Perl & Python)
    if ($loc) {
        push @query, '@location "' . $sph->EscapeString($loc) . '"';
    }
    my $ret = $sph->Query(join(' & ', @query));
    return $ret;
}

__PACKAGE__->meta->make_immutable;

1;