#!/usr/bin/perl

use strict;
use warnings;
use FindBin qw/$Bin/;
use lib "$Bin/../../lib";
use FindmJob::Basic;
use WWW::Sitemap::XML;

my $root = FindmJob::Basic->root;
my $file = "$root/static/sitemap.xml.gz";

my $map = WWW::Sitemap::XML->new();
my $config = FindmJob::Basic->config;
my $schema = FindmJob::Basic->schema;
my $dbh = FindmJob::Basic->dbh;

my @d = localtime();
my $today = sprintf('%04d-%02d-%02d', $d[5] + 1900, $d[4] + 1, $d[3]);
$map->add(
    loc => 'http://findmjob.com/',
    lastmod => $today,
    changefreq => 'daily',
    priority => 1.0,
);

my $sth = $dbh->prepare("SELECT id, tbl FROM object ORDER BY time DESC LIMIT 500");
$sth->execute();
while (my ($id, $tbl) = $sth->fetchrow_array) {
    my $obj = $schema->resultset(ucfirst $tbl)->find($id);
    my $url = $config->{sites}->{main} . '/' . $tbl . '/' . $id;
    $url = $config->{sites}->{main} . $obj->url if $obj->can('url');
    if ($tbl eq 'job') {
        $map->add(
            loc => $url,
            priority => 0.7,
        );
    } else {
        $map->add(
            loc => $url,
            priority => 0.5,
        );
    }
}

$map->write($file);

1;
