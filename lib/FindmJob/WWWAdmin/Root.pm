package FindmJob::WWWAdmin::Root;

use Mojo::Base 'Mojolicious::Controller';

sub index {
    my $self = shift;

    $self->render(text => 'Works!');
}

1;