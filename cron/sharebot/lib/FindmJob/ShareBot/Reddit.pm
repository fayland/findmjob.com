package FindmJob::ShareBot::Reddit;

use Moose;
use namespace::autoclean;
with 'FindmJob::ShareBot::Role';

use Reddit::Client;

has 'reddit' => ( is => 'ro', isa => 'Reddit::Client', lazy_build => 1 );
sub _build_reddit {
    my $self = shift;
    my $config = $self->config;
    my $t = $config->{share}->{Reddit};
    my $session_file = '/tmp/.reddit';
    my $reddit = Reddit::Client->new(session_file => $session_file);
    unless ($reddit->is_logged_in) {
        $reddit->login($t->{u}, $t->{p});
        $reddit->save_session();
    }
    return $reddit;
}

sub share {
    my ($self, $job) = @_;

    my $config = $self->config;
    my @subreddit = ('jobs');

    # Error(s): [BAD_CAPTCHA] care to try these again? at /findmjob.com/cron/sharebot/lib/FindmJob/ShareBot/Reddit.pm line 30
    my $st = $self->reddit->submit_link(
        subreddit => 'jobs',
        title     => $job->title,
        url       => $config->{sites}->{main} . $job->url
    );
    $self->log_debug("# added " . $job->url . " $st");

    return $st;
}

__PACKAGE__->meta->make_immutable;

1;