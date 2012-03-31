#!/usr/bin/perl

use strict;
use warnings;
use FindBin qw/$Bin/;
use lib "$Bin/../lib";
use FindmJob::Basic;
use DBIx::Class::Schema::Loader qw/ make_schema_at /;

my $dbi_config = FindmJob::Basic->config->{DBI};
make_schema_at(
    'FindmJob::Schema',
    {   debug => 1,
        dump_directory => "$Bin/../lib",
    },
    [   @$dbi_config[0 .. 2],
        {
            loader_options => {
                use_mosse => 1,
                naming => 'current',
            },
        }
    ]
);