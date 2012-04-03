package FindmJob::HTML::FormatText;

use strict;
use warnings;

use base 'HTML::FormatText';

# part of the code is copied from L<Silki::HTML::FormatText>

sub a_start {
    my $self = shift;
    my $node = shift;

    $self->{a_raw} = $node->as_HTML;
    $node->{_content} = '';

    return 1;
}

sub a_end {
    my $self = shift;
    my $node = shift;

    $self->out($self->{a_raw}) if $self->{a_raw};
    delete $self->{a_raw};

    return 1;
}

sub img_start {
    my ($self, $node) = @_;

    $self->out($node->as_HTML);
    return 1;
}

1;