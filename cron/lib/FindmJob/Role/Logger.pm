package FindmJob::Role::Logger;

use Moose::Role;
with 'MooseX::Role::Loggable';

has '+debug' => (default => 1);

1;