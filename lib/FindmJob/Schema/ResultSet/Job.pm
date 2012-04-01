package FindmJob::Schema::ResultSet::Job;

use Moose;
use namespace::autoclean;
extends 'FindmJob::Schema::ResultSet';

sub is_inserted_by_url {
    my ($self, $url) = @_;

    return $self->count( { source_url => $url } );
}

sub create_job {
    my ($self, $row) = @_;

    my $schema = $self->result_source->schema;
    my $company = $schema->resultset('Company')->get(delete $row->{company});
    $row->{company_id} = $company->id;
    $row->{inserted_at} = time();
    $self->create($row);
}

sub update_job {
    my ($self, $row) = @_;

    my $schema = $self->result_source->schema;
    my $company = $schema->resultset('Company')->get(delete $row->{company});
    $row->{company_id} = $company->id;
    $row->{inserted_at} = time();
    my $source_url = delete $row->{source_url};
    $self->search( { source_url => $source_url } )->update($row);
}

1;