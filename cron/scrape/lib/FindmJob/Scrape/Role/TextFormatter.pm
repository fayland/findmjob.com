package FindmJob::Scrape::Role::TextFormatter;

use Moose::Role;
use FindmJob::HTML::FormatText;

has 'formatter' => (
    is => 'rw',
    lazy_build => 1
);
sub _build_formatter {
    return FindmJob::HTML::FormatText->new(leftmargin => 0, rightmargin => 999);
}

1;