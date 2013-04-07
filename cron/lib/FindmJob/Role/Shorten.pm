package FindmJob::Role::Shorten;

use Moo::Role;
use WWW::Shorten::Bitly;

requires 'config'; # from Role::Basic;

has 'bitly' => ( is => 'lazy' );
sub _build_bitly {
    my $self = shift;
    my $config = $self->config;
    my $t = $config->{share}->{bitly};
    my $bitly = WWW::Shorten::Bitly->new(USER => $t->{uid}, APIKEY => $t->{key});

    # set socks proxy (Tor)
    $bitly->{browser}->proxy('http', $config->{scrape}->{proxy})
        if $config->{scrape}->{proxy};

    return $bitly;
}

sub shorten {
    my ($self, $url) = @_;

    return $self->bitly->shorten(URL => $url);
}

1;