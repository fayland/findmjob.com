#!/usr/bin/perl

use strict;
use warnings;
use FindBin qw/$Bin/;
use lib "$Bin/../../lib"; # FindmJob::Basic
use FindmJob::Basic;
use Data::Dumper;
use Digest::MD5 'md5_hex';
use Template;
use FindmJob::Email 'sendmail';

my $root    = FindmJob::Basic->root;
my $config  = FindmJob::Basic->config;
my $dbh     = FindmJob::Basic->dbh;

my $tt = Template->new(
    INCLUDE_PATH => "$root/templates/emails",
    PRE_CHOMP    => 0,
    POST_CHOMP   => 0,
);

my $mark_as_sent_sth = $dbh->prepare("UPDATE subscriber SET last_sent=? WHERE id = ?");

my $sql = "SELECT * FROM subscriber WHERE last_sent=0 AND is_active=0";
my $sth = $dbh->prepare($sql);
$sth->execute();
while (my $r = $sth->fetchrow_hashref) {
    print "on $r->{id} / $r->{email}\n";

    my $to = delete $r->{email};
    $r->{sec_hash} = md5_hex($r->{id} . $config->{secret_hash});

    my $html;
    $tt->process("subscribe_confirm.html", $r, \$html)
        || die $tt->error(), "\n";

    sendmail( {
    	to => $to,
    	subject => "[FindmJob.com] Confirmation on subscription",
    	html_body => $html
    } );

    $mark_as_sent_sth->execute(time(), $r->{id});
}

1;