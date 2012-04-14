#!/usr/bin/perl

use strict;
use warnings;
use FindBin qw/$Bin/;
use lib "$Bin/../../lib";
use FindmJob::Basic;

my $dbh = FindmJob::Basic->dbh;

my @language = ('perl', 'python', 'java', 'asp', 'php', 'javascript', 'ruby', 'c#', 'c++', 'lisp', 'actionscript', 'c', 'objective-c', 'visual basic', 'sql', '.net', 'asp.net', 'pascal', 'lua', 'fortran', 'scheme', 'bash', 'haskell', 'smalltalk', 'erlang', 'groovy', 'prolog', 'html', 'css', 'scala', 'vbscript');
$dbh->do("UPDATE tag SET category='language' WHERE text IN (" . join(', ', split(//, '?' x @language)) . ")", undef, @language);

my @skills = ('MySQL', 'Linux', 'svn', 'git', 'Apache', 'Ajax', 'node.js', 'coffeescript', 'WordPress', 'Joomla', 'Catalyst', 'DBIx::Class', 'Moose', 'Drupal', 'Ruby on Rails', 'Dancer', 'Mojo', 'ruby-on-rails', 'photoshop', 'facebook', 'hadoop', 'silverlight', 'oracle', 'postgresql', 'iPad', 'iPhone', 'jquery', 'html5', 'unix', 'redis', 'twitter', 'mongodb', 'android', 'css3', 'jquery-ui', 'memcached', 'nosql', 'django', 'oracle');
$dbh->do("UPDATE tag SET category='skill' WHERE text IN (" . join(', ', split(//, '?' x @skills)) . ")", undef, @skills);

1;