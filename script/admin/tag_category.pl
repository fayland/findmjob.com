#!/usr/bin/perl

use strict;
use warnings;
use FindBin qw/$Bin/;
use lib "$Bin/../../lib";
use FindmJob::Basic;
use FindmJob::Utils 'uuid';

my $dbh = FindmJob::Basic->dbh;

my $select_sth = $dbh->prepare("SELECT id FROM tag WHERE text = ?");
my $insert_sth = $dbh->prepare("INSERT INTO tag (id, text, category) VALUES (?, ?, ?)");
my $update_sth = $dbh->prepare("UPDATE tag SET category = ? WHERE id = ?");

my @language = ('perl', 'python', 'java', 'asp', 'php', 'javascript', 'ruby', 'c#', 'c++', 'lisp', 'actionscript', 'c', 'objective-c', 'visual basic', 'sql', '.net', 'asp.net', 'pascal', 'lua', 'fortran', 'scheme', 'bash', 'haskell', 'smalltalk', 'erlang', 'groovy', 'prolog', 'html', 'xml', 'css', 'scala', 'vbscript', 'clojure', 'ColdFusion', 'OCaml', 'Smalltalk', 'shell', 'Dart');
foreach my $tag (@language) {
    $select_sth->execute($tag);
    my ($id) = $select_sth->fetchrow_array;
    if ($id) {
        $update_sth->execute('language', $id);
    } else {
        $id = uuid();
        $insert_sth->execute($id, $tag, 'language');
    }
}

my @skills = ('MySQL', 'Linux', 'svn', 'git', 'Apache', 'Ajax', 'node.js', 'coffeescript', 'WordPress', 'Joomla', 'Catalyst', 'DBIx::Class', 'Moose', 'Drupal', 'Ruby on Rails', 'Dancer', 'Mojo', 'ruby-on-rails', 'photoshop', 'facebook', 'hadoop', 'silverlight', 'oracle', 'postgresql', 'iPad', 'iPhone', 'jquery', 'html5', 'unix', 'redis', 'mongodb', 'android', 'css3', 'jquery-ui', 'jQuery Mobile', 'memcached', 'nosql', 'django', 'oracle', 'flex', 'flash', 'Cordova', 'phonegap', 'appmobi', 'telecommute', 'telecommuting', 'cPanel', 'MongoDB', 'Redis', 'Cassandra', 'CouchDB', 'Riak', 'Amazon Web Services', 'AWS', 'SOAP', 'REST', 'OAuth', 'OpenID', 'SEO', 'Rails', 'iOS');
foreach my $tag (@skills) {
    $select_sth->execute($tag);
    my ($id) = $select_sth->fetchrow_array;
    if ($id) {
        $update_sth->execute('skill', $id);
    } else {
        $id = uuid();
        $insert_sth->execute($id, $tag, 'skill');
    }
}
1;