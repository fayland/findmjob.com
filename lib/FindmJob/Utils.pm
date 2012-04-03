package FindmJob::Utils;

use strict;
use warnings;
use base 'Exporter';
use vars qw/@EXPORT_OK/;
@EXPORT_OK = qw/uuid seo_title/;

use Data::UUID;

sub uuid {
    my $str = Data::UUID->new->create_b64;
    $str =~ s/\=+$//;
    $str =~ s/\//\_/g; # damn, base64 contains / and it breaks URL
    return $str;
}

sub seo_title {
    my ($title) = @_;

    $title =~ s/[^\w\-]+/\-/g;
    $title =~ s/\-{2,}/\-/g;
    $title =~ s/^\-|\-$//g;

    return $title;
}

1;