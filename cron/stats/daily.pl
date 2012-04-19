#!/usr/bin/perl

use strict;
use warnings;
use FindBin qw/$Bin/;
use lib "$Bin/../../lib"; # FindmJob::Basic
use FindmJob::Basic;
use FindmJob::Email 'sendmail';
use FindmJob::DateUtils 'today_date';
use Data::Dumper;
use URI;

my $config  = FindmJob::Basic->config;
my $dbh     = FindmJob::Basic->dbh;
my $dbh_log = FindmJob::Basic->dbh_log;

my $text;

# sharebots
my $daysago = time() - 7 * 86400;
my $sql = "select DATE(FROM_UNIXTIME(time)) d, site, COUNT(*) as cnt from `findmjob_log`.sharebot WHERE time > $daysago group by d, site ORDER by d DESC";
my $sth = $dbh_log->prepare($sql);
$sth->execute();
$text .= "Daily ShareBot Stats:\n";
my %sharebot_stats;
while (my ($d, $site, $cnt) = $sth->fetchrow_array) {
    $sharebot_stats{$d}{$site} = $cnt;
}

foreach my $d (sort { $b cmp $a } keys %sharebot_stats) {
    my $total = 0;
    foreach my $s (keys %{$sharebot_stats{$d}}) {
        $text .= "$d\t$s\t$sharebot_stats{$d}{$s}\n";
        $total += $sharebot_stats{$d}{$s};
    }
    $text .= "=" x 30 . "\n";
    $text .= "$d\tTotal\t$total\n";
    $text .= "=" x 40 . "\n";
}

# jobs scraped
$sql = "select DATE(FROM_UNIXTIME(inserted_at)) d, source_url from job WHERE inserted_at > $daysago";
$sth = $dbh_log->prepare($sql);
$sth->execute();
$text .= "Daily Scrape Stats:\n";
my %scrape_stats;
while (my ($d, $url) = $sth->fetchrow_array) {
    my $host = URI->new($url)->host;
    $scrape_stats{$d}{$host}++;
}

foreach my $d (sort { $b cmp $a } keys %scrape_stats) {
    my $total = 0;
    foreach my $s (keys %{$scrape_stats{$d}}) {
        $text .= "$d\t$s\t$scrape_stats{$d}{$s}\n";
        $total += $scrape_stats{$d}{$s};
    }
    $text .= "=" x 30 . "\n";
    $text .= "$d\tTotal\t$total\n";
    $text .= "=" x 40 . "\n";
}

sendmail($config->{email}->{default_from}, $config->{email}->{default_to}, 'Daily Report ' . today_date(), $text);

1;