package FindmJob::WWW;

use Mojo::Base 'Mojolicious';
use FindmJob::Basic;
use File::Spec::Functions 'catdir';

sub startup {
    my $self = shift;

    my $config = FindmJob::Basic->config;
    $self->secret($config->{secret_hash});
    $self->helper(sconfig => sub { return $config });
    $self->helper(schema => sub { FindmJob::Basic->schema });
    unshift @{$self->static->paths}, catdir( FindmJob::Basic->root, 'static' );

    $self->plugin('charset' => {charset => 'UTF-8'});
    $self->plugin('tt_renderer' => {
        template_options => {
            WRAPPER => 'wrapper.tt2'
        }
    });
    $self->renderer->default_handler( 'tt' );

    my $r = $self->routes;
    $r->namespaces(['FindmJob::WWW']);

    # feed.(rss|atom) and /p.2/
    $self->hook(before_dispatch => sub {
        my $self = shift;

        my $p = $self->req->url->path;
        if ($p =~ s{/feed\.(rss|atom)$}{}) {
            $self->stash('is_feed' => $1);
        }
        if ($p =~ s{/p\.(\d+)(/|$)}{$2}) {
            $self->stash('page' => $1);
        }
        $self->req->url->path($p);

        if ($self->req->url->host =~ /fb/) { # fb.findmjob.com
            $self->stash(is_fb_app => 1);
        }

        # config into stash
        $self->stash(config => $config);
    });

    $r->any('/')->to(controller => 'Root', action => 'index');
    $r->get('/jobs')->to(controller => 'Root', action => 'jobs');
    $r->get('/freelances')->to(controller => 'Root', action => 'freelances');
    $r->get('/job/:id')->to(controller => 'Root', action => 'job');
    $r->get('/job/:id/*seo')->to(controller => 'Root', action => 'job');
    $r->get('/freelance/:id')->to(controller => 'Root', action => 'freelance');
    $r->get('/freelance/:id/*seo')->to(controller => 'Root', action => 'freelance');
    $r->any('/search/*rest')->to(controller => 'Search', action => 'search');
    $r->get('/company/:id')->to(controller => 'Root', action => 'company');
    $r->get('/company/:id/*seo')->to(controller => 'Root', action => 'company');
    $r->get('/tag/:id')->to(controller => 'Root', action => 'tag');
    $r->get('/tag/:id/*seo')->to(controller => 'Root', action => 'tag');
    $r->post('/subscribe')->to(controller => 'Subscribe', action => 'subscribe');
    $r->get('/subscribe/confirm')->to(controller => 'Subscribe', action => 'confirm');

    ## html files
    $r->get('/:html.html' => sub {
        my $self = shift;
        my $html = $self->stash('html');
        if ($html !~ /\./ and -e FindmJob::Basic->root . "/templates/" . $html . ".html.tt") {
            $self->render(template => $html);
        }
    });
}

1;