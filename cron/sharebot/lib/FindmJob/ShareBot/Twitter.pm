package FindmJob::ShareBot::Twitter;

use Moo;
with 'FindmJob::ShareBot::Role';
with 'FindmJob::Role::Shorten';

use List::Util 'shuffle';
use Net::Twitter::Lite::WithAPIv1_1;

has 'twitter' => ( is => 'lazy' );
sub _build_twitter {
    my $self = shift;
    my $config = $self->config;
    my $t = $config->{share}->{Twitter};

    my $nt = Net::Twitter::Lite::WithAPIv1_1->new(
        consumer_key    => $t->{consumer_key},
        consumer_secret => $t->{consumer_secret},
        access_token        => $t->{access_token},
        access_token_secret => $t->{access_token_secret},
    );

    return $nt;
}

sub share {
    my ($self, $job) = @_;

    my @tags = @{ $job->tags };
    @tags = map { $_->{text} } @tags;
    @tags = $self->remove_useless_tags(@tags);
    @tags = map { s/[\&\#\+\s\.\-\/]+//g; $_ } @tags; # no &, # in tags
    @tags = grep { length($_) and $_ ne 'c' } @tags;
    @tags = shuffle @tags; # shuffle should work better so every tag has the chance
    @tags = splice(@tags, 0, 2);
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

    my $st = eval { $self->twitter->update($update) };
    $self->log_debug( "# Error posting tweet: $@" ) if $@;

    return exists $st->{id} ? 1: 0;
}

1;