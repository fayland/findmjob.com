package FindmJob::Scrape::Role::TextFormatter;

use Moose::Role;
use HTML::FormatText;

has 'formatter' => (
    is => 'rw',
    lazy_build => 1
);
sub _build_formatter {
    return HTML::FormatText->new(leftmargin => 0, rightmargin => 999);
}

1;