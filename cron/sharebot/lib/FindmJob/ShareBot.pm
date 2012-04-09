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

    # get latest 10 jobs? or better what?
    my $job_rs = $self->schema->resultset('Job')->search( undef, {
        order_by => 'inserted_at DESC',
        rows => 12,
        page => 1
    });
    while (my $job = $job_rs->next) {
        foreach my $plugin ( @plugins ) {
            $plugin->share($job);
            sleep 2;
        }
        sleep 10;
    }
}

1;