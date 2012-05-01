package FindmJob::ShareBot;

use Moose;
use namespace::autoclean;
use Class::Load 'load_class';
with 'FindmJob::ShareBot::Role';
with 'MooseX::Getopt::Strict';

has 'module' => (is => 'ro', isa => 'Str', required => 1, traits => [ 'Getopt' ], cmd_aliases => 'm');
has 'num'    => (is => 'ro', isa => 'Int', default => 12, traits => [ 'Getopt' ], cmd_aliases => 'n');
has 'debug'  => (is => 'ro', isa => 'Bool', default => 0, traits => [ 'Getopt' ], cmd_aliases => 'd');
has 'type'   => (is => 'ro', isa => 'Str', default => 'Job', traits => [ 'Getopt' ], cmd_aliases => 't');

sub run {
    my ($self) = @_;

    my @plugins;
    my @modules = split(/\,/, $self->module);
    foreach my $m (@modules) {
        my $module = "FindmJob::ShareBot::$m";
        load_class($module) or die "Failed to load $module\n";
        push @plugins, $module->new;
    }

    # random so that every job have the chance
    my $job_rs = $self->schema->resultset( $self->type );
    my $job_rw = $job_rs->search( {
        inserted_at => { '>', time() - 86440 }, # today
    }, {
        order_by => 'RAND()',
        rows => $self->num * 2,
        page => 1
    });

    my $dbh_log = $self->basic->dbh_log;
    my $is_inserted_sth = $dbh_log->prepare("SELECT 1 FROM `findmjob_log`.`sharebot` WHERE id = ? AND site = ?");
    my $insert_sth = $dbh_log->prepare("INSERT INTO `findmjob_log`.`sharebot` (id, site, time) VALUES (?, ?, ?)");

    my $posted_num = 0;
    while (my $job = $job_rw->next) {
        $posted_num++;
        last if $posted_num > $self->num;

        foreach my $plugin ( @plugins ) {
            my $pkg = ref $plugin; $pkg =~ s{FindmJob::ShareBot::}{};

            # check if we did it
            $is_inserted_sth->execute($job->id, $pkg);
            my ($is_inserted) = $is_inserted_sth->fetchrow_array;
            next if $is_inserted;

            $self->log_debug("# on " . $job->id . " with $pkg");
            my $st = $plugin->share($job);

            $insert_sth->execute($job->id, $pkg, time()) if $st;
        }
        last if $self->debug; # debug means test one job
        sleep 10;
    }
}

__PACKAGE__->meta->make_immutable;

1;