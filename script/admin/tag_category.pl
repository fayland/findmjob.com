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

my @language = ('perl', 'python', 'java', 'asp', 'php', 'javascript', 'ruby', 'c#', 'c++', 'lisp', 'actionscript', 'c', 'objective-c', 'visual basic', 'sql', '.net', 'asp.net', 'pascal', 'lua', 'fortran', 'scheme', 'bash', 'haskell', 'smalltalk', 'erlang', 'groovy', 'prolog', 'html', 'xml', 'css', 'scala', 'vbscript', 'clojure', 'ColdFusion', 'OCaml', 'Smalltalk', 'shell', 'Dart', 'node.js', 'GoLang');
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

my @skills = ('MySQL', 'Linux', 'svn', 'git', 'mercurial', 'Apache', 'Ajax', 'CoffeeScript', 'LiveScript' 'Catalyst', 'DBIx::Class', 'Moose', 'Ruby on Rails', 'Dancer', 'Mojo', 'Mojolicious', 'ruby-on-rails', 'photoshop', 'facebook', 'hadoop', 'silverlight', 'oracle', 'postgresql', 'iPad', 'iPhone', 'jquery', 'html5', 'unix', 'redis', 'mongodb', 'android', 'css3', 'jquery-ui', 'jQuery Mobile', 'memcached', 'nosql', 'django', 'oracle', 'flex', 'flash', 'Cordova', 'phonegap', 'appmobi', 'telecommute', 'telecommuting', 'CodeIgniter', 'MongoDB', 'Redis', 'Cassandra', 'CouchDB', 'Riak', 'Amazon Web Services', 'AWS', 'SOAP', 'REST', 'OAuth', 'OpenID', 'SEO', 'Rails', 'iOS', 'PayPal', 'eWAY');
foreach my $tag (@skills) {
    $select_sth->execute($tag);
    my ($id) = $select_sth->fetchrow_array;
    $update_sth->execute('skill', $id) if $id;
}

my @softwares = ('WordPress', 'Joomla', 'Drupal', 'WHMCS', 'cPanel', 'Trac', 'MediaWiki', 'vBulletin', 'Discuz!', 'phpMyAdmin', 'TinyMCE', 'CKEditor');
foreach my $tag (@softwares) {
    $select_sth->execute($tag);
    my ($id) = $select_sth->fetchrow_array;
    $update_sth->execute('software', $id) if $id;
}

1;