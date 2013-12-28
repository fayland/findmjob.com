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

sub updates {
    my $c = shift;

    my $ref = $c->param('ref') || ''; # Chrome extension ref=chrome

    my $user_id = 0;
    my $token = $c->param('token');
    if ($token) {
        my ($_id, $_token) = ($token =~ /^(.*?)\-(\w{12})$/);
        if ($_id) {
            my $_user = $c->schema->resulset('User')->find($_id);
            $user_id = $user->id if $user->token eq $_token;
        }
    } elsif (my $user = $c->stash('user')) {
        $user_id = $user->id;
    }
    unless ($user_id) {
        return $c->render(json => { error => "Token is required. "}) if $ref eq 'chrome';
        return $c->redirect_to('/user/login');
    }

    # my @follow_ids;
    # my $rs = $c->schema->resultset('UserFollow')->search({ user_id => $user_id });
    # while (my $r = $rs->next) { push @follow_ids, $r->follow_id; }

    my @updates;
    my $rs = $c->schema->resultset('UserUpdates')->search({ user_id => $user_id });
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