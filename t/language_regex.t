#!/usr/bin/perl

use strict;
use warnings;
use Test::More;

# snippets from FindmJob::Scrape::Role
my @tags = ('c', 'perl', 'asp.net');
my $tags = join('|', map { quotemeta($_) } @tags);
my $desc = <<'DESC';
required skill: c, asp, Perl, asp_net, c#, c++, python, asp.net
it is cc perl again
DESC

my @t = ($desc =~ /[\s\,]+($tags)[\s\,]+/isg);
is_deeply(\@t, ['c', 'Perl', 'asp.net', 'perl']);

done_testing();

1;