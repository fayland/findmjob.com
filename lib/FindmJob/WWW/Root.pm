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

sub company {
    my $self = shift;

    my $schema = $self->schema;
    my $companyid = $self->stash('id');

    my $company = $schema->resultset('Company')->find($companyid);
    $self->stash(company => $company);

    my ($p) = ($self->req->url->path =~ m{/p\.(\d+)(/|$)});
    $p = 1 unless $p and $p =~ /^\d+$/;
    my $job_rs = $schema->resultset('Job')->search( {
        company_id => $companyid
    }, {
        order_by => 'inserted_at DESC',
        rows => 12,
        page => $p
    });
    $self->stash(pager => $job_rs->pager);
    $self->stash(jobs  => [ $job_rs->all ]);

    $self->render(template => 'company');
}

sub tag {
    my $self = shift;

    my $schema = $self->schema;
    my $tagid = $self->stash('id');

    my $tag;
    if (length($tagid) == 22) {
        $tag = $schema->resultset('Tag')->find($tagid);
    }
    unless ($tag) {
        $tag = $schema->resultset('Tag')->get_row_by_text($tagid);
        $tagid = $tag->id if $tag;
    }
    $self->stash(tag => $tag);

    my ($p) = ($self->req->url->path =~ m{/p\.(\d+)(/|$)});
    $p = 1 unless $p and $p =~ /^\d+$/;
    my $rs = $schema->resultset('ObjectTag')->search( {
        tag => $tagid
    }, {
        order_by => 'time DESC',
        rows => 12,
        page => $p
    });

    my @obj;
    while (my $row = $rs->next) {
        my $tbl = $row->object->tbl;
        my $obj = $schema->resultset(ucfirst $tbl)->find($row->object->id);
        $obj->{tbl} = $tbl;
        push @obj, $obj;
    }

    $self->stash(pager => $rs->pager);
    $self->stash(objects => \@obj);

#    if (vars->{feed_format}) {
#        var title => $tag->text;
#        return _render_feed(@obj);
#    }

    $self->render(template => 'tag');
}

1;