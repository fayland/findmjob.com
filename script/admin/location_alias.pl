#!/usr/bin/perl

use strict;
use warnings;
use FindBin qw/$Bin/;
use lib "$Bin/../../lib";
use FindmJob::Basic;
use FindmJob::Utils 'uuid';
use feature 'say';
use IO::Prompter;

my $dbh = FindmJob::Basic->dbh;

my $location = shift @ARGV;
unless ($location) {
    $location = prompt 'Enter the location to search: ';
}

my @matches;
my $sth = $dbh->prepare("SELECT * FROM location WHERE text RLIKE ?");
$sth->execute($location);
while (my $row = $sth->fetchrow_hashref) {
    push @matches, $row;
}

say "# We found " . scalar(@matches) . " matches.";
exit(0) unless @matches;
if (@matches == 1) {
    print "# " . $matches[0]->{text} . "\n";
    exit(0);
}

my @all_texts = map { $_->{text} } @matches;
my $select = prompt 'Please select ...', -menu => \@all_texts, '>';

say "You have picked up $select";
my ($picked) = grep { $_->{text} eq $select } @matches;
die unless $picked;

my $id = $picked->{id};
foreach my $m (@matches) {
    next if $m->{id} eq $id;

    my $want_edit = prompt "Do you want to alias '$m->{text}'? [yn]", -yesno;
    next if $want_edit =~ /^n/;

    say "# Update Job location_id $m->{id} -> $id";
    $dbh->do("UPDATE job SET location_id = ? WHERE location_id = ?", undef, $id, $m->{id}) or die $dbh->errstr;

    $dbh->do("INSERT INTO location_alias (text, id) VALUES (?, ?) ON DUPLICATE KEY UPDATE id=values(id)", undef, $m->{text}, $id);

    say "# Delete $m->{id}, $m->{text}\n\n";
    $dbh->do("DELETE FROM location WHERE id = ?", undef, $m->{id}) or die $dbh->errstr;
}

exit(0) if $picked->{is_verified};

say "Picked row:";
say "    City: " . ($picked->{city} || '(Blank)');
say "    State: " . ($picked->{state} || '(Blank)');
say "    Country: " . ($picked->{country} || '(Blank)');

my $want_edit = prompt "Do you want to edit this? [yn]", -yesno;
if ($want_edit =~ /^y/) {
    my $to_text = prompt "Text: ", -default => $picked->{text};
    $to_text ||= $picked->{text};

    my $to_city = prompt "City: ", -default => $picked->{city};
    $to_city ||= $picked->{city};

    my $to_state = prompt "State: ", -default => $picked->{state};
    $to_state ||= $picked->{state};

    my $to_country = prompt "Country: ", -default => $picked->{country};
    $to_country ||= $picked->{country};

    my $confirm_save = prompt "Save $picked->{text} with City($to_city), State($to_state) and Country($to_country)? [yn]", -yesno;
    if ($confirm_save =~ /^y/) {
        $dbh->do("UPDATE location SET text = ?, city = ?, country = ?, is_verified=1 WHERE id = ?", undef, $to_text, $to_city, $to_country, $id);
    }
}

say "Done";

1;