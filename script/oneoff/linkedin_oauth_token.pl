#!/usr/bin/perl

use strict;
use warnings;
use FindBin qw/$Bin/;
use lib "$Bin/../../lib";
use WWW::LinkedIn;
use FindmJob::Basic;
use autodie;
use Data::Dumper;

my $config = FindmJob::Basic->config;
my $api = $config->{api}->{linkedin};

my $li = WWW::LinkedIn->new(
  consumer_key    => $api->{key},
  consumer_secret => $api->{secret},
);

my $file = "$Bin/linkedin.token.txt";
if (@ARGV and -e $file) {
    open(my $fh, '<', $file);
    my $line = <$fh>;
    close($fh);
    chomp($line);
    my ($request_token, $request_token_secret) = split(/\|/, $line);
    my $access_token = $li->get_access_token(
        verifier              => shift @ARGV,
        request_token         => $request_token,
        request_token_secret  => $request_token_secret,
    );
    open($fh, '>', $file);
    print $fh join('|', $request_token, $request_token_secret, $access_token->{token}, $access_token->{secret});
    close($fh);
    print Dumper(\$access_token);
} else {
    my $token = $li->get_request_token(
        callback  => "http://findmjob.com/"
    );
    open(my $fh, '>', $file);
    print $fh $token->{token} . '|' . $token->{secret};
    close($fh);
    print $token->{url} . "\n";
}

1;