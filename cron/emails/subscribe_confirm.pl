#!/usr/bin/perl

use strict;
use warnings;
use FindBin qw/$Bin/;
use lib "$Bin/../../lib"; # FindmJob::Basic
use FindmJob::Basic;
use FindmJob::Utils 'uuid';
use Data::Dumper;
use JSON::XS;

my $config  = FindmJob::Basic->config;
my $dbh     = FindmJob::Basic->dbh;
my $dbh_log = FindmJob::Basic->dbh_log;

my $insert_email_sth = $dbh_log->prepare("INSERT INTO findmjob_log.email (id, `to`, `data`, `status`) VALUES (?, ?, ?, 0)");
my $mark_as_sent_sth = $dbh->prepare("UPDATE subscriber SET last_sent=? WHERE email = ? AND keyword = ?");

my $sql = "SELECT * FROM subscriber WHERE last_sent=0 AND is_active=0";
my $sth = $dbh->prepare($sql);
$sth->execute();
while (my $r = $sth->fetchrow_hashref) {
    print "on $r->{email} / $r->{keyword}\n";
    $r->{template} = 'subscribe_confirm';
    my $id = uuid();
    my $to = delete $r->{email};
    $r->{subject} = "[FindmJob.com] Confirmation on subscription";
    $insert_email_sth->execute($id, $to, encode_json($r)) or die $dbh->errstr;
    $mark_as_sent_sth->execute(time(), $to, $r->{keyword});
}

1;