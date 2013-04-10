package FindmJob::WWW;

use Dancer ':syntax';

our $VERSION = '0.1';

use FindmJob::Basic;
use FindmJob::Search;
use Encode;
use JSON::XS ();
use Dancer::Plugin::Feed;
use Data::Page;
use DateTime ();
use Digest::MD5 'md5_hex';

# different template dir than default one
setting 'views'  => path( FindmJob::Basic->root, 'templates' );
setting 'public' => path( FindmJob::Basic->root, 'static' );

hook before_template_render => sub {
    my $tokens = shift;

    # merge vars into token b/c I like it more
    my $vars = delete $tokens->{vars} || {};
    foreach (keys %$vars) {
        $tokens->{$_} = $vars->{$_};
    }

    ## if it is Facebook App
    if (request->host =~ /fb/) { # fb.findmjob.com
        $tokens->{is_fb_app} = 1;
    }

    $tokens->{config} = FindmJob::Basic->config;
};

# abuse the pattern
# 1. pager
get qr'.*?/p\.(\d+).*?' => sub {
    my $uri = request->uri;
    $uri =~ s'/p\.(\d+)'';
    var page => $1;
    $uri =~ s/\/$//;
    forward $uri;
};
# 2. rss/atom feed
get qr'.*?/feed\.(rss|atom).*?' => sub {
    my $uri = request->uri;
    $uri =~ s'/feed\.(rss|atom)'';
    var feed_format => $1;
    $uri =~ s/\/$//;
    forward $uri;
};
# 3. seo
get qr'.*?/([^\/]+).html' => sub {
    my $uri = request->uri;
    $uri =~ s'/([^\/]+).html'';
    my $html = $1;

    # some static TT2 files
    if ($html !~ /\./ and -e FindmJob::Basic->root . "/templates/" . $html . ".tt2") {
        template "$html.tt2";
    } else {
        var html_filename => $html;
        forward $uri;
    }
};

# temp fix
get qr'.+/$' => sub {
    my $uri = request->uri;
    $uri =~ s'/$''g;
    forward $uri;
};

any ['head', 'get', 'post'] => '/' => sub {
    # backwards
    if ( vars->{page} or vars->{feed_format} ) {
        forward '/jobs';
    }

    my $schema = FindmJob::Basic->schema;
    my $job_rs = $schema->resultset('Job')->search( undef, {
        order_by => 'inserted_at DESC',
        rows => 6,
        page => 1,
    });
    var jobs  => [$job_rs->all];
    var jobs_pager => $job_rs->pager;
    my $freelance_rs = $schema->resultset('Freelance')->search( undef, {
        order_by => 'inserted_at DESC',
        rows => 6,
        page => 1,
    });
    var freelances => [$freelance_rs->all];
    var freelances_pager => $freelance_rs->pager;

    template 'index.tt2';
};

get '/jobs' => sub {
    my $schema = FindmJob::Basic->schema;

    my $p = vars->{page} || 1; $p = 1 unless $p =~ /^\d+$/;
    my $rows = 12;
    if ( vars->{feed_format} ) {
        $rows = 20; # more for feeds
        $p = 1;
    }

    my $job_rs = $schema->resultset('Job')->search( undef, {
        order_by => 'inserted_at DESC',
        rows => $rows,
        page => $p
    });
    my @jobs = $job_rs->all;
    var pager => $job_rs->pager;
    var jobs  => \@jobs;

    if (vars->{feed_format}) {
        var title => "Recent";
        map { $_->{tbl} = 'job' } @jobs;
        return _render_feed(@jobs);
    }

    template 'jobs.tt2';
};

get '/freelances' => sub {
    my $schema = FindmJob::Basic->schema;

    my $p = vars->{page} || 1; $p = 1 unless $p =~ /^\d+$/;
    my $rows = 12;
    if ( vars->{feed_format} ) {
        $rows = 20; # more for feeds
        $p = 1;
    }

    my $job_rs = $schema->resultset('Freelance')->search( undef, {
        order_by => 'inserted_at DESC',
        rows => $rows,
        page => $p
    });
    my @jobs = $job_rs->all;
    var pager => $job_rs->pager;
    var jobs  => \@jobs;

    if (vars->{feed_format}) {
        var title => "Recent";
        map { $_->{tbl} = 'freelance' } @jobs;
        return _render_feed(@jobs);
    }

    template 'freelances.tt2';
};

get qr'/job/.+' => sub {
    my ($jobid) = (request->uri =~ '/job/([^\/]+)');
    my $schema = FindmJob::Basic->schema;
    my $job = $schema->resultset('Job')->find($jobid);

    unless ($job) {
        # check if it's inside freelance since we split it into two parts: jobs and freelance
        if ($schema->resultset('Freelance')->count( { id => $jobid } )) {
            redirect "/freelance/$jobid", 301;
            return;
        }

        forward '/410', { status => 410 };
    }

    if ($job->source_url =~ 'jobs.github.com') {
        $job->title( decode_utf8($job->title) );
        $job->description( decode_utf8($job->description) );
    }
    $job->{extra_data} = JSON::XS->new->utf8->decode( encode_utf8($job->extra) ) if $job->extra =~ /^\{/;
    var job => $job;

    template 'job.tt2';
};

get qr'/freelance/.+' => sub {
    my ($jobid) = (request->uri =~ '/freelance/([^\/]+)');
    my $schema = FindmJob::Basic->schema;
    my $job = $schema->resultset('Freelance')->find($jobid);

    unless ($job) {
        forward '/410', { status => 410 };
    }

    $job->{extra_data} = JSON::XS->new->utf8->decode( encode_utf8($job->extra) ) if $job->extra =~ /^\{/;
    var job => $job;

    template 'freelance.tt2';
};

get qr'/search.*?' => sub {
    my $p = vars->{page} || 1; $p = 1 unless $p =~ /^\d+$/;
    my $rows = 12;

    my $q = params->{'q'};
    my $loc = params->{loc} || '';
    my $by  = params->{by} || 'relevance';
    my $filename = vars->{html_filename};
    if ($filename) {
        $filename =~ s/\_by\_(date|relevance)$// and $by = $1;
        $filename =~ s/(^|\_)in\_(\w+)$// and $loc = $2;
        $q = $filename;
    }
    var 'q'    => $q;
    var 'loc'  => $loc;
    var 'sort' => $by;

    my $search = FindmJob::Search->new;
    my $ret = $search->search_job( {
        'q'  => $q,
        loc  => $loc,
        sort => $by,
        rows => $rows,
        page => $p,
    } );
    if ($ret->{total}) {
        my $schema = FindmJob::Basic->schema;

        my @ids    = map { $_->{id} } @{$ret->{matches}};
        my @jobids = map { $_->{id} } grep { $_->{tbl} eq 'job' } @{$ret->{matches}};
        my @freelance_ids = map { $_->{id} } grep { $_->{tbl} eq 'freelance' } @{$ret->{matches}};

        my %ids;
        if (@jobids) {
            my @jobs   = $schema->resultset('Job')->search( {
                id => { 'IN', \@jobids }
            } )->all;
            %ids = map { $_->id => $_ } @jobs;
        }
        if (@freelance_ids) {
            my @jobs   = $schema->resultset('Freelance')->search( {
                id => { 'IN', \@freelance_ids }
            } )->all;
            map { $ids{$_->id} = $_ } @jobs;
        }

        my @jobs = map { $ids{$_} } @ids;
        var jobs => \@jobs;

        # pager
        my $pager = Data::Page->new();
        $pager->total_entries($ret->{total});
        $pager->entries_per_page($rows);
        $pager->current_page($p);
        var pager => $pager;
    }

    template 'search.tt2';
};

get '/company/:companyid' => sub {
    my $companyid = params->{companyid};
    my $schema = FindmJob::Basic->schema;
    my $company = $schema->resultset('Company')->find($companyid);
    var company => $company;

    my $p = vars->{page} || 1; $p = 1 unless $p =~ /^\d+$/;
    my $job_rs = $schema->resultset('Job')->search( {
        company_id => $companyid
    }, {
        order_by => 'posted_at DESC',
        rows => 12,
        page => $p
    });
    var pager => $job_rs->pager;
    var jobs  => [ $job_rs->all ];

    template 'company.tt2';
};

get '/tag/:tagid' => sub {
    my $tagid = params->{tagid};

    my $schema = FindmJob::Basic->schema;
    my $tag;
    if (length($tagid) == 22) {
        $tag = $schema->resultset('Tag')->find($tagid);
    }
    unless ($tag) {
        $tag = $schema->resultset('Tag')->get_row_by_text($tagid);
        $tagid = $tag->id if $tag;
    }
    var tag => $tag;

    my $p = vars->{page} || 1; $p = 1 unless $p =~ /^\d+$/;
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

    var pager => $rs->pager;
    var objects => \@obj;

    if (vars->{feed_format}) {
        var title => $tag->text;
        return _render_feed(@obj);
    }

    template 'tag.tt2';
};

post '/subscribe' => sub {
    my $keyword = params->{keyword};
    my $frm = params->{frm} || 'search';
    $frm = 'search' unless grep { $_ eq $frm } ('search', 'tag', 'company');
    my $loc = params->{loc} || '';
    my $frequency_days = params->{frequency_days};
    $frequency_days = 1 unless $frequency_days and $frequency_days eq '7';
    my $email = params->{email};

    # we do not validate email now, instead, we drop invalid email in cron when started
    if ($email and $keyword) {
        my $schema = FindmJob::Basic->schema;
        my $r = $schema->resultset('Subscriber')->create( {
            email => $email,
            frm   => $frm,
            keyword => $keyword,
            loc => $loc,
            frequency_days => $frequency_days,
            created_at => time(),
            last_sent => 0,
            is_active => 0,
        } );
        var subscriber => $r;
    }

    template 'subscribe.tt2';
};

get '/subscribe/confirm' => sub {
    my $id   = params->{id};
    my $hash = params->{hash};

    my $suc = 0;
    if ($id and $hash) {
        ## check cron/emails/subscribe_confirm.pl
        my $config = FindmJob::Basic->config;
        my $sec = md5_hex($id . $config->{secret_hash});
        if ($hash eq $sec) {
            $suc = 1;
            my $schema = FindmJob::Basic->schema;
            $schema->resultset('Subscriber')->search( { id => $id } )->update( { is_active => 1 } );
        }
    }
    var suc => $suc;

    template 'subscribe_confirm.tt2';
};

any qr{.*} => sub {
    if (params->{status} and params->{status} eq '410') {
        status 'gone';
        template 'gone.tt2';
    } else {
        status 'not_found';
        template 'not_found.tt2';
    }
};

sub _render_feed {
    my (@obj) = @_;

    my $config = FindmJob::Basic->config;

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

    my $feed = create_feed(
        format  => vars->{feed_format},
        title   => vars->{title} . " Jobs - FindmJob.com",
        description => 'Find My Job Today',
        id      => $config->{sites}->{main},
        modified => DateTime->now,
        entries  => \@entries,
    );
    return $feed;
}

true;