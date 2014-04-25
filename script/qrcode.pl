#!/usr/bin/env perl

use strict;
use warnings;
use HTML::QRCode;

my $text = 'http://static.findmjob.com/FindmJob.apk';
print HTML::QRCode->new->plot($text);

1;