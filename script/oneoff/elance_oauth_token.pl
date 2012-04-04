#!/usr/bin/perl

use strict;
use warnings;
use FindBin qw/$Bin/;
use lib "$Bin/../../lib";
use FindmJob::Basic;
use autodie;
use Data::Dumper;
use LWP::UserAgent;
use JSON::XS 'decode_json';

my $config = FindmJob::Basic->config;
my $api = $config->{api}->{elance};

my $file = "$Bin/elance.token.txt";
if (@ARGV) {
    my $ua = LWP::UserAgent->new(
        default_headers => HTTP::Headers->new(
            'User-Agent' => 'curl/7.24.0 (x86_64-apple-darwin11.3.0) libcurl/7.24.0 OpenSSL/1.0.1 zlib/1.2.6 libidn/1.22',
            Host => 'www.elance.com',
            Accept => '*/*',
            'Content-Type' => 'application/x-www-form-urlencoded',
        )
    );

    my $resp = $ua->post('https://www.elance.com/api2/oauth/token', [
        code => shift @ARGV,
        grant_type => 'authorization_code',
        client_id  => $api->{key},
        client_secret => $api->{secret},
    ]);
    my $d = decode_json($resp->decoded_content);

    print Dumper(\$d);
    exit if $d->{errors};

    $d = $d->{data};
    open(my $fh, '>', $file);
    print $fh join(',', $d->{access_token}, $d->{expires_in}, $d->{token_type}, $d->{refresh_token}, $d->{scope});
    close($fh);
} else {
    print "https://elance.com/api2/oauth/authorize?client_id=$api->{key}&redirect_uri=http://findmjob.com/&response_type=code\n";
}

1;