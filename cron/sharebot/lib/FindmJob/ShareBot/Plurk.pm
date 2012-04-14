package FindmJob::ShareBot::Plurk;

use Moose;
use namespace::autoclean;
use Data::Dumper;
with 'FindmJob::ShareBot::Role';
with 'FindmJob::Role::Shorten';

use Net::Plurk;

has 'plurk' => ( is => 'ro', isa => 'Net::Plurk', lazy_build => 1 );
sub _build_plurk {
    my $self = shift;
    my $config = $self->config;
    my $t = $config->{share}->{Plurk};

    my $p = Net::Plurk->new(
        consumer_key    => $t->{consumer_key},
        consumer_secret => $t->{consumer_secret},
        raw_output => 1,
    );
    $p->authorize(
        access_token => $t->{access_token},
        access_token_secret => $t->{access_token_secret}
    );

    return $p;
}

sub share {
    my ($self, $job) = @_;

    my @tags = @{ $job->tags };
    @tags = map { $_->{text} } @tags;
    @tags = $self->remove_useless_tags(@tags);
    push @tags, 'jobs', 'hiring', 'careers';
    @tags = map { '#' . $_ } @tags;
    my $tags = join(' ', @tags);

    my $config = $self->config;
    my $url = $config->{sites}->{main} . $job->url;
    my $shorten_url = $self->shorten($url);

    my $content = $job->title . ' ' . $shorten_url . ' ' . $tags;
    my $json = $self->plurk->add_plurk($content, 'shares');
    my $st = $json->{plurk_id} ? 1 : 0;
    $self->log_debug("# failed: " . Dumper(\$json)) unless $st;
    $self->log_debug("# plurk $content: $st");

    return $st;
}

__PACKAGE__->meta->make_immutable;

1;