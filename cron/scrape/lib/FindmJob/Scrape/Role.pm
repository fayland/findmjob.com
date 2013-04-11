package FindmJob::Scrape::Role;

use Moo::Role;
use FindmJob::Utils 'uuid';
use Locale::Codes::Country;

with 'FindmJob::Role::Basic';
with 'FindmJob::Role::UA';
with 'FindmJob::Role::TextFormatter';
with 'FindmJob::Role::Logger';

has 'opt_update' => ( is => 'ro', default => sub { '0' } );

has 'language_regex' => ( is => 'lazy' );
sub _build_language_regex {
    my $self = shift;
    my $schema = $self->schema;
    my @tags = $schema->resultset('Tag')->search( { category => ['language', 'skill'] } )->all;
    @tags = map { $_->text } @tags;
    my $tags = join('|', map { quotemeta($_) } @tags);
    return $tags;
}
sub get_extra_tags_from_desc {
    my ($self, $desc) = @_;

    return unless $desc and length $desc;

    my $language_regex = $self->language_regex;
    my @tags = ($desc =~ /(?:^|[\s\,\/\(\)]+)($language_regex)(?:[\s\,\/\(\)\.]+|$)/isg);

    return @tags;
}

## Location related
has 'countries_regex' => (is => 'lazy');
sub _build_countries_regex {
    my $self = shift;

    my @names = all_country_names();
    push @names, 'USA';
    return join('|', @names);
}

sub get_location_id_from_text {
    my ($self, $text) = @_;

    return unless $text;
    return unless length($text) > 2;

    my $schema = $self->schema;
    my $dbh = $schema->storage->dbh;

    my ($id) = $dbh->selectrow_array("SELECT id FROM location_alias WHERE text = ?", undef, $text);
    return $id;

    my $row = $schema->resultset('Location')->search( { text => $text } )->first;
    return $row->id if $row and $row->country;

    my $countries_regex = $self->countries_regex;
    # parse country
    my $o_text = $text;
    ($text =~ s{(^|\,\s*|\s+)($countries_regex)$}{}) and my $country = $2;
    $country = 'United States' if $country and $country eq 'USA';
    if ($row) {
        $row->update({ city => $text, country => $country }) if $country;
        return $row->id;
    } else {
        my $id = uuid();
        $schema->resultset('Location')->create({
            id => $id,
            text => $o_text,
            ($country) ? (country => $country, city => $text) : ()
        });
        $dbh->do("INSERT IGNORE INTO location_alias (text, id) VALUES (?, ?)", undef, $o_text, $id);
        return $id;
    }
}

1;