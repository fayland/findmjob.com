package FindmJob::ShareBot::Twitter;

use Moose;
with 'FindmJob::ShareBot::Role';
with 'FindmJob::Role::Shorten';

use Net::Twitter::Lite;

has 'twitter' => ( is => 'ro', isa => 'Net::Twitter::Lite', lazy_build => 1 );
sub _build_twitter {
    my $self = shift;
    my $config = $self->config;
    my $t = $config->{share}->{Twitter};

    my $nt = Net::Twitter::Lite->new(
        consumer_key    => $t->{consumer_key},
        consumer_secret => $t->{consumer_secret},
    );
    $nt->access_token($t->{access_token});
    $nt->access_token_secret($t->{access_token_secret});

    return $nt;
}

sub share {
    my ($self, $job) = @_;

    my @tags = @{ $job->tags };
    @tags = map { $_->{text} } @tags;
    @tags = $self->remove_useless_tags(@tags);
    @tags = sort { length($a) <=> length($b) } @tags;
    @tags = splice(@tags, 0, 2);
    @tags = map { s/\s+//g; $_ } @tags;
    push @tags, 'jobs', 'hiring', 'careers';
    @tags = map { '#' . $_ } @tags;
    my $tags = join(' ', @tags);

    my $config = $self->config;
    my $url = $config->{sites}->{main} . $job->url;
    my $shorten_url = $self->shorten($url);

    my $left_len = 140 - (length($tags) + length($shorten_url) + 2);
    my $title = $job->title;
    $title = substr($title, 0, $left_len - 3) . '...' if length($title) > $left_len;

    my $update = "$title $shorten_url $tags";
    $self->log_debug("# tweet $update");

    my $st;
    try {
        $st = $self->twitter->update($update);
    } catch {
        $st = 0;
        $self->log_fatal( "Error posting tweet: $_" );
    };

    return $st;
}

1;