package FindmJob::Role::Basic;

use Moose::Role;

use FindmJob::Basic;
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