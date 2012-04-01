package FindmJob::Scrape::Role;

use Moose::Role;
use FindmJob::Basic;

with 'FindmJob::Scrape::Role::UA';
with 'MooseX::Role::Loggable';

has 'opt_update' => ( is => 'ro', isa => 'Bool', default => '0' );

has 'basic' => (
    is => 'ro',
    lazy => 1,
    isa => 'FindmJob::Basic',
    default => sub {
        FindmJob::Basic->instance;
    },
    handles => ['schema', 'config']
);

1;