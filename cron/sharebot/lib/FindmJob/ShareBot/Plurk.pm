package FindmJob::ShareBot::Twitter;

use Moose;
use namespace::autoclean;
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
    )

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
    # randomly shorten, want to see which one works better?
    my $shorten_url = time() % 2 == 1 ? $self->shorten($url) : $url;

    my $content = $job->title . ' ' . $shorten_url . ' ' . $tags;
    my $resp = $self->plurk->add_plurk($update, 'shares');
    my $st = $resp =~ /plurk_id/ ? 1 : 0;
    $self->log_debug("# failed: $resp") unless $st;
    $self->log_debug("# plurk $content: $st");

    return exists $st ? 1: 0;
}

__PACKAGE__->meta->make_immutable;

1;