package FindmJob::ShareBot::GiveaLink;

use Moose;
use namespace::autoclean;
with 'FindmJob::ShareBot::Role';

use LWP::Authen::OAuth;

has 'ua' => ( is => 'ro', isa => 'LWP::Authen::OAuth', lazy_build => 1 );
sub _build_ua {
    my $self = shift;
    my $config = $self->config;
    my $t = $config->{share}->{givealink};

    my $file = $self->basic->root . "/script/oneoff/givealink.token.txt";
    open(my $fh, '<', $file) or die "Can't open $file: $!";
    my $line = <$fh>; chomp($line);
    close($fh);

    my ($oauth_token, $oauth_token_secret) = split(/\,/, $line);

    return LWP::Authen::OAuth->new(
        oauth_consumer_key => $t->{key},
        oauth_consumer_secret => $t->{secret},
        oauth_token => $oauth_token,
        oauth_token_secret => $oauth_token_secret,
    );
}

sub share {
    my ($self, $job) = @_;

    my @tags = @{ $job->tags };
    @tags = map { $_->{text} } @tags;
    @tags = $self->remove_useless_tags(@tags);
    push @tags, 'findmjob', 'job';

    my $config = $self->config;
    my $resp = $self->ua->post("http://givealink.org/api/2.0/", [
        method => 'Annotation.add',
        user   => 'findmjob.com@gmail.com',
        api_key => $config->{share}->{givealink}->{key},
        url => $config->{sites}->{main} . $job->url,
        tag => join(', ', @tags),
        title => $job->title,
        desc => substr($job->description, 0, 255) . '...',
    ]);
    my $st = $resp->decoded_content =~ /status\=\"ok\"/ ? 1 : 0;
    $self->log_debug("# GiveaLink added " . $job->url . " $st");

    return $st;
}

__PACKAGE__->meta->make_immutable;

1;