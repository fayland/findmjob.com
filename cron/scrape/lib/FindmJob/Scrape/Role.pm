package FindmJob::Scrape::Role;

use Moose::Role;
use FindmJob::Basic;

with 'FindmJob::Role::UA';
with 'FindmJob::Role::TextFormatter';
with 'MooseX::Role::Loggable';

has 'opt_update' => ( is => 'ro', isa => 'Bool', default => '0' );

has 'basic' => (
    is => 'ro',
    lazy => 1,
    isa => 'FindmJob::Basic',
    default => sub {
        FindmJob::Basic->instance;
    },
    handles => ['schema', 'config', 'root']
);

1;