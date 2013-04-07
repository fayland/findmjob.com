package FindmJob::ShareBot::Role;

use Moo::Role;
with 'FindmJob::Role::Basic';
with 'FindmJob::Role::Logger';

has 'stop' => (is => 'rw', default => sub { 0 });
sub should_stop { (shift)->stop } # alias

sub remove_useless_tags {
    my ($self, @tags) = @_;

    # those we added
    my @useless_tags = ('jobs.perl.org', 'odesk', 'elance', 'careerbuilder', 'linkedin', 'github', 'joelonsoftware', 'stackoverflow', 'Other', 'Others', 'freelancer', 'freelance', 'smashingmagazine', 'rubynow');

    my %useless_tags = map { $_ => 1 } @useless_tags;
    @tags = grep { not $useless_tags{$_} } @tags;
    return @tags;
}

1;