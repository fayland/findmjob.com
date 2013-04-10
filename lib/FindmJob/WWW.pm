package FindmJob::WWW;

use Mojo::Base 'Mojolicious';
use FindmJob::Basic;
use FindmJob::Search;
use Encode;
use JSON::XS ();
use Data::Page;
use DateTime ();
use Digest::MD5 'md5_hex';
use File::Spec::Functions 'catdir';

sub startup {
    my $self = shift;

    my $config = FindmJob::Basic->config;
    $self->secret($config->{secret_hash});
    $self->helper(config => sub { return $config });
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
    $r->route('/')->to(controller => 'Root', action => 'index');
    $r->route('/jobs')->to(controller => 'Root', action => 'jobs');
    $r->route('/freelances')->to(controller => 'Root', action => 'freelances');
    $r->route('/job/:id')->to(controller => 'Root', action => 'job');
    $r->route('/job/:id/*seo')->to(controller => 'Root', action => 'job');
    $r->route('/freelance/:id')->to(controller => 'Root', action => 'freelance');
    $r->route('/freelance/:id/*seo')->to(controller => 'Root', action => 'freelance');
    $r->route('/search/*rest')->to(controller => 'Search', action => 'search');
    $r->route('/company/:id')->to(controller => 'Root', action => 'company');
    $r->route('/company/:id/*seo')->to(controller => 'Root', action => 'company');
    $r->route('/tag/:id')->to(controller => 'Root', action => 'tag');
    $r->route('/tag/:id/*seo')->to(controller => 'Root', action => 'tag');
    $r->post('/subscribe')->to(controller => 'Subscribe', action => 'subscribe');
    $r->get('/subscribe/confirm')->to(controller => 'Subscribe', action => 'confirm');
}

1;