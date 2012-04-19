package FindmJob::Email;

use strict;
use warnings;
use base 'Exporter';
use vars qw/@EXPORT_OK/;
@EXPORT_OK = qw/sendmail/;

use MIME::Lite;

sub sendmail {
    my ($from, $to, $subject, $body) = @_;

    my $msg = MIME::Lite->new(
        From    => $from,
        To      => $to,
        Subject => $subject,
        Type    => 'TEXT',
        Data    => $body
    );

    $msg->send; # send via default
}

1;