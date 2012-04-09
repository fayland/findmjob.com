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
    return unless @tags;

    push @tags, 'findmjob', 'job';

    my $config = $self->config;
    my $url = $config->{sites}->{main} . $job->url;
    my $shorten_url = $self->shorten($url);
    print $shorten_url;
    exit;

    my $st = $self->twitter->add_post( {
        url => $config->{sites}->{main} . $job->url,
        title => $job->title,
        description => substr($job->description, 0, 255) . '...',
        tags  => join(', ', @tags)
    } );
    $self->log_debug("# added " . $job->url . " $st");

    return $st;
}

1;