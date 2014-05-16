#!/usr/bin/perl

use strict;
use warnings;
use FindBin qw/$Bin/;
use lib "$Bin/../../lib"; # FindmJob::Basic
use FindmJob::Basic;
use Data::Dumper;

my $es = FindmJob::Basic->elasticsearch;
my $schema = FindmJob::Basic->schema;
my $dbh = FindmJob::Basic->dbh;

my $bulk = $es->bulk_helper(
    index   => 'findmjob',
    type    => 'job',
    # verbose => 1
);

my $prev_time = $schema->resultset('Option')->get('last_es_time_job');
die unless $prev_time; # call fullindex instead

my @rows;
my $sth = $dbh->prepare("SELECT id, title, description, location, contact, inserted_at FROM job WHERE inserted_at > $prev_time");
$sth->execute();
while (my $row = $sth->fetchrow_hashref) {
    my $id = delete $row->{id};
    push @rows, { id => $id, source => $row };
}
$bulk->create_docs(@rows);
$bulk->flush;

$schema->resultset('Option')->set('last_es_time_job', time());

$bulk = $es->bulk_helper(
    index   => 'findmjob',
    type    => 'freelance',
    # verbose => 1
);

$prev_time = $schema->resultset('Option')->get('last_es_time_freelance');
die unless $prev_time; # call fullindex instead

@rows = ();
$sth = $dbh->prepare("SELECT id, title, description, 'Anywhere' as location, contact, inserted_at FROM freelance WHERE inserted_at > $prev_time");
$sth->execute();
while (my $row = $sth->fetchrow_hashref) {
    my $id = delete $row->{id};
    push @rows, { id => $id, source => $row };
}
$bulk->create_docs(@rows);
$bulk->flush;

$schema->resultset('Option')->set('last_es_time_freelance', time());

1;