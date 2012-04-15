#!/usr/bin/perl

use strict;
use warnings;
use FindBin qw/$Bin/;
use lib "$Bin/../../lib";
use FindmJob::Basic;
use autodie;
use Data::Dumper;
use LWP::Authen::OAuth;

my $config = FindmJob::Basic->config;
my $api = $config->{share}->{givealink};

my $ua = LWP::Authen::OAuth->new(
    oauth_consumer_key => $api->{key},
    oauth_consumer_secret => $api->{secret},
);

my $file = "$Bin/givealink.token.txt";

my $r = $ua->post('http://givealink.org/oauth/request_token', [
    oauth_callback => 'http://findmjob.com/',
]);
die $r->as_string if $r->is_error;
my ($oauth_token) = ($r->decoded_content =~ /oauth_token=([^\&]+)/);
print Dumper(\$r);
print "http://givealink.org/oauth/authorize?oauth_token=" . $oauth_token . "\n";

$ua->oauth_update_from_response( $r );

print "Type the oauth_verifier:\n";
my $x = <STDIN>;
chomp($x);

$r = $ua->post('http://givealink.org/oauth/access_token', [
    oauth_verifier => $x
]);

print Dumper(\$r);

($oauth_token) = ($r->decoded_content =~ /oauth_token=(.*?)(\&|$)/);
my ($oauth_token_secret) = ($r->decoded_content =~ /oauth_token_secret=(.*?)(\&|$)/);

open(my $fh, '>', $file);
print $fh join(',', $oauth_token, $oauth_token_secret);
close($fh);

1;