package FindmJob::Schema::ResultSet::Job;

use Moo;
extends 'FindmJob::Schema::ResultSet';

sub is_inserted_by_url {
    my ($self, $url) = @_;

    return $self->count( { source_url => $url } );
}

sub create_job {
    my ($self, $row) = @_;

    my $schema = $self->result_source->schema;
    if ( exists $row->{company} and not $row->{company_id} ) {
        my $company = $schema->resultset('Company')->get_or_create(delete $row->{company});
        $row->{company_id} = $company->id;
    }
    $row->{expired_at} ||= \"DATE_ADD(NOW(), INTERVAL 1 MONTH)"; #" default to expired after 1 month
    $row->{inserted_at} = time();

    $row->{location_id} = $schema->resultset('Location')->get_location_id_from_text($row->{location}) if $row->{location};

    $row->{type} ||= '';
    $row->{contact} ||= '';
    $row->{location} ||= '';
    $row->{location_id} ||= '';
    $row->{company_id} ||= '';
    $row->{extra} ||= '';

    $self->create($row);
}

sub update_job {
    my ($self, $row) = @_;

    my $schema = $self->result_source->schema;
    if ( exists $row->{company} and not $row->{company_id} ) {
        my $company = $schema->resultset('Company')->get_or_create(delete $row->{company});
        $row->{company_id} = $company->id;
    }
    $row->{expired_at} ||= \"DATE_ADD(NOW(), INTERVAL 1 MONTH)"; #" default to expired after 1 month
    $row->{inserted_at} = time();

    $row->{location_id} = $schema->resultset('Location')->get_location_id_from_text($row->{location}) if $row->{location};

    my $source_url = delete $row->{source_url};
    $self->search( { source_url => $source_url } )->update($row);
}

sub delete_job {
    my ($self, $id) = @_;

    $self->search({ id => $id })->delete;

    my $schema = $self->result_source->schema;
    $schema->resultset('ObjecTag')->search({ object => $id })->delete;
}

1;