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
    if (not $user->token or $c->param('revoke')) {
        my $token = rand_string(12);
        $user->token($token);
        $user->update();
    }
}

sub updates {
    my $c = shift;

    my $ref = $c->param('ref') || ''; # Chrome extension ref=chrome
    my $is_json = ($ref =~ /chrome/) ? 1 : 0;
    my $is_notification = ($ref =~ /chrome/) ? 1 : 0;
    my $is_feed = $c->stash('is_feed');

    my $user_id = 0;
    my $token = $c->param('token');
    if ($token) {
        my ($_id, $_token) = ($token =~ /^(.*?)\-(\w{12})$/);
        if ($_id) {
            my $_user = $c->schema->resultset('User')->find($_id);
            $user_id = $_user->id if $_user->token eq $_token;
        }
    } elsif (my $user = $c->stash('user')) {
        $user_id = $user->id;
    }
    unless ($user_id) {
        return $c->render(json => { error => "Token is required or invalid."}) if $is_json;
        return $c->redirect_to('/user/login');
    }

    my $rows = ($is_json) ? 10 : 100;
    $rows = 20 if $is_feed;

    my $schema = $c->schema;
    my $dbh = $schema->storage->dbh;

    my @updates;

    my $min_pushed_at = $c->param('min_pushed_at') || 0;
    my $rs = $c->schema->resultset('UserUpdate')->search({
        user_id => $user_id,
        $min_pushed_at ? (pushed_at => {'>', $min_pushed_at}) : (),
    }, {
        rows => $rows,
        $is_notification ? (order_by => 'pushed_at') : (order_by => \'pushed_at DESC'), #'
    });
    while (my $r = $rs->next) {
        # only job and freelance for now
        my $obj = $schema->resultset(ucfirst $r->tbl)->find($r->object_id);
        next unless $obj;

        # get follow obj (FIXME)

        $obj->{follow_id} = $r->follow_id;
        $obj->{pushed_at} = $r->pushed_at;
        $obj->{tbl}       = $r->tbl if $is_feed;
        if ($is_notification) {
            unshift @updates, $obj;
        } else {
            push @updates, $obj;
        }
    }
    if ($is_json) {
        my $max_pushed_at = $min_pushed_at;
        my @jdata;
        foreach my $obj (@updates) {
            my $data = {
                title => $obj->title,
                url   => $obj->url,
                id    => $obj->id,
                pushed_at => $obj->{pushed_at},
                follow_id => $obj->{follow_id},
            };
            push @jdata, $data;
            $max_pushed_at = $data->{pushed_at} if $data->{pushed_at} > $max_pushed_at;
        }
        $c->render(json => { 'updates' => \@jdata, max_pushed_at => $max_pushed_at });
    } elsif ($is_feed) {
        $c->stash(title => "User Updates");
        return $c->stash('feeds' => \@updates);
    } else {

        my $sth = $dbh->prepare("SELECT tag.* FROM tag JOIN user_follow uf ON tag.id=uf.follow_id WHERE uf.user_id = ?");
        $sth->execute($user_id);
        $c->stash(followed_tags => $sth->fetchall_arrayref({}));

        $c->stash(updates => \@updates);
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
        $c->redirect_to('/user/updates');
    }
}

sub unfollow {
    my $c = shift;

    my $follow_id = $c->param('follow_id');
    if ($follow_id) {
        my $user = $c->stash('user');
        $c->schema->resultset('UserFollow')->search( {
            user_id => $user->id,
            follow_id => $follow_id
        } )->delete;
    }

    if ($c->req->is_xhr) {
        $c->render(json => {'success' => 1});
    } else {
        $c->redirect_to('/user/updates');
    }
}

1;