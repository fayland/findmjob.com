package FindmJob::Resource;

use strict;
use warnings;
use parent 'Web::Machine::Resource';

use JSON::XS ();
use FindmJob::Basic;
use FindmJob::Search;

my $JSON = JSON::XS->new->allow_nonref->pretty;

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
    } elsif ($action eq 'search') {
        my $q = $req->param('q');
        my $p = $req->param('page'); $p = 1 unless $p and $p =~ /^\d+$/;
        my $search = FindmJob::Search->new;
        my $ret = $search->search_job( {
            'q' => $q,
            rows => 12,
            page => $p,
        } );
    }
    $self->{_data} = $data;
    return 1;
}

sub to_json { $JSON->encode( (shift)->{_data} ) }

1;