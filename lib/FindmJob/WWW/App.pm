package FindmJob::WWW::App;

use Mojo::Base 'Mojolicious::Controller';
use FindmJob::Utils qw/uuid rand_string/;
use Digest::MD5 qw/md5_hex/;
use Mojo::UserAgent;

sub index {
    my $c = shift;

    my $schema = $c->schema;
    my $user = $c->stash('user');

    my $delete_id = $c->param('delete_id');
    if ($delete_id) {
        $schema->resultset('App')->search({ id => $delete_id })->delete;
        $c->stash('message' => 'App deleted.');
    }

    my @apps;
    my $rs = $schema->resultset('App')->search({ user_id => $user->id });
    while (my $r = $rs->next) {
        my %data = $r->get_columns();
        push @apps, \%data;
    }
    $c->stash(apps => \@apps);
}

sub create {
    my $c = shift;

    return unless $c->req->method eq 'POST';

    my $user = $c->stash('user');
    my $name = $c->param('name') || '';
    my $website = $c->param('website') || '';

    # validate
    my @errors;
    if (! length($name)) {
        push @errors, "Name is required.";
    } elsif (length($name) > 64) {
        push @errors, "Max length for name is 64."
    }
    if (! length($website)) {
        push @errors, "website is required.";
    } elsif ($website !~ s{^(https?://)?([\w\.\-]+)/?$}{$2}i) {
        push @errors, "Invalid website, please use domain only";
    }

    return $c->stash(errors => \@errors) if @errors;

    my $id = uuid();
    my $schema = $c->schema;
    $schema->resultset('App')->create({
        id => $id,
        secret => rand_string(6),
        name => $name,
        website => $website,
        user_id => $user->id,
    });

    $c->redirect_to("/app/$id/verify");
}

sub verify {
    my $c = shift;

    my $schema = $c->schema;
    my $id = $c->stash('id');
    my $app = $schema->resultset('App')->find($id);
    unless ($app) {
        $c->flash('error' => "Unknown App $id");
        return $c->redirect_to('/app');
    }
    if ($app->is_verified) {
        $c->flash('message' => "App is already verified.");
        return $c->redirect_to('/app');
    }

    my $verify_secret = md5_hex($app->id . '-verify');
    $c->stash(app => $app, verify_secret => $verify_secret);

    my $m = $c->param('m');
    return unless $m;
    return unless $m eq '1' or $m eq '2';

    my $url = 'http://' . $app->website . '/';
    if ($m eq '2') {
        $url .= 'findmjob.verify.html';
    }
    my $ua = Mojo::UserAgent->new;
    $ua->max_redirects(3);
    $ua->inactivity_timeout(30);

    my $tx = $ua->get($url);
    unless ($tx->success) {
        return $c->stash('error' => "Failed to fetch $url: " . $tx->res->error->{message});
    }

    my $verify_ok = 0;
    if ($m eq '2') {
        unless ($tx->res->body =~ /\Q$verify_secret\E/) {
            return $c->stash('error' => "We can't find the $verify_secret in $url.");
        }
    } else {
        my $x = $tx->res->dom('meta[property="findmjob:verify"]');
        return $c->stash('error' => "We can't find the right meta tag in $url.") unless $x;
        return $c->stash('error' => "The meta tag in the $url is not matched with $verify_secret.")
            unless $x->attr('content') eq $verify_secret;
    }

    $app->is_verified(1);
    $app->update();

    $c->flash('message' => 'Verified.');
    $c->redirect_to('/app');
}

1;