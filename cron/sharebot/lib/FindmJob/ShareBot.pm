package FindmJob::ShareBot;

use Moose;
use Module::Pluggable::Object;

sub run {
    my ($self) = @_;

    my @plugins = Module::Pluggable::Object->new(
        instantiate => 'new',
        search_path => 'FindmJob::ShareBot',
        except => ['FindmJob::ShareBot::Role'],
    )->plugins;

    # get random job?
    foreach my $plugin ( @plugins ) {
        $plugin->share({ id => 'x' });
    }
}

1;