package FindmJob::Role::Logger;

use Moose::Role;
use namespace::autoclean;

with 'MooseX::Role::Loggable';

has 'debug' => (is => 'rw', isa => 'Bool', default => 1);
has 'log_to_stdout' => (is => 'ro', isa => 'Bool', default => 1);
has 'log_to_stderr' => (is => 'ro', isa => 'Bool', default => 0);
has 'logger_facility' => (is => 'ro', isa => 'Str', default => 'none');
has 'logger_ident' => (is => 'ro', isa => 'Str', default => sub { 'findmjob' });
has 'log_to_file' => (is => 'ro', isa => 'Bool', default => 1);
has 'log_path' => (is => 'ro', isa => 'Str', predicate => 'has_log_path', default => '/tmp');

1;