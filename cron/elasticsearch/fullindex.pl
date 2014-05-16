#!/usr/bin/perl

use strict;
use warnings;
use FindBin qw/$Bin/;
use lib "$Bin/../../lib"; # FindmJob::Basic
use FindmJob::Basic;
use Data::Dumper;

my $es = FindmJob::Basic->elasticsearch;
my $dbh = FindmJob::Basic->dbh;

my $bulk = $es->bulk_helper(
    index   => 'findmjob',
    type    => 'job',
    # verbose => 1
);

$es->indices->delete(index => 'findmjob'); # purge

my @rows;
my $sth = $dbh->prepare("SELECT id, title, description, location, contact, inserted_at FROM job WHERE expired_at > NOW()");
$sth->execute();
while (my $row = $sth->fetchrow_hashref) {
    my $id = delete $row->{id};
    push @rows, { id => $id, source => $row };
}
$bulk->create_docs(@rows);
$bulk->flush;

$bulk = $es->bulk_helper(
    index   => 'findmjob',
    type    => 'freelance',
    # verbose => 1
);
@rows = ();
$sth = $dbh->prepare("SELECT id, title, description, 'Anywhere' as location, contact, inserted_at FROM freelance WHERE expired_at > NOW()");
$sth->execute();
while (my $row = $sth->fetchrow_hashref) {
    my $id = delete $row->{id};
    push @rows, { id => $id, source => $row };
}
$bulk->create_docs(@rows);
$bulk->flush;

1;