package FindmJob::DateUtils;

use strict;
use warnings;
use base 'Exporter';
use vars qw/@EXPORT_OK/;
@EXPORT_OK = qw/human_to_db_date/;

use Date::Manip::Date;

sub human_to_db_date {
    my ($in) = @_;
    my $date = Date::Manip::Date->new;
    $date->parse($in);
    return $date->printf('%Y-%m-%d');
}

1;