package FindmJob::WWW;

use Dancer ':syntax';

our $VERSION = '0.1';

use FindmJob::Basic;
use Encode;
use JSON::XS ();
use Dancer::Plugin::Feed;
use Sphinx::Search;

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
    var html_filename => $1;
    forward $uri;
};

# temp fix
get qr'.+/$' => sub {
    my $uri = request->uri;
    $uri =~ s'/$'';
    forward $uri;
};

get '/' => sub {
    my $schema = FindmJob::Basic->schema;
    my $p = vars->{page} || 1; $p = 1 unless $p =~ /^\d+$/;
    my $job_rs = $schema->resultset('Job')->search( undef, {
        order_by => 'inserted_at DESC',
        rows => 12,
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

    template 'index.tt2';
};

get '/job/:jobid' => sub {
    my $jobid = params->{jobid};
    my $schema = FindmJob::Basic->schema;
    my $job = $schema->resultset('Job')->find($jobid);
    if ($job->source_url =~ 'jobs.github.com') {
        $job->title( decode_utf8($job->title) );
        $job->description( decode_utf8($job->description) );
    }
    $job->{extra_data} = JSON::XS->new->utf8->decode( encode_utf8($job->extra) ) if $job->extra =~ /^\{/;
    $job->{tags} = [ $schema->resultset('ObjectTag')->get_tags_by_object($job->id) ];
    var job => $job;

    template 'job.tt2';
};

get qr'/search.*?' => sub {
    my $p = vars->{page} || 1; $p = 1 unless $p =~ /^\d+$/;
    my $row = 12;

    my $q = vars->{html_filename} || params->{'q'};
    print STDERR "QQQQQQQ: $q\n";

    my $sph = Sphinx::Search->new;
    $sph->SetServer('localhost', 9312);
    $sph->SetLimits(($p - 1) * $row, $row, 800);
    $sph->SetMatchMode(SPH_MATCH_EXTENDED2);
    $sph->SetSortMode(SPH_SORT_RELEVANCE);
    my @k = split(/\s+/, $q);
    @k = map { $sph->EscapeString($_) } @k;
    @k = map { '"' . $_ . '"' } @k;
    my $k = '(' . join(' & ', @k) . ')';
    my $ret = $sph->Query('@* ' . $k);
    if ($ret->{total}) {
        my @jobids = map { $_->{id} } @{$ret->{matches}};
        my $schema = FindmJob::Basic->schema;
        my @jobs   = $schema->resultset('Job')->search( {
            id => { 'IN', \@jobids }
        } )->all;
        my %jobs = map { $_->id => $_ } @jobs;
        @jobs = map { $jobs{$_} } @jobids;
        var jobs => \@jobs;
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
    if ( length($tagid) == 22) {
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

    var pager => $rs->pager;
    var objects => \@obj;

    if (vars->{feed_format}) {
        var title => $tag->text;
        return _render_feed(@obj);
    }

    template 'tag.tt2';
};

sub _render_feed {
    my (@obj) = @_;

    my $config = FindmJob::Basic->config;

    my @entries;
    foreach my $obj (@obj) {
        my ($title, $content, $link, $author);
        # refer templates/object.tt2
        if ($obj->{tbl} eq 'job') {
            $link = $config->{sites}->{main} . $obj->url;
            $title = $obj->title;
            $author = $obj->company->name;
            $content = $obj->description;
        } elsif ($obj->{tbl} eq 'company') {
            $link = $config->{sites}->{main} . $obj->url;
            $title = $obj->name;
        }

        push @entries, {
            id => $obj->id,
            link => $link,
            title => $title,
            $author ? (author => $author) : (),
            $content ? (content => $content) : (),
        };
    }

    my $feed = create_feed(
        format  => vars->{feed_format},
        title   => vars->{title} . " Jobs - FindmJob.com",
        entries => \@entries,
    );
    return $feed;
}

true;