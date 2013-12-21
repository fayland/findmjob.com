package FindmJob::WWW::User;

use Mojo::Base 'Mojolicious::Controller';

sub login {}
sub logout {
    my $c = shift;
    delete $c->session->{__user};
    $c->redirect_to('/');
}

1;