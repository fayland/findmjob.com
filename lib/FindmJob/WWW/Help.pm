package FindmJob::WWW::Help;

use Mojo::Base 'Mojolicious::Controller';
use FindmJob::Basic;
use FindmJob::Email 'sendmail';

sub contact {
    my $c = shift;

    if ($c->req->method eq 'POST') {
        my $email = $c->param('email');
        my $subject = $c->param('subject');
        my $body = $c->param('body');

        my @errors;
        if (not length($email)) {
            push @errors, "Email is required.";
        } elsif ($email !~ qr/^\S+@\S+\.\S+$/) {
            push @errors, "Email is invalid.";
        }
        if (not length($subject)) {
            push @errors, "Subject is required.";
        }
        if (not length($body)) {
            push @errors, "Body is required.";
        }

        $c->recaptcha;
        push @errors, $c->stash('recaptcha_error') if $c->stash('recaptcha_error');

        if (@errors) {
            $c->stash('errors' => \@errors);
            return;
        }

        # sendmail
        sendmail( {
            to => $c->sconfig->{email}->{default_to},
            subject => $subject,
            body => $body,
            ($email) ? (extra_headers => "Reply-To: $email") : ()
        } );

        $c->flash('message' => "Request sent, we'll get back to you asap.");
        return $c->redirect_to('/');
    }

}

sub html {
    my $c = shift;
    my $html = $c->stash('html') || $c->stash('html.html');
    if ($html !~ /\./ and -e FindmJob::Basic->root . "/templates/help/" . $html . ".html.tt") {
        $c->render(template => 'help/' . $html);
    }
}

1;