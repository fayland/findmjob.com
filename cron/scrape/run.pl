#!/usr/bin/perl

use strict;
use warnings;
use FindBin qw/$Bin/;
use lib "$Bin/../../lib";
use lib "$Bin/lib";
use Getopt::Long;
use Class::Load 'load_class';

my $m;
GetOptions(
    "m|module=s" => \$m,
) or die "error parsing opt";

unless ($m) {
    die <<USAGE;
perl $0 [options]
    options:
        -m, --module        running module, eg: JobsPerlOrg
USAGE
}

my $module = "FindmJob::Scrape::$m";
load_class($module) or die "Failed to load $module\n";

$module->new()->run;

1;