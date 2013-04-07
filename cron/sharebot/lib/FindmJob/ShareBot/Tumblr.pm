package FindmJob::ShareBot::Tumblr;

use Moo;
use Data::Dumper;
with 'FindmJob::ShareBot::Role';

use WebService::Tumblr;

has 'tumblr' => ( is => 'lazy' );
sub _build_tumblr {
    my $self = shift;
    my $t = $self->config->{share}->{Tumblr};
    my $p = WebService::Tumblr->new(%$t);
    return $p;
}

sub share {
    my ($self, $job) = @_;

    my @tags = @{ $job->tags };
    @tags = map { $_->{text} } @tags;
    @tags = $self->remove_useless_tags(@tags);
    push @tags, 'jobs', 'hiring', 'careers';
    my $tags = join(', ', @tags);

    my $config = $self->config;
    my $url = $config->{sites}->{main} . $job->url;

    # Make a post
    my $dispatch = $self->tumblr->write(
       type => 'link',
       private => 0,
       tags => $tags,
       url  => $url,
       name => $job->title,
       source_url => $url,
    );
    my $st = 0;
    if ( $dispatch->is_success ) {
        $st = 1;
        my $post_id = $dispatch->content; # Shortcut for $dispatch->response->decoded_content;
        $self->log_debug("# tumblr $post_id: 1");
    } else {
        $self->log_debug("# failed: " . Dumper(\$dispatch->response));
    }

    return $st;
}

1;