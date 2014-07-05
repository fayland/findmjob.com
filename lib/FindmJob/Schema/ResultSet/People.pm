package FindmJob::Schema::ResultSet::People;

use Moo;
extends 'FindmJob::Schema::ResultSet';

use FindmJob::Utils qw/uuid/;

sub do_people {
    my ($self, $row) = @_;

    my $schema = $self->result_source->schema;
    my $identity = delete $row->{identity};

    $row->{updated_at} = time();
    $row->{location_id} = $schema->resultset('Location')->get_location_id_from_text($row->{location}) if $row->{location};

    my $people_id;
    my $irow = $schema->resultset('PeopleIdentity')->find($identity);
    if ($irow) {
        $people_id = $irow->people_id;
        my $people = $self->find($people_id);
        # merge data
        my $new_data = { %{$people->data}, %{$row->{data}} };
        $row->{data} = $new_data;
        $self->search({ id => $people_id })->update($row);
    } else {
        $people_id = uuid();
        $row->{id} = $people_id;
        $self->create($row);
        $schema->resultset('PeopleIdentity')->create({
            identity => $identity,
            people_id => $people_id
        });
    }

    return $people_id;
}

1;