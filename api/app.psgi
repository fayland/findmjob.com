#!/usr/bin/perl

use strict;
use warnings;

use Plack::Request;
use Plack::Response;
use Web::Machine::FSM;

use FindBin qw/$Bin/;
use lib "$Bin/lib";     # FindmJob::Resource
use lib "$Bin/../lib";  # FindmJob::Basic
use FindmJob::Resource;

sub {
    Web::Machine::FSM->new->run(
        FindmJob::Resource->new(
            request  => Plack::Request->new( shift ),
            response => Plack::Response->new,
        )
    )->finalize;
};