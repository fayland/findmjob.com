#!/usr/bin/perl

use strict;
use warnings;
use FindBin qw/$Bin/;
use lib "$Bin/../../lib";
use FindmJob::Basic;
use FindmJob::HTML::FormatText;

my $formatter = FindmJob::HTML::FormatText->new(leftmargin => 0, rightmargin => 999);
my $dbh = FindmJob::Basic->dbh;
my $sth = $dbh->prepare("SELECT id, description FROM job WHERE source_url rlike 'github.com' and description rlike '<p>'");
$sth->execute();
my $update_sth = $dbh->prepare("UPDATE job SET description = ? WHERE id = ?");
while (my ($id, $description) = $sth->fetchrow_array) {
    my $tree = HTML::TreeBuilder->new_from_content($description);
    my $text = $formatter->format($tree);
    $tree = $tree->delete;
    $update_sth->execute($text, $id);
}

1;