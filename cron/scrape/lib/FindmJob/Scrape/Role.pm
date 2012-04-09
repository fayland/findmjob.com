package FindmJob::Scrape::Role;

use Moose::Role;

with 'FindmJob::Role::Basic';
with 'FindmJob::Role::UA';
with 'FindmJob::Role::TextFormatter';
with 'FindmJob::Role::Logger';

has 'opt_update' => ( is => 'ro', isa => 'Bool', default => '0' );

1;