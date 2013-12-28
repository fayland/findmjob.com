package FindmJob::WWW::User;

use Mojo::Base 'Mojolicious::Controller';
use FindmJob::Utils 'rand_string';

sub login {}
sub logout {
    my $c = shift;
    delete $c->session->{__user};
    $c->redirect_to('/');
}

sub token {
    my $c = shift;

    my $user = $c->stash('user');
    unless ($user->token) {
        my $token = rand_string(12);
        $user->token($token);
        $user->update();
    }
}

1;