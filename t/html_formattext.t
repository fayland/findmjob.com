#!/usr/bin/perl

use strict;
use warnings;
use Test::More;
use HTML::TreeBuilder;
use FindmJob::HTML::FormatText;

my $html = <<'HTML';
<h1>Hello</h1>

<a href="http://findmjob.com/" target="_blank">findmjob.com</a>

<img src="http://somewhere.com/x.jpg" />

<font color='red'>Big</font>
HTML

my $tree = HTML::TreeBuilder->new_from_content($html);
my $formatter = FindmJob::HTML::FormatText->new(leftmargin => 0, rightmargin => 999);
my $formatted_text = $formatter->format($tree);
$tree = $tree->delete;

my $text = <<'TEXT';
Hello
=====

<a href="http://findmjob.com/" target="_blank">findmjob.com</a> <img src="http://somewhere.com/x.jpg" /> Big
TEXT

is($formatted_text, $text);
done_testing;

1;