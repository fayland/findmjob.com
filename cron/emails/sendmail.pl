#!/usr/bin/perl

use strict;
use warnings;
use FindBin qw/$Bin/;

BEGIN {
	use Proc::PID::File;
	exit if Proc::PID::File->running( { dir => $Bin } );
};

use lib "$Bin/../../lib";
use FindmJob::Basic;
use MIME::Lite;
use HTML::FormatText;
use HTML::TreeBuilder;

my $config = FindmJob::Basic->config;
my $schema = FindmJob::Basic->schema;
my $dbh = $schema->storage->dbh;

my $formatter = HTML::FormatText->new(leftmargin => 0, rightmargin => 520);

my $sth = $dbh->prepare("SELECT * FROM emails");
$sth->execute();
while (my $e = $sth->fetchrow_hashref) {
	print "# sending $e->{subject} to $e->{to}\n";

	my $msg = MIME::Lite->new(
        From    => $e->{from} || $config->{email}->{default_from},
        To      => $e->{to},
	    Subject => $e->{subject},
        Type    => 'multipart/mixed'
    );
    if ($e->{body}) {
        $msg->attach(
            Type => 'TEXT',
            Data => $e->{body}
        );
    }
    if ($e->{html_body}) {
        unless ($e->{body}) {
            my $tree = HTML::TreeBuilder->new_from_content($e->{html_body});
            my $text = $formatter->format($tree);
            $tree = $tree->delete;
            $msg->attach(
                Type => 'TEXT',
                Data => $text
            );
        }

        $msg->attach(
            Type => 'text/html',
            Data => $e->{html_body}
        );
    }

	if ($e->{extra_headers}) {
        my @parts = split("\r\n", $e->{extra_headers});
        foreach my $p (@parts) {
            next unless $p;
            my @p = split(/\:\s*/, $p, 2);
            if (lc($p[0]) eq 'content-type') {
                $msg->attr('content-type', $p[1]);
            } else {
                $msg->add(@p);
            }
        }
    }

    # MIME::Lite->send("sendmail", "/usr/sbin/sendmail");
	$msg->send() or die "[ERROR][Email] Error sending email: $!\n";

	$dbh->do("INSERT IGNORE INTO emails_sent SELECT * FROM emails WHERE id = ?", undef, $e->{id});
	$dbh->do("DELETE FROM emails WHERE id = ?", undef, $e->{id});
}

1;