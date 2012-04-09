package FindmJob::ShareBot;

use Moose;
use Module::Pluggable::Object;
with 'FindmJob::ShareBot::Role';

sub run {
    my ($self) = @_;

    my @plugins = Module::Pluggable::Object->new(
        instantiate => 'new',
        search_path => 'FindmJob::ShareBot',
        except => ['FindmJob::ShareBot::Role'],
    )->plugins;

    # random so that every job have the chance
    my $job_rs = $self->schema->resultset('Job')->search( {
        inserted_at => { '>', time() - 7 * 86440 }, # today
    }, {
        order_by => 'RAND()',
        rows => 12,
        page => 1
    });

    my $dbh_log = $self->basic->dbh_log;
    my $is_inserted_sth = $dbh_log->prepare("SELECT 1 FROM `findmjob_log`.`sharebot` WHERE id = ? AND site = ?");
    my $insert_sth = $dbh_log->prepare("INSERT INTO `findmjob_log`.`sharebot` (id, site, time) VALUES (?, ?, ?)");

    while (my $job = $job_rs->next) {
        foreach my $plugin ( @plugins ) {
            # check if we did it
            my $pkg = ref $plugin; $pkg =~ s{FindmJob::ShareBot::}{};
            $is_inserted_sth->execute($job->id, $pkg);
            my ($is_inserted) = $is_inserted_sth->fetchrow_array;
            next if $is_inserted;

            print "working on " . $job->id . "\n";
            # $plugin->share($job);

            $insert_sth->execute($job->id, $pkg, time());

            sleep 2;
        }
        sleep 10;
    }
}

1;