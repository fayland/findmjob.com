package FindmJob::Role::TextFormatter;

use Moose::Role;
use FindmJob::HTML::FormatText;
use HTML::TreeBuilder;

has 'formatter' => (
    is => 'rw',
    lazy_build => 1
);

sub _build_formatter {
    return FindmJob::HTML::FormatText->new(leftmargin => 0, rightmargin => 999);
}

sub format_tree_text {
    my ($self, $ele) = @_;

    my $txt = $self->formatter->format($ele);

    my $x100 = '-' x 100;
    $txt =~ s/\-{80,}/$x100/sg;
    $txt =~ s/^\s+|\s+$//g;
    $txt =~ s/\n{3,}/\n\n/g;
    $txt =~ s/\xA0/ /g;

    return $txt;
}

sub format_text {
    my ($self, $text) = @_;

    my $tree = HTML::TreeBuilder->new_from_content($text);
    my $txt  = $self->format_tree_text($tree);
    $tree = $tree->delete;

    return $txt;
}

1;