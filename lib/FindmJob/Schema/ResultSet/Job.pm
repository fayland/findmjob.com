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

## shortcuts
sub jobs_by_company {
    my ($self, $company_id, $exclude_job_id) = @_;

    return $self->search( {
        company_id => $company_id,
        $exclude_job_id ? (id => { '<>', $exclude_job_id }) : ()
    }, {
        order_by => 'inserted_at DESC',
        rows => 5, page => 1
    })->all;
}

sub jobs_by_location {
    my ($self, $location_id, $exclude_job_id) = @_;

    return $self->search( {
        location_id => $location_id,
        $exclude_job_id ? (id => { '<>', $exclude_job_id }) : ()
    }, {
        order_by => 'inserted_at DESC',
        rows => 5, page => 1
    })->all;
}

sub jobs_by_tag {
    my ($self, $tag_id, $exclude_job_id) = @_;

    my $schema = $self->result_source->schema;
    my $rs = $schema->resultset('ObjectTag')->search( {
        tag => $tag_id,
        tbl => 'job',
    }, {
        order_by => 'me.time DESC',
        prefetch => ['object'],
        '+select' => ['object.tbl', 'object.id'],
        '+as'     => ['tbl', 'object_id'],
        rows => 10, page => 1
    });

    my @jobs;
    while (my $row = $rs->next) {
        my $tbl = $row->get_column('tbl');
        my $id  = $row->get_column('object_id');
        next if $id eq $exclude_job_id;
        push @jobs, $schema->resultset(ucfirst $tbl)->find($id);
    }

    return @jobs;
}

1;