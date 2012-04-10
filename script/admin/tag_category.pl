#!/usr/bin/perl

use strict;
use warnings;
use FindBin qw/$Bin/;
use lib "$Bin/../../lib";
use FindmJob::Basic;

my $dbh = FindmJob::Basic->dbh;

my @language = ('perl', 'python', 'java', 'asp', 'php', 'javascript', 'ruby', 'c#', 'c++', 'lisp', 'actionscript', 'c', 'objective-c', 'visual basic', 'sql', '.net', 'asp.net', 'pascal', 'lua', 'fortran', 'scheme', 'bash', 'haskell', 'smalltalk', 'erlang', 'groovy', 'prolog');
$dbh->do("UPDATE tag SET category='language' WHERE text IN (" . join(', ', split(//, '?' x @language)) . ")", undef, @language);

1;