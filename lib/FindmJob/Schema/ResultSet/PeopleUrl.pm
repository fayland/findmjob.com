package FindmJob::Schema::ResultSet::PeopleUrl;

use Moo;
extends 'FindmJob::Schema::ResultSet';

sub insert_urls {
    my ($self, @urls) = @_;

    my $schema = $self->result_source->schema;
    my $dbh = $schema->storage->dbh;

    my $sth = $dbh->prepare("INSERT IGNORE INTO people_url (url) VALUES (?);");
    foreach my $url (@urls) {
        $sth->execute($url);
    }
}

1;