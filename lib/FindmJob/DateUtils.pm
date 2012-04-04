package FindmJob::DateUtils;

use strict;
use warnings;
use base 'Exporter';
use vars qw/@EXPORT_OK/;
@EXPORT_OK = qw/human_to_db_date human_to_db_datetime/;

use Date::Manip::Date;

sub human_to_db_date {
    my ($in) = @_;
    $in = scalar(gmtime($in)) if $in =~ /^\d+$/;
    my $date = Date::Manip::Date->new;
    $date->parse($in);
    return $date->printf('%Y-%m-%d');
}

sub human_to_db_datetime {
    my ($in) = @_;
    $in = scalar(gmtime($in)) if $in =~ /^\d+$/;
    my $date = Date::Manip::Date->new;
    $date->parse($in);
    return $date->printf('%Y-%m-%d %H:%M:%S');
}

1;