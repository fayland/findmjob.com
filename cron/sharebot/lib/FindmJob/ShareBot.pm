package FindmJob::ShareBot;

use Moo;
use MooX::Options;
use Class::Load 'load_class';
with 'FindmJob::ShareBot::Role';

option 'module' => (is => 'ro', format => 's', required => sub { 1 }, short => 'm');
option 'num'    => (is => 'ro', format => 'i', default => sub { 12 }, short => 'n');
option 'type'   => (is => 'ro', format => 's', default => sub { 'Job' }, short => 't');

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
        source_url  => { 'NOT LIKE', '%careerbuilder.com%' }, # careerbuilder.com is not that good
    }, {
        order_by => 'RAND()',
        rows => $self->num * 2,
        page => 1
    });

    my $dbh_log = $self->dbh_log;
    my $is_inserted_sth = $dbh_log->prepare("SELECT 1 FROM `findmjob_log`.`sharebot` WHERE id = ? AND site = ?");
    my $insert_sth = $dbh_log->prepare("INSERT INTO `findmjob_log`.`sharebot` (id, site, time) VALUES (?, ?, ?)");

    my $posted_num = 0;
    while (my $job = $job_rw->next) {
        $posted_num++;
        last if $posted_num > $self->num;

        foreach my $plugin ( @plugins ) {
            next if $plugin->should_stop; # stop
            my $pkg = ref $plugin; $pkg =~ s{FindmJob::ShareBot::}{};

            # check if we did it
            $is_inserted_sth->execute($job->id, $pkg);
            my ($is_inserted) = $is_inserted_sth->fetchrow_array;
            next if $is_inserted;

            $self->log_debug("# on " . $job->id . " with $pkg");
            my $st = $plugin->share($job);

            $insert_sth->execute($job->id, $pkg, time()) if $st;
        }
        sleep 10;
    }
}

1;