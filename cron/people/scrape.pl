#!/usr/bin/perl

use strict;
use warnings;
use FindBin qw/$Bin/;
use lib "$Bin/../../lib"; # FindmJob::Basic etc.
use lib "$Bin/../lib";    # FindmJob::Role::
use lib "$Bin/../scrape/lib"; # FindmJob::Scrape::Role
use Moo;
use HTML::TreeBuilder;
use Try::Tiny;
use Data::Dumper;

with 'FindmJob::Scrape::Role';

sub run {
    my $self = shift;

    my $schema = $self->schema;
    my $dbh    = $self->dbh;

    my $ua = $self->ua;

    my $update_sth = $dbh->prepare("UPDATE people_url SET scraped_at = ? WHERE url = ?");

    my $one_day_ago = time() - 86400; # do not repeat scraping if it's done in one day
    my $sth = $dbh->prepare("SELECT url FROM people_url WHERE scraped_at < $one_day_ago ORDER BY inserted_at DESC LIMIT 1000");
    $sth->execute() or die $dbh->errstr;
    while (my ($url) = $sth->fetchrow_array) {
        $self->log_debug("# [People] working on $url");
        my $res = $ua->get($url);
        unless ($res->is_success) {
            print "# Failed to fetch $url: " . $res->status_line . "\n";
            next;
        }

        my $people = $self->parse($url, $res->decoded_content);
        next unless $people;

        # insert or update people
        $people->{identity} = $url;
        $schema->resultset('People')->do_people($people);

        $update_sth->execute(time(), $url);

        sleep 2; # add some sleep
    }
}

sub parse {
    my ($self, $url, $content) = @_;

    return $self->__parse_elance($url, $content) if $url =~ m{/(www\.)?elance\.com/}i;
    die "TO IMPLEMENTED: $url\n";
}

sub __parse_elance {
    my ($self, $url, $content) = @_;

    my $people;
    my $tree = HTML::TreeBuilder->new_from_content($content);
    try {
        $people->{name} = $tree->look_down(_tag => 'h1', id => 'p-title')->as_trimmed_text;
        $people->{title} = $tree->look_down(_tag => 'span', class => qr'p-summary-tagline')->as_trimmed_text;
        my $locality = $tree->look_down(_tag => 'span', class => 'locality');
        my $country  = $tree->look_down(_tag => 'span', class => 'country-name');
        $locality = $locality->as_trimmed_text if $locality;
        $country  = $country->as_trimmed_text  if $country;
        $people->{location} = join(', ', $locality || '', $country || '') if $country or $locality;
        $people->{location} =~ s/(^\,\s*)|(\,\s*$)//g if $people->{location};
        $people->{bio} = $self->format_tree_text($tree->look_down(_tag => 'p', class => qr/p-about-txt/));

        my @tags = $self->get_extra_tags_from_desc($people->{bio});
        push @tags, $self->get_extra_tags_from_desc($people->{title});
        $people->{tags} = \@tags;

        my $s12mo = $tree->look_down(_tag => 'div', id => 'snapshot-12mo-2');
        my @v = $s12mo ? $s12mo->look_down(_tag => 'a') : ();
        @v = map { $_->as_trimmed_text } @v;
        if (@v == 2) {
            $people->{data}{elance}{'12mo'}{review_num} = $v[0];
            $people->{data}{elance}{'12mo'}{recommend_pct} = $v[1];
        }

        my $slife = $tree->look_down(_tag => 'div', id => 'snapshot-life-2');
        @v = $slife ? $slife->look_down(_tag => 'a') : ();
        @v = map { $_->as_trimmed_text } @v;
        if (@v == 2) {
            $people->{data}{elance}{life}{review_num} = $v[0];
            $people->{data}{elance}{life}{recommend_pct} = $v[1];
        }

        $s12mo = $tree->look_down(_tag => 'div', id => 'snapshot-12mo-3');
        $people->{data}{elance}{'12mo'}{review_stars} = $s12mo->as_trimmed_text if $s12mo;
        $slife = $tree->look_down(_tag => 'div', id => 'snapshot-life-3');
        $people->{data}{elance}{life}{review_stars} = $slife->as_trimmed_text if $slife;
    } catch {
        warn $_ . "\n";
    };
    $tree = $tree->delete;

    return $people;
}

__PACKAGE__->new->run();

1;
