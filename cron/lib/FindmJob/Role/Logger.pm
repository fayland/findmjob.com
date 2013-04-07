package FindmJob::Role::Logger;

use Moo::Role;
use Log::Dispatchouli;
use File::Path 'make_path';
use FindBin qw/$RealBin $RealScript/;

requires 'root';

has logger => (
    is      => 'lazy',
    handles => [ qw/
        log log_fatal log_debug info debug fatal
        set_debug clear_debug set_prefix clear_prefix set_muted clear_muted
    / ],
);
sub _build_logger {
    my $self     = shift;

    my $ident = 'findmjob';

    my $log_file = sprintf('%04u%02u%02u', ((localtime)[5] + 1900),
        sprintf('%02d', (localtime)[4] + 1),
        sprintf('%02d', (localtime)[3]),
    ) . '.log';

    my $logger = Log::Dispatchouli->new( {
        debug       => 1,
        ident       => $ident,
        facility    => '',
        to_file     => 1,
        to_stdout   => 1,
        to_stderr   => 0,
        log_pid     => 1,
        fail_fatal  => 1,
        muted       => 0,
        log_path    => '/tmp',
        log_file    => $log_file,
    } );

    return $logger;
}

1;