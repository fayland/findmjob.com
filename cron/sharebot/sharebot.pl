#!/usr/bin/perl

use strict;
use warnings;
use FindBin qw/$Bin/;
use lib "$Bin/../../lib"; # FindmJob::Basic etc.
use lib "$Bin/../lib";    # FindmJob::Role::
use lib "$Bin/lib";       # FindmJob::Scrape::
use FindmJob::ShareBot;

FindmJob::ShareBot->new(@ARGV)->run;

1;