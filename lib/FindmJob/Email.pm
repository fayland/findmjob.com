package FindmJob::Email;

use strict;
use warnings;
use base 'Exporter';
use vars qw/@EXPORT_OK/;
@EXPORT_OK = qw/sendmail/;

use FindmJob::Basic;

sub sendmail {
	my ($from, $to, $subject, $body, $html_body);
	if (@_ > 1) {
		($from, $to, $subject, $body) = @_;
	} else {
		my %d = @_;
		($from, $to, $subject, $body, $html_body) = @d{qw/from to subject body html_body/};
	}

    my $dbh = FindmJob->dbh;
    $dbh->do("INSERT INTO emails (`from`, `to`, `subject, `body`, `html_body`) VALUES (?, ?, ?, ?)", undef,
    	$from, $to, $subject, $body, $html_body);
}

1;