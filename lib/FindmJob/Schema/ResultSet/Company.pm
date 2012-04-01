package FindmJob::Schema::ResultSet::Company;

use Moose;
use namespace::autoclean;
extends 'FindmJob::Schema::ResultSet';

sub get {
    my ($self, $row) = @_;

    if ($row->{website}) {
        my $r = $self->get_by_website( $row->{website} );
        return $r if $r;
    }
    $row->{name} //= $row->{website}; #/
    $row->{website} //= ''; #/
    return 'NA' unless length $row->{name};
    my $r = $self->get_by_name( $row->{name} );
    return $r if $r;
    return $self->create($row);
}

sub get_by_website {
    my ($self, $website) = @_;

    return $self->search( { website => $website } )->first;
}

sub get_by_name {
    my ($self, $name) = @_;

    return $self->search( { name => $name } )->first;
}


1;