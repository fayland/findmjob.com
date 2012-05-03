package FindmJob::Role::Shorten;

use Moose::Role;
use namespace::autoclean;
use WWW::Shorten::Bitly;

requires 'config'; # from Role::Basic;

has 'bitly' => ( is => 'ro', isa => 'WWW::Shorten::Bitly', lazy_build => 1 );
sub _build_bitly {
    my $self = shift;
    my $config = $self->config;
    my $t = $config->{share}->{bitly};
    my $bitly = WWW::Shorten::Bitly->new(USER => $t->{uid}, APIKEY => $t->{key});

    # set socks proxy (Tor)
    $bitly->{browser}->proxy('http', 'socks://127.0.0.1:9050');

    return $bitly;
}

sub shorten {
    my ($self, $url) = @_;

    return $self->bitly->shorten(URL => $url);
}

1;