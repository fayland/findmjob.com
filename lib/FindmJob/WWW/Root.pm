package FindmJob::WWW::Root;

use Mojo::Base 'Mojolicious::Controller';
use Encode;

sub index {
    my $c = shift;

    my $schema = $c->schema;
    my $job_rs = $schema->resultset('Job')->search( undef, {
        order_by => 'inserted_at DESC',
        rows => 6,
        page => 1,
    });
    $c->stash->{jobs} = [$job_rs->all];
    my $freelance_rs = $schema->resultset('Freelance')->search( undef, {
        order_by => 'inserted_at DESC',
        rows => 6,
        page => 1,
    });
    $c->stash->{freelances} = [$freelance_rs->all];

    # popular locations
    $c->stash->{popular_locations} = [ $schema->resultset('Location')->search(undef, {
        order_by => 'job_num DESC',
        rows => 10, page => 1
    })->all ];

    my $is_chrome = $c->req->headers->user_agent =~ /Chrome/ ? 1 : 0;
    $c->stash(is_chrome => $is_chrome);

    $c->render(template => 'index');
}

sub jobs {
    my $self = shift;

    my $schema = $self->schema;

    my $p = $self->stash('page');
    $p = 1 unless $p and $p =~ /^\d+$/;
    my $rows = 12;

    my $is_feed = $self->stash('is_feed');
    if ( $is_feed ) {
        $rows = 20; # more for feeds
        $p = 1;
    }

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

        if ($is_feed) {
            $self->stash(title => "Recent Jobs");
            map { $_->{tbl} = 'job' } @jobs;
            return $self->stash('feeds' => \@jobs);
        }
    }

    $self->render(template => 'jobs');
}

sub freelances {
    my $self = shift;

    my $schema = $self->schema;

    my $p = $self->stash('page');
    $p = 1 unless $p and $p =~ /^\d+$/;
    my $rows = 12;

    my $is_feed = $self->stash('is_feed');
    if ($is_feed) {
        $rows = 20; # more for feeds
        $p = 1;
    }

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

        if ($is_feed) {
            $self->stash(title => "Recent Freelances");
            map { $_->{tbl} = 'freelance' } @jobs;
            return $self->stash('feeds' => \@jobs);
        }
    }

    $self->render(template => 'freelances');
}

sub job {
    my $self = shift;

    my $schema = $self->schema;
    my $jobid = $self->stash('id');
    my $job_rs = $schema->resultset('Job');
    my $job = $job_rs->find($jobid);

    unless ($job) {
        $self->res->code(410); # Gone
        return $self->render(template => 'gone', object => 'job');
    }

    if ($job->source_url =~ 'jobs.github.com') {
        $job->title( decode_utf8($job->title) );
        $job->description( decode_utf8($job->description) );
    }
    $self->stash(job => $job);

    $self->stash(company_jobs => [ $job_rs->jobs_by_company($job->company_id, $job->id) ]);
    $self->stash(location_jobs => [ $job_rs->jobs_by_location($job->location_id, $job->id) ])
        if $job->location_id;
    foreach my $tag (@{ $job->tags }) {
        my @tag_jobs = $job_rs->jobs_by_tag($tag->{id}, $job->id);
        next unless @tag_jobs;
        $self->stash(tag_jobs_text => $tag->{text});
        $self->stash(tag_jobs => \@tag_jobs);
    }

    $self->render(template => 'job');
}

sub freelance {
    my $self = shift;

    my $schema = $self->schema;
    my $jobid = $self->stash('id');
    my $job = $schema->resultset('Freelance')->find($jobid);

    unless ($job) {
        $self->res->code(410); # Gone
        return $self->render(template => 'gone', object => 'freelance');
    }

    $self->stash(job => $job);

    $self->render(template => 'freelance');
}

sub location {
    my $self = shift;

    my $schema = $self->schema;
    my $location_id = $self->stash('id');

    my $location = $schema->resultset('Location')->find($location_id);

    unless ($location) {
        $self->res->code(410); # Gone
        return $self->render(template => 'gone', object => 'location');
    }

    $self->stash(location => $location);

    my $p = $self->stash('page');
    $p = 1 unless $p and $p =~ /^\d+$/;
    my $rows = 12;

    my $is_feed = $self->stash('is_feed');
    if ($is_feed) {
        $rows = 20; # more for feeds
        $p = 1;
    }

    my $job_rs = $schema->resultset('Job')->search( {
        location_id => $location_id
    }, {
        order_by => 'inserted_at DESC',
        rows => $rows,
        page => $p
    });
    my @jobs = $job_rs->all;
    $self->stash(pager => $job_rs->pager);
    $self->stash(jobs  => [@jobs]);

    if ($is_feed) {
        $self->stash(title => "Jobs in " . $location->text);
        map { $_->{tbl} = 'job' } @jobs;
        return $self->stash('feeds' => \@jobs);
    }

    $self->render(template => 'location');
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

    unless ($tag) {
        $self->res->code(410); # Gone
        return $self->render(template => 'gone', object => 'tag');
    }

    my ($view_tab) = ($self->req->url->path =~ m{/\+(freelance|job)/});
    $view_tab ||= '';
    $self->stash(view_tab => $view_tab);

    my $p = $self->stash('page');
    $p = 1 unless $p and $p =~ /^\d+$/;

    my $rs = $schema->resultset('ObjectTag')->search( {
        tag => $tagid,
        ($view_tab) ? (tbl => $view_tab) : (),
    }, {
        order_by => 'me.time DESC',
        prefetch => ['object'],
        '+select' => ['object.tbl', 'object.id'],
        '+as'     => ['tbl', 'object_id'],
        rows => 12,
        page => $p
    });

    my @obj;
    while (my $row = $rs->next) {
        my $tbl = $row->get_column('tbl');
        my $id  = $row->get_column('object_id');
        my $obj = $schema->resultset(ucfirst $tbl)->find($id);
        $obj->{tbl} = $tbl;
        push @obj, $obj;
    }

    if ($self->stash('is_feed')) {
        $self->stash(title => $tag->text);
        return $self->stash('feeds' => \@obj);
    } else {
        my $pager = $rs->pager;
        $self->stash(pager => $pager);
        $self->stash(objects => \@obj);

        # count number in tab
        my %count;
        if ($view_tab) {
            $count{$view_tab} = $pager->total_entries;
        }
        foreach my $tbl ('job', 'freelance') {
            next if $count{$tbl};
            $count{$tbl} = $schema->resultset('ObjectTag')->count( {
                tag => $tagid,
                'object.tbl' => $tbl,
            }, {
                prefetch => ['object']
            } );
        }
        $self->stash(count => \%count);
    }

    $self->render(template => 'tag');
}

1;