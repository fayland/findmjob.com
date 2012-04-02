package FindmJob::WWW;

use Dancer ':syntax';

our $VERSION = '0.1';

use FindmJob::Basic;
use Encode;

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

get '/' => sub {
    my $schema = FindmJob::Basic->schema;
    my $p = params->{p} || 1; $p = 1 unless $p =~ /^\d+$/;
    my $job_rs = $schema->resultset('Job')->search( undef, {
        order_by => 'posted_at DESC',
        rows => 12,
        page => $p
    });
    var pager => $job_rs->pager;
    var jobs  => [ $job_rs->all ];

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
    $job->{extra_data} = from_json( $job->extra ) if $job->extra =~ /^\{/;
    $job->{tags} = [ $schema->resultset('ObjectTag')->get_tags_by_object($job->id) ];
    var job => $job;

    template 'job.tt2';
};

get '/company/:companyid' => sub {
    my $companyid = params->{companyid};
    my $schema = FindmJob::Basic->schema;
    my $company = $schema->resultset('Company')->find($companyid);
    var company => $company;

    my $p = params->{p} || 1; $p = 1 unless $p =~ /^\d+$/;
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
    my $tag = $schema->resultset('Tag')->find($tagid);
    var tag => $tag;

    my $p = params->{p} || 1; $p = 1 unless $p =~ /^\d+$/;
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

    template 'tag.tt2';
};

true;
