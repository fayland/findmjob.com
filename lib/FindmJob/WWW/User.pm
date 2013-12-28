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

sub follow {
    my $c = shift;

    my $follow_id = $c->param('follow_id');
    if ($follow_id) {
        my $user = $c->stash('user');
        $c->schema->resultset('UserFollow')->find_or_create( {
            user_id => $user->id,
            follow_id => $follow_id
        } );
    }

    if ($c->req->is_xhr) {
        $c->render(json => {'success' => 1});
    } else {
        $c->redirect_to('/'); # FIXME, to /user/followed
    }
}

1;