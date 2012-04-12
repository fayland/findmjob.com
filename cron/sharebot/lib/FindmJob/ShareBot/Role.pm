package FindmJob::ShareBot::Role;

use Moose::Role;
use namespace::autoclean;
with 'FindmJob::Role::Basic';
with 'FindmJob::Role::Logger';

sub remove_useless_tags {
    my ($self, @tags) = @_;

    # those we added
    my @useless_tags = ('jobs.perl.org', 'odesk', 'elance', 'careerbuilder', 'linkedin', 'github', 'joelonsoftware', 'stackoverflow');

    my %useless_tags = map { $_ => 1 } @useless_tags;
    @tags = grep { not $useless_tags{$_} } @tags;
    return @tags;
}

1;