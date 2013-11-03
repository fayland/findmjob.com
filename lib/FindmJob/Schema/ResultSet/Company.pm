package FindmJob::Schema::ResultSet::Company;

use Moo;
extends 'FindmJob::Schema::ResultSet';

sub get_or_create {
    my ($self, $row) = @_;

    if ($row->{website}) {
        my $r = $self->get_by_website( $row->{website} );
        return $r if $r;
    }
    if ($row->{ref}) {
        my $r = $self->get_by_ref( $row->{ref} );
        return $r if $r;
    }
    $row->{name} //= $row->{website}; #/
    $row->{name} =~ s#http://(www\.)?##;
    $row->{website} //= ''; #/
    $row->{ref} //= ''; #/
    $row->{extra} //= ''; #/
    $row->{name} = 'Unknown' unless length $row->{name};
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

sub get_by_ref {
    my ($self, $ref) = @_;
    return $self->search( { ref => $ref } )->first;
}

1;