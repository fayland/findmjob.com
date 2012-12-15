package FindmJob::ShareBot::LinkedIn;

use Moose;
use namespace::autoclean;
with 'FindmJob::ShareBot::Role';
with 'FindmJob::Role::Shorten';

use LWP::Authen::OAuth;
use JSON::XS;

has 'ua' => ( is => 'ro', isa => 'LWP::Authen::OAuth', lazy_build => 1 );
sub _build_ua {
    my $self = shift;
    my $config = $self->config;
    my $t = $config->{api}->{linkedin};

    my $root = $self->basic->root;
    my $file = $root . "/script/oneoff/linkedin.token.txt";
    open(my $fh, '<', $file) or die "Can't get $file";
    my $line = <$fh>;
    close($fh);
    chomp($line);
    my ($_x, $_x2, $token, $secret) = split(/\|/, $line);

    my ($oauth_token, $oauth_token_secret) = split(/\,/, $line);

    return LWP::Authen::OAuth->new(
        oauth_consumer_key => $t->{key},
        oauth_consumer_secret => $t->{secret},
        oauth_token => $token,
        oauth_token_secret => $secret,
    );
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

    my $json = encode_json({
        comment => $update,
        content => {
            title => $title,
            'submitted-url' => $url,
        },
        visibility => {
            code => 'anyone'
        }
    });

    my $resp = $self->ua->post("http://api.linkedin.com/v1/people/~/shares", 'Content-Type' => 'application/json', Content => $json);
    my $st = $resp->code == 201 ? 1 : 0;
    $self->log_debug("# failed to add linkedin share: " . $resp->content) unless $st;
    $self->log_debug("# Linkedin added " . $job->url . " $st");

    $self->stop(1) if $resp->content =~ /Throttle limit for calls to this resource is reached/i;

    return $st;
}

__PACKAGE__->meta->make_immutable;

1;