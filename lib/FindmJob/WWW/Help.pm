package FindmJob::WWW::Help;

use Mojo::Base 'Mojolicious::Controller';
use FindmJob::Email 'sendmail';

sub contact {
    my $self = shift;

    if ($self->req->method eq 'POST') {
        my $email = $self->param('email');
        my $subject = $self->param('subject');
        my $body = $self->param('body');

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

        $self->recaptcha;
        push @errors, $self->stash('recaptcha_error') if $self->stash('recaptcha_error');

        if (@errors) {
            $self->stash('errors' => \@errors);
            return;
        }

        # sendmail
        sendmail( {
            to => $self->sconfig->{email}->{default_to},
            subject => $subject,
            body => $body,
            ($email) ? (extra_headers => "Reply-To: $email") : ()
        } );

        $self->flash('message' => "Request sent, we'll get back to you asap.");
        return $self->redirect_to('/');
    }

}


1;