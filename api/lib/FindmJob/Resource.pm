package FindmJob::Resource;

use strict;
use warnings;
use parent 'Web::Machine::Resource';

use JSON::XS 'encode_json';
use FindmJob::Basic;
use FindmJob::Search;
use URI::Escape ();

# read-only API for now
sub content_types_provided { [{ 'application/json' => 'to_json'   }] }

sub resource_exists {
    my $self = shift;

    my $req = $self->request;
    my $path_info = $req->path_info;

    # simple dispatch
    if ($path_info =~ '/search') {
        return $self->_dispatcher('search');
    } elsif ($path_info =~ '/job/(\w+)') {
        return $self->_dispatcher('job', $1);
    }

    return 0;
}

sub _dispatcher {
    my ($self, $action, @args) = @_;

    my $req = $self->request;
    my $schema = FindmJob::Basic->schema;

    my $data;
    if ($action eq 'job') {
        my $id = shift @args;
        my $job = $schema->resultset('Job')->find($id);
        return 0 unless $job;
        $data = _export_job_as_hashref($job);
    } elsif ($action eq 'search') {
        my $q   = $req->param('q');
        my $loc = $req->param('loc');
        my $p = $req->param('page'); $p = 1 unless $p and $p =~ /^\d+$/;
        my $search = FindmJob::Search->new;
        my $ret = $search->search_job( {
            'q' => $q,
            loc => $loc,
            rows => 12,
            page => $p,
        } );
        my @data;
        if ($ret->{total}) {
            my @jobids = map { $_->{id} } @{$ret->{matches}};
            my $schema = FindmJob::Basic->schema;
            my @jobs   = $schema->resultset('Job')->search( {
                id => { 'IN', \@jobids }
            } )->all;
            my %jobs = map { $_->id => $_ } @jobs;
            @jobs = map { $jobs{$_} } @jobids;

            foreach my $job (@jobs) {
                push @data, _export_job_as_hashref($job);
            }
            $data->{jobs}  = \@data;
            $data->{total} = $ret->{total};
            $data->{page}  = $p;
        } else {
            $data->{jobs} = [];
            $data->{total} = 0;
        }
    }
    $self->{_data} = $data;
    return 1;
}

sub _export_job_as_hashref {
    my $job = shift;

    my $data;

    # only known cols are exported
    foreach my $col ('id', 'source_url', 'title', 'location', 'description', 'type', 'contact', 'inserted_at', 'expired_at') {
        $data->{$col} = $job->get_column($col);
    }

    # related company and tags
    my @tags = @{ $job->tags };
    @tags = map { $_->{text} } @tags;
    $data->{tag} = \@tags;
    my $company = $job->company;
    $data->{company} = { id => $company->id, name => $company->name, website => $company->website };

    return $data;
}

sub to_json {
    my $self = shift;
    my $json = encode_json( $self->{_data} );
    if (my $callback = $self->request->param('callback')) {
        my $cb = URI::Escape::uri_unescape($callback);
        $json = "$cb($json)";
    }
    return $json;
}

1;