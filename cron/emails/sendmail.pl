#!/usr/bin/perl

use strict;
use warnings;
use FindBin qw/$Bin/;
use lib "$Bin/../../lib"; # FindmJob::Basic
use FindmJob::Basic;
use Data::Dumper;
use JSON::XS;
use MIME::Lite;
use Template;
use HTML::FormatText;
use HTML::TreeBuilder;

my $root    = FindmJob::Basic->root;
my $config  = FindmJob::Basic->config;
my $dbh     = FindmJob::Basic->dbh;
my $dbh_log = FindmJob::Basic->dbh_log;

my $tt = Template->new(
    INCLUDE_PATH => "$root/templates/emails",
    PRE_CHOMP    => 0,
    POST_CHOMP   => 0,
);
my $formatter = HTML::FormatText->new(leftmargin => 0, rightmargin => 520);

my $mark_as_sent_sth = $dbh->prepare("UPDATE findmjob_log.email SET status=1 WHERE id = ?");

my $sql = "SELECT * FROM findmjob_log.email WHERE status=0";
my $sth = $dbh->prepare($sql);
$sth->execute();
while (my $r = $sth->fetchrow_hashref) {
    print "on $r->{id} / $r->{to}\n";

    my ($html, $text);
    my $data = decode_json($r->{data});
    my $template = $data->{template};
    if ($template) {
        $tt->process("$template.html", $data, \$html)
            || die $tt->error(), "\n";
        my $tree = HTML::TreeBuilder->new_from_content($html);
        $text = $formatter->format($tree);
        $tree = $tree->delete;
    } else {
        $text = delete $data->{TEXT};
        $html = delete $data->{HTML};
    }

    my $from = $data->{from} || 'findmjob.com@gmail.com';
    my $msg = MIME::Lite->new(
        From    => $from,
        To      => $r->{to},
        Subject => $r->{subject},
        Type    => 'multipart/mixed'
    );
    if ($text) {
        $msg->attach(
            Type => 'TEXT',
            Data => $text
        );
    }
    if ($html) {
        $msg->attach(
            Type => 'text/html',
            Data => $html
        );
    }
    $msg->send; # send via default

    $mark_as_sent_sth->execute($r->{id});
}

1;