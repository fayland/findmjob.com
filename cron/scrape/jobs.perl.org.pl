#!/usr/bin/perl

use strict;
use warnings;
use FindBin qw/$Bin/;
use lib "$Bin/../../lib";
use lib "$Bin/lib";
use FindmJob::Basic;

# FIXME
use FindmJob::Scrape::JobsPerlOrg;
FindmJob::Scrape::JobsPerlOrg->new(@ARGV)->run;

1;