package FindmJob::Scrape::Role;

use Moose::Role;

with 'FindmJob::Role::Basic';
with 'FindmJob::Role::UA';
with 'FindmJob::Role::TextFormatter';
with 'MooseX::Role::Loggable';

has 'opt_update' => ( is => 'ro', isa => 'Bool', default => '0' );

1;