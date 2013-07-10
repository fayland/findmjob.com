#!/usr/bin/perl

use strict;
use warnings;
use FindBin qw/$Bin/;
use lib "$Bin/../../lib";
use FindmJob::Basic;
use autodie;
use Data::Dumper;
use Facebook::Graph;

my $config = FindmJob::Basic->config;
my $t = $config->{share}->{Facebook};
my $fb = Facebook::Graph->new(
    app_id   => $t->{app_id},
    secret   => $t->{secret},
    postback => 'http://fb.findmjob.com/'
);

my $file = "$Bin/facebook.token.txt";
if (@ARGV) {
    $fb->request_access_token(shift @ARGV);
    open(my $fh, '>', "$Bin/facebook.token.txt");
    print $fh $fb->access_token . ',' . time();
    close($fh);
} else {
    my $uri = $fb
        ->authorize
        ->extend_permissions(qw(offline_access publish_stream))
        ->uri_as_string;
    print $uri . "\n";
}

1;