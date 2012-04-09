package FindmJob::Role::Logger;

use Moose::Role;
with 'MooseX::Role::Loggable';

has 'debug' => (is => 'rw', isa => 'Bool', default => 1);

1;