package FindmJob::Schema::ResultSet::Company;

use Moo;
extends 'FindmJob::Schema::ResultSet';

use Mojo::JSON;

sub get_or_create {
    my ($self, $row) = @_;

    my $r;
    $r = $self->get_by_website( $row->{website} ) if $row->{website};
    $r ||= $self->get_by_ref( $row->{ref} ) if $row->{ref};

    $row->{name} //= $row->{website}; #/
    $row->{name} = 'Unknown' unless length $row->{name};
    $row->{name} =~ s#http://(www\.)?##;
    $r ||= $self->get_by_name( $row->{name} );

    if ($r) {
        if ($row->{extra}) {
            my $json = Mojo::JSON->new;

            # merge extra
            my $extra_data = $r->extra_data;
            $row->{extra} = { %{ $json->decode($row->{extra}) }, %$extra_data };

            $r->extra( $json->encode($row->{extra}) );
            $r->update();
            die "updated " . Dumper(\$row->{extra}) . $r->id . "\n"; use Data::Dumper;
        }
        return $r;
    }

    $row->{website} //= ''; #/
    $row->{ref} //= ''; #/
    $row->{extra} //= ''; #/

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