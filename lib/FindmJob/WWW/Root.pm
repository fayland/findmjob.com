package FindmJob::WWW::Root;

use Mojo::Base 'Mojolicious::Controller';
use Mojo::JSON;
use Encode;

sub index {
    my $self = shift;

    my $schema = $self->schema;
    my $job_rs = $schema->resultset('Job')->search( undef, {
        order_by => 'inserted_at DESC',
        rows => 6,
        page => 1,
    });
    $self->stash->{jobs} = [$job_rs->all];
    my $freelance_rs = $schema->resultset('Freelance')->search( undef, {
        order_by => 'inserted_at DESC',
        rows => 6,
        page => 1,
    });
    $self->stash->{freelances} = [$freelance_rs->all];

    $self->render(template => 'index');
}

sub jobs {
    my $self = shift;

    my $schema = $self->schema;

    my ($p) = ($self->req->url->path =~ m{/p\.(\d+)(/|$)});
    $p = 1 unless $p and $p =~ /^\d+$/;
    my $rows = 12;

#    if ( vars->{feed_format} ) {
#        $rows = 20; # more for feeds
#        $p = 1;
#    }

    my $count = $schema->resultset('Job')->count();
    # avoid slow 'LIMIT 96828, 12'
    if ( $count > ($p - 1) * $rows ) {
        my $job_rs = $schema->resultset('Job')->search( undef, {
            order_by => 'inserted_at DESC',
            rows => $rows,
            page => $p
        });
        my @jobs = $job_rs->all;
        $self->stash->{pager} = $job_rs->pager;
        $self->stash->{jobs}  = \@jobs;

#        if (vars->{feed_format}) {
#            var title => "Recent";
#            map { $_->{tbl} = 'job' } @jobs;
#            return _render_feed(@jobs);
#        }
    }

    $self->render(template => 'jobs');
}

sub freelances {
    my $self = shift;

    my $schema = $self->schema;

    my ($p) = ($self->req->url->path =~ m{/p\.(\d+)(/|$)});
    $p = 1 unless $p and $p =~ /^\d+$/;
    my $rows = 12;

#    if ( vars->{feed_format} ) {
#        $rows = 20; # more for feeds
#        $p = 1;
#    }

    my $count = $schema->resultset('Freelance')->count();
    # avoid slow 'LIMIT 96828, 12'
    if ( $count > ($p - 1) * $rows ) {
        my $job_rs = $schema->resultset('Freelance')->search( undef, {
            order_by => 'inserted_at DESC',
            rows => $rows,
            page => $p
        });
        my @jobs = $job_rs->all;
        $self->stash->{pager} = $job_rs->pager;
        $self->stash->{jobs}  = \@jobs;

#        if (vars->{feed_format}) {
#            var title => "Recent";
#            map { $_->{tbl} = 'job' } @jobs;
#            return _render_feed(@jobs);
#        }
    }

    $self->render(template => 'freelances');
}

sub job {
    my $self = shift;

    my $schema = $self->schema;
    my $jobid = $self->stash('id');
    my $job = $schema->resultset('Job')->find($jobid);

    unless ($job) {
        return $self->render(template => 'gone');
    }

    if ($job->source_url =~ 'jobs.github.com') {
        $job->title( decode_utf8($job->title) );
        $job->description( decode_utf8($job->description) );
    }
    $job->{extra_data} = Mojo::JSON->new->decode( encode_utf8($job->extra) ) if $job->extra =~ /^\{/;
    $self->stash(job => $job);

    $self->render(template => 'job');
}

sub freelance {
    my $self = shift;

    my $schema = $self->schema;
    my $jobid = $self->stash('id');
    my $job = $schema->resultset('Freelance')->find($jobid);

    unless ($job) {
        return $self->render(template => 'gone');
    }

    $job->{extra_data} = Mojo::JSON->new->decode( encode_utf8($job->extra) ) if $job->extra =~ /^\{/;
    $self->stash(job => $job);

    $self->render(template => 'freelance');
}

1;