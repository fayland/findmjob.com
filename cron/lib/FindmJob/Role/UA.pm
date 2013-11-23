package FindmJob::Role::UA;

use Moo::Role;
use MooX::Types::MooseLike::Base qw(:all);
use Module::Runtime 'use_module';

has 'ua_class' => (is => 'rw', isa => Str, default => sub { 'LWP::UserAgent' });
has 'ua_args'  => (is => 'rw', isa => HashRef, default => sub { {
    agent   => 'Mozilla/4.0 (compatible; MSIE 7.0; Windows NT 6.0; Trident/5.0)',
} });
has 'ua' => (
    is => 'lazy',
);
sub _build_ua {
    my $self = shift;
    return use_module($self->ua_class)->new( %{$self->ua_args} );
}

sub get {
    my ($self, $url) = @_;

    my $ua = $self->ua;
    my $max_retries = 5; my $retries = 1;
    $self->log_debug("# get $url");
    my $resp = $ua->get($url);
    while (1) {
        sleep 2 * $retries;
        last if $resp->is_success;
        $self->log_debug("# get $url failed: " . $resp->status_line);
        $retries++;
        last if $retries > $max_retries;
        $resp = $ua->get($url);
    }
    return $resp;
}

1;