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
    $str =~ s/\//\_/g; # damn, base64 contains / and it breaks URL
    return $str;
}

1;