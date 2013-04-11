#!/usr/bin/perl

use strict;
use warnings;
use FindBin qw/$Bin/;
use lib "$Bin/../../lib"; # FindmJob::Basic
use FindmJob::Basic;
use Data::Dumper;

my $dbh = FindmJob::Basic->dbh;

my $update_sth = $dbh->prepare("UPDATE location SET job_num = ? WHERE id = ?");

my $one_week = time() - 7 * 86400;
my $sth = $dbh->prepare("SELECT location_id, COUNT(*) FROM job WHERE inserted_at > $one_week GROUP BY location");
$sth->execute();
while (my ($id, $cnt) = $sth->fetchrow_array) {
    $update_sth->execute($cnt, $id);
}

print "Done\n";

1;