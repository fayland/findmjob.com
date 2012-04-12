package FindmJob::ShareBot;

use Moose;
use namespace::autoclean;
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
        inserted_at => { '>', time() - 86440 }, # today
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
            my $pkg = ref $plugin; $pkg =~ s{FindmJob::ShareBot::}{};

            # test usage
            # next if $pkg eq 'Twitter';

            # check if we did it
            $is_inserted_sth->execute($job->id, $pkg);
            my ($is_inserted) = $is_inserted_sth->fetchrow_array;
            next if $is_inserted;

            $self->log_debug("# on " . $job->id . " with $pkg");
            my $st = $plugin->share($job);

            $insert_sth->execute($job->id, $pkg, time()) if $st;

            sleep 2;
        }
        sleep 10;
    }
}

__PACKAGE__->meta->make_immutable;

1;