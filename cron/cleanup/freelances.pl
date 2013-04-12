#!/usr/bin/perl

use strict;
use warnings;
use FindBin qw/$Bin/;
use lib "$Bin/../../lib"; # FindmJob::Basic
use FindmJob::Basic;
use Data::Dumper;

## remove old freelances which is older than one months

my $dbh = FindmJob::Basic->dbh;

my $month_ago = time() - 40 * 86400;
my $rows = $dbh->do("DELETE FROM freelance WHERE inserted_at < $month_ago");
print "DELETE freelance: $rows\n";

$rows = $dbh->do("DELETE FROM object where tbl='freelance' and id not in (SELECT id FROM freelance)");
print "DELETE object: $rows\n";

$rows = $dbh->do("DELETE FROM object_tag where object not in (SELECT id FROM object)");
print "DELETE object_tag: $rows\n";

print "Done\n";

1;