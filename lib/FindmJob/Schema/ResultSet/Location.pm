package FindmJob::Schema::ResultSet::Location;

use Moo;
extends 'FindmJob::Schema::ResultSet';

use FindmJob::Utils 'uuid';
use Locale::Codes::Country;

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

    my $schema = $self->result_source->schema;
    my $dbh = $schema->storage->dbh;

    my ($id) = $dbh->selectrow_array("SELECT id FROM location_alias WHERE text = ?", undef, $text);
    return $id if $id;

    my $row = $schema->resultset('Location')->search( { text => $text } )->first;
    return $row->id if $row and $row->country;

    my $countries_regex = $self->countries_regex;
    # parse country
    my $country = '';
    my $o_text = $text;
    if ($text =~ s{(^|\,\s*|\s+)($countries_regex)$}{}) { # {}()
        $country = $2;
    }
    $country = 'United States' if $country eq 'USA';
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