package FindmJob::Utils;

use strict;
use warnings;
use base 'Exporter';
use vars qw/@EXPORT_OK/;
@EXPORT_OK = qw/uuid seo_title rand_string file_get_contents/;

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

sub rand_string {
    my ($len) = @_;

    srand();
    my $str;
    my @p = ('A' .. 'Z', 'a' .. 'z', 0 .. 9);
    foreach (1 .. $len) {
        $str .= $p[rand(scalar @p)];
    }

    return $str;
}

sub file_get_contents {
    my ($file) = @_;

    open(my $fh, '<', $file) or return;
    my $c = do { local $/; <$fh> };
    close($fh);

    return $c;
}

1;