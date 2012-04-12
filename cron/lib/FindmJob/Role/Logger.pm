package FindmJob::Role::Logger;

use Moose::Role;
use namespace::autoclean;

with 'MooseX::Role::Loggable';

has 'debug' => (is => 'rw', isa => 'Bool', default => 1);

1;