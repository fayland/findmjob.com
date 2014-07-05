package FindmJob::Schema::ResultSet::PeopleUrl;

use Moo;
extends 'FindmJob::Schema::ResultSet';

sub insert_urls {
    my ($self, @urls) = @_;

    my $schema = $self->result_source->schema;
    my $dbh = $schema->storage->dbh;

    my $sth = $dbh->prepare("INSERT INTO people_url (url, inserted_at) VALUES (?, ?) ON DUPLICATE KEY UPDATE inserted_at=values(inserted_at);");
    foreach my $url (@urls) {
        $sth->execute($url, time());
    }
}

1;