package FindmJob::Role::Logger;

use Moose::Role;
use namespace::autoclean;

with 'MooseX::Role::Loggable';

has 'debug' => (is => 'rw', isa => 'Bool', default => 1);
has 'log_to_stdout' => (is => 'ro', isa => 'Bool', default => 0);
has 'log_to_stderr' => (is => 'ro', isa => 'Bool', default => 1);

1;