package FindmJob::ShareBot::Delicious;

use Moose;
with 'FindmJob::ShareBot::Role';

use Net::Delicious;

has 'delicious' => ( is => 'ro', isa => 'Net::Delicious', lazy_build => 1 );
sub _build_delicious {
    my $self = shift;
    my $config = $self->config;
    die Dumper($config->{Delicious}); use Data::Dumper;
    Net::Delicious->new({ user => $config->{Delicious}->{u}, pswd => $config->{Delicious}->{p}, debug => 1 });
}

sub share {
    my ($self, $job) = @_;

    my @tags = @{ $job->tags };
    @tags = map { $_->{text} } @tags;
    return unless @tags;

    my $config = $self->config;
    my $st = $self->delicious->add_post( {
        url => $config->{sites}->{main} . $job->url,
        title => $job->title,
        description => substr($job->description, 0, 255) . '...',
        tags  => join(', ', @tags)
    } );
    $self->log_debug("# added " . $job->url . " $st");

    exit;
}

1;