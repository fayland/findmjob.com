#!/usr/bin/perl

use strict;
use warnings;
use FindBin qw/$Bin/;
use lib "$Bin/../../lib";
use FindmJob::Basic;
use WWW::SitemapIndex::XML;
use WWW::Sitemap::XML;
use LWP::UserAgent;
use URI::Escape;

my $root = FindmJob::Basic->root;
my $dir = "$root/static/";

my $config = FindmJob::Basic->config;
my $schema = FindmJob::Basic->schema;
my $dbh = FindmJob::Basic->dbh;

my @d = localtime();
my $today = sprintf('%04d-%02d-%02d', $d[5] + 1900, $d[4] + 1, $d[3]);

## an index with 4 files, jobs, freelancer, tags and companies
my $index = WWW::SitemapIndex::XML->new();
$index->add(
    loc => $config->{sites}->{main} . '/sitemap.jobs.xml.gz',
    lastmod => $today,
);
$index->add(
    loc => $config->{sites}->{main} . '/sitemap.freelances.xml.gz',
    lastmod => $today,
);
$index->add(
    loc => $config->{sites}->{main} . '/sitemap.tags.xml.gz',
    lastmod => $today,
);

=pod

$index->add(
    loc => $config->{sites}->{main} . '/sitemap.companies.xml.gz',
    lastmod => $today,
);

=cut

$index->write("$dir/sitemap.xml.gz");

# sitemaps.jobs.xml.gz
my $map = WWW::Sitemap::XML->new();
$map->add(
    loc => 'http://findmjob.com/',
    lastmod => $today,
    changefreq => 'daily',
    priority => 1.0,
);

# Each text file can contain a maximum of 50,000 URLs and must be no larger than 10MB (10,485,760 bytes)
my $rs = $schema->resultset('Job')->search( {
    expired_at => { '>', \"NOW()" }, #"
}, {
    order_by => 'inserted_at DESC',
    rows => 10000,
    page => 1
} );
while (my $r = $rs->next) {
    my $url = $config->{sites}->{main} . $r->url;
    $map->add(
        loc => $url,
        priority => 0.7,
    );
}
$map->write("$dir/sitemap.jobs.xml.gz");

# sitemap.freelances.xml.gz
$map = WWW::Sitemap::XML->new();
$rs = $schema->resultset('Freelance')->search( {
    expired_at => { '>', \"NOW()" }, #"
}, {
    order_by => 'inserted_at DESC',
    rows => 10000,
    page => 1
} );
while (my $r = $rs->next) {
    my $url = $config->{sites}->{main} . $r->url;
    $map->add(
        loc => $url,
        priority => 0.7,
    );
}
$map->write("$dir/sitemap.freelances.xml.gz");

# sitemap.tags.xml.gz
$map = WWW::Sitemap::XML->new();
$rs = $schema->resultset('Tag')->search( undef, {
    rows => 10000,
    page => 1
} );
while (my $r = $rs->next) {
    my $url = $config->{sites}->{main} . '/tag' . $r->id;
    $map->add(
        loc => $url,
        priority => 0.5,
    );
}
$map->write("$dir/sitemap.tags.xml.gz");

# add ping
LWP::UserAgent->new->get( "http://www.google.com/webmasters/tools/ping?sitemap=" . uri_escape($config->{sites}->{main} . '/sitemap.xml.gz') );

1;
