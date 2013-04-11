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
            $self->stash(title => "Recent");
            map { $_->{tbl} = 'job' } @jobs;
            return $self->_render_feed(@jobs);
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
            $self->stash(title => "Recent");
            map { $_->{tbl} = 'job' } @jobs;
            return _render_feed(@jobs);
        }
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

    my $p = $self->stash('page');
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

sub location {
    my $self = shift;

    my $schema = $self->schema;
    my $location_id = $self->stash('id');

    my $location = $schema->resultset('Location')->find($location_id);
    $self->stash(location => $location);

    my $p = $self->stash('page');
    $p = 1 unless $p and $p =~ /^\d+$/;
    my $job_rs = $schema->resultset('Job')->search( {
        location_id => $location_id
    }, {
        order_by => 'inserted_at DESC',
        rows => 12,
        page => $p
    });
    $self->stash(pager => $job_rs->pager);
    $self->stash(jobs  => [ $job_rs->all ]);

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

    my $p = $self->stash('page');
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

    if ($self->stash('is_feed')) {
        $self->stash(title => $tag->text);
        return _render_feed(@obj);
    }

    $self->render(template => 'tag');
}

sub _render_feed {
    my ($self, @obj) = @_;

    my $config = $self->sconfig;
    my $feed_format = $self->stash('is_feed');

    require DateTime;
    require XML::Feed;

    my @entries;
    foreach my $obj (@obj) {
        my ($title, $content, $link, $author, $issued);
        # refer templates/object.tt2
        if ($obj->{tbl} eq 'job' or $obj->{tbl} eq 'freelance') {
            $link = $config->{sites}->{main} . $obj->url;
            $title = $obj->title;
            $author = ($obj->{tbl} eq 'job') ? $obj->company->name : 'FindmJob.com';
            $content = $obj->description;
            $issued  = DateTime->from_epoch( epoch => $obj->inserted_at );
        } elsif ($obj->{tbl} eq 'company') {
            $link = $config->{sites}->{main} . $obj->url;
            $title = $obj->name;
        }

        push @entries, {
            id => $link,
            link => $link,
            title => $title,
            $issued ? (issued => $issued, modified => $issued) : (),
            $author ? (author => $author) : (),
            $content ? (content => $content) : (),
        };
    }

    my $mime = ("atom" eq $feed_format) ? "application/atom+xml" : "application/rss+xml";
    $self->res->headers->content_type($mime);

    my $format = ("atom" eq $feed_format) ? 'Atom' : 'RSS';
    my $feed = XML::Feed->new($format);

    my %feed_properties = (
        title   => $self->stash('title') . " Jobs - FindmJob.com",
        description => 'Find My Job Today',
        id      => $config->{sites}->{main},
        modified => DateTime->now,
        entries  => \@entries,
    );
    foreach my $x (keys %feed_properties) {
        $feed->$x($feed_properties{$x});
    }

    foreach my $entry (@entries) {
        my $e = XML::Feed::Entry->new($format);
        foreach my $x (keys %$entry) {
            $e->$x($entry->{$x});
        }
        $feed->add_entry($e);
    }

    $self->render(text => $feed->as_xml);
}

1;