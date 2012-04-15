#!/usr/bin/perl

use strict;
use warnings;
use FindBin qw/$Bin/;
use lib "$Bin/../../lib"; # FindmJob::Basic etc.
use lib "$Bin/../lib";    # FindmJob::Role::
use lib "$Bin/lib";       # FindmJob::Scrape::
use FindmJob::ShareBot;
use Getopt::Long;

my %options;
GetOptions(
    "m|module=s" => \$options{module},
    "n|num=i"    => \$options{num},
    "d|debug=i"  => \$options{debug},
) or die "error parsing opt";

unless ($options{module}) {
    die <<USAGE;
perl $0 [options]
    options:
        -m, --module        running module, eg: Twitter
USAGE
}

FindmJob::ShareBot->new(%options)->run;

1;