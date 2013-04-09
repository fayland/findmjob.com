package FindmJob::ShareBot::Facebook;

use Moo;
with 'FindmJob::ShareBot::Role';
with 'FindmJob::Role::Shorten';
with 'FindmJob::Role::UA';

use Facebook::Graph;

has 'facebook' => ( is => 'lazy' );
sub _build_facebook {
    my $self = shift;
    my $config = $self->config;
    my $t = $config->{share}->{Facebook};

    my $fb = Facebook::Graph->new(
        app_id   => $t->{app_id},
        secret   => $t->{secret},
        postback => 'http://fb.findmjob.com/'
    );

    # check the token
    my $file = $self->root . "/script/oneoff/facebook.token.txt";
    open(my $fh, '<', $file) or die "Can't open $file: $!\n";
    my $line = <$fh>; chomp($line);
    close($fh);
    my ($token, $expiry_time) = split(/\,\s*/, $line);
    if ( $expiry_time - time() < 86400 ) {
        # time to exchange and extend the token
        my $url = "https://graph.facebook.com/oauth/access_token?client_id=" . $t->{app_id} . "&client_secret=" . $t->{secret} . "&grant_type=fb_exchange_token&fb_exchange_token=" . $token;
        $self->log_debug("# exchange the token with $url");
        my $resp = $self->ua->get($url);
        if ($resp->decoded_content =~ /access_token\=/) {
            ($token) = ($resp->decoded_content =~ /access_token\=([^\&]+)/);
            my ($expires) = ($resp->decoded_content =~ /expires\=(.*?)(\&|$)/);
            $expiry_time = time() + $expires;
            open(my $fh, '>', $file);
            print $fh $token . ',' . $expiry_time;
            close($fh);
        }
    }

    $fb->access_token($token);

    return $fb;
}

sub share {
    my ($self, $job) = @_;

    my @tags = @{ $job->tags };
    @tags = map { $_->{text} } @tags;
    @tags = $self->remove_useless_tags(@tags);
    @tags = sort { length($a) <=> length($b) } @tags;
    @tags = map { s/\s+//g; $_ } @tags;
    push @tags, 'jobs', 'hiring', 'careers';
    @tags = map { s/[\&\#\+]//g; $_ } @tags; # no &, # in tags
    @tags = grep { $_ ne 'c' } @tags;
    @tags = map { '#' . $_ } @tags;
    my $tags = join(' ', @tags);

    my $config = $self->config;
    my $url = $config->{sites}->{main} . $job->url;
    my $shorten_url = $self->shorten($url);

    my $title = $job->title;
    my $update = "$title $shorten_url $tags";

    my $response = $self->facebook->add_post
        ->set_message($update)
        ->publish;
    # {"id":"100003659837802_120048934793767"}
    my $st = $response->as_string =~ /[\'\"]id[\'\"]\:/ ? 1 : 0;
    $self->log_debug("# facebook set status $update: $st");
    $self->log_debug("# facebook failed: " . $response->as_string) unless $st;

    return $st ? 1: 0;
}

1;