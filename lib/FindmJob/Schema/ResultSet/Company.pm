package FindmJob::Schema::ResultSet::Company;

use Moo;
extends 'FindmJob::Schema::ResultSet';

use JSON::XS;

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
            my $json = JSON::XS->new->utf8;

            # merge extra
            my $extra_data = $r->extra_data;
            print Dumper($json->decode($row->{extra}));
            print Dumper($extra_data); use Data::Dumper;
            $row->{extra} = { %{ $json->decode($row->{extra}) }, %$extra_data };

            $r->extra( $json->encode($row->{extra}) );
            $r->update();
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