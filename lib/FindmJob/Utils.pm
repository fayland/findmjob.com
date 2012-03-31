package FindmJob::Utils;

use strict;
use warnings;
use base 'Exporter';
use vars qw/@EXPORT_OK/;
@EXPORT_OK = qw/uuid/;

use Data::UUID;

sub uuid {
    my $str = Data::UUID->new->create_b64;
    $str =~ s/\=+$//;
    return $str;
}

1;