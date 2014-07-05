#!/usr/bin/perl

use strict;
use warnings;
use FindBin qw/$Bin/;
use lib "$Bin/../../lib";
use lib "$Bin/../../cron/lib";
use lib "$Bin/../../cron/scrape/lib";
use Moo;
with 'FindmJob::Scrape::Role';

sub run {
    my $self = shift;

    my $schema = $self->schema;
    my $rs = $schema->resultset('Job');
    while (my $r = $rs->next) {
        next unless $r->location;
        next if $r->location_id;
        my $location_id = $schema->resultset('Location')->get_location_id_from_text($r->location);
        $r->update( { location_id => $location_id } );
        print "# update " . $r->title . " with location_id=$location_id (" . $r->location . ")\n";
    }

}

__PACKAGE__->new()->run();

1;