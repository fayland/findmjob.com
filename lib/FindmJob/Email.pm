package FindmJob::Email;

use strict;
use warnings;
use base 'Exporter';
use vars qw/@EXPORT_OK/;
@EXPORT_OK = qw/sendmail/;

use FindmJob::Basic;

sub sendmail {
	my ($from, $to, $subject, $body, $html_body, $extra_headers);
	if (scalar(@_) > 1) {
		print scalar(@_) . "\n";
		($from, $to, $subject, $body) = @_;
	} else {
		my %d = %{(shift)};
		($from, $to, $subject, $body, $html_body, $extra_headers) = @d{qw/from to subject body html_body extra_headers/};
	}

    my $dbh = FindmJob::Basic->dbh;
    $dbh->do("INSERT INTO emails (`from`, `to`, `subject`, `body`, `html_body`, `extra_headers`) VALUES (?, ?, ?, ?, ?, ?)", undef,
    	$from, $to, $subject, $body, $html_body, $extra_headers);
}

1;