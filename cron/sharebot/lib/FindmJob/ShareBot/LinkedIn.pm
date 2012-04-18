package FindmJob::ShareBot::LinkedIn;

use Moose;
use namespace::autoclean;
with 'FindmJob::ShareBot::Role';

use LWP::Authen::OAuth;
use HTML::Entities;

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
    $title = decode_entities($title);
    my $update = "$title $shorten_url $tags";

    my $xml = <<'XML';
<?xml version="1.0" encoding="UTF-8"?>
<share>
  <comment>$update</comment>
  <content>
	 <title>$title</title>
	 <submitted-url>$url</submitted-url>
  </content>
  <visibility>
	 <code>anyone</code>
  </visibility>
</share>
XML

    my $resp = $self->ua->post("http://api.linkedin.com/v1/people/~/shares", Content => $xml);
    my $st = $resp->code == 201 ? 1 : 0;
    $self->log_debug("# Linkedin added " . $job->url . " $st");

    return $st;
}

__PACKAGE__->meta->make_immutable;

1;