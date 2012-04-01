#!/usr/bin/env perl

use FindBin qw/$Bin/;
use lib "$Bin/../lib";
use lib "$Bin/../../lib";
use lib '/findmjob.com/lib';
use lib '/findmjob.com/www/lib';
use Dancer;
use FindmJob::WWW;

dance;
