package FindmJob::ShareBot::Delicious;

use Moose;
use Net::Delicious;

sub share {
    my ($self, $job) = @_;

    print $job->{id};
}

1;