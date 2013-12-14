#!/usr/bin/perl

use strict;
use warnings;
use FindBin qw/$Bin/;
use lib "$Bin/../../lib"; # FindmJob::Basic
use FindmJob::Basic;
use Data::Dumper;

my $dbh = FindmJob::Basic->dbh;
my $rows = $dbh->do(<<SQL);
INSERT IGNORE INTO stats_trends SELECT DATE(FROM_UNIXTIME(time)) as dt, tag, COUNT(*) FROM object_tag WHERE tag in (SELECT id FROM tag WHERE category='language' or category='skill' or category='software') AND DATE(FROM_UNIXTIME(time)) >= date(date_sub(now(), interval 2 day)) AND DATE(FROM_UNIXTIME(time)) < date(now()) GROUP BY dt, tag;
SQL

print "$rows Done\n";

1;