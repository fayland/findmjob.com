package FindmJob::WWW;

use Mojo::Base 'Mojolicious';
use FindmJob::Basic;
use FindmJob::Utils 'seo_title';
use File::Spec::Functions 'catdir';

sub startup {
    my $self = shift;

    $self->config(hypnotoad => {
        listen => ['http://*:8080'],
    });

    my $config = FindmJob::Basic->config;
    $self->secret($config->{secret_hash});
    $self->helper(sconfig => sub { return $config });
    $self->helper(schema => sub { FindmJob::Basic->schema });
    unshift @{$self->static->paths}, catdir( FindmJob::Basic->root, 'static' );

    $self->plugin('charset' => {charset => 'UTF-8'});
    $self->plugin('tt_renderer' => {
        template_options => {
            WRAPPER => 'wrapper.tt2',
            FILTERS => {
                seo_title => \&seo_title,
            }
        }
    });
    $self->renderer->default_handler( 'tt' );
    $self->plugin(recaptcha => {
        public_key  => $config->{api}->{recaptcha}->{pub},
        private_key => $config->{api}->{recaptcha}->{pri},
    });

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

        if ($self->req->url->to_abs->host =~ /fb/) { # fb.findmjob.com
            $self->stash(is_fb_app => 1);
        }

        # config into stash
        $self->stash(config => $config);
        $self->stash(base_url => $self->req->url->path->to_string);
    });

    $r->any('/')->to(controller => 'Root', action => 'index');
    $r->get('/jobs')->to(controller => 'Root', action => 'jobs');
    $r->get('/freelances')->to(controller => 'Root', action => 'freelances');
    $r->get('/job/:id')->to(controller => 'Root', action => 'job');
    $r->get('/job/:id/*seo')->to(controller => 'Root', action => 'job');
    $r->get('/freelance/:id')->to(controller => 'Root', action => 'freelance');
    $r->get('/freelance/:id/*seo')->to(controller => 'Root', action => 'freelance');
    $r->any('/search')->to(controller => 'Search', action => 'search');
    $r->any('/search/*rest')->to(controller => 'Search', action => 'search');
    $r->get('/location/:id')->to(controller => 'Root', action => 'location');
    $r->get('/location/:id/*seo')->to(controller => 'Root', action => 'location');
    $r->get('/tag/:id')->to(controller => 'Root', action => 'tag');
    $r->get('/tag/:id/*seo')->to(controller => 'Root', action => 'tag');
    $r->post('/subscribe')->to(controller => 'Subscribe', action => 'subscribe');
    $r->get('/subscribe/confirm')->to(controller => 'Subscribe', action => 'confirm');
    $r->get('/company/:id')->to(controller => 'Root', action => 'company');
    $r->any('/company/:id/jobs')->to(controller => 'Root', action => 'company_jobs');
    $r->any('/company/:id/reviews')->to(controller => 'Review', action => 'company_reviews');
    $r->any('/company/:id/reviews/new')->to(controller => 'Review', action => 'company_review_new');
    $r->get('/company/:cid/review/:rid')->to(controller => 'Review', action => 'review');
    $r->get('/company/:cid/review/:rid/*seo')->to(controller => 'Review', action => 'review');
    $r->get('/company/:id/*seo')->to(controller => 'Root', action => 'company');

    $r->get('/trends')->to(controller => 'Trends', action => 'index');

    $r->any('/help/contact')->to(controller => 'Help', action => 'contact');
    $r->get('/help/:html.html')->to(controller => 'Help', action => 'html');
}

1;