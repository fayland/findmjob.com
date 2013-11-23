package FindmJob::WWW::Trends;

use Mojo::Base 'Mojolicious::Controller';

sub index {
    my $self = shift;

    my $schema = $self->schema;
    my $dbh = $schema->storage->dbh;

    my (%languages, %skills);
    my $sth = $dbh->prepare(<<SQL);
SELECT tr.*, tag.text, tag.category FROM stats_trends tr JOIN tag ON tr.tag_id=tag.id WHERE tr.dt > DATE_SUB(NOW(), INTERVAL 30 DAY) order by dt;
SQL
    $sth->execute();
    while (my $row = $sth->fetchrow_hashref) {
        if ($row->{category} eq 'language') {
            push @{ $languages{$row->{text}} }, $row;
        } else {
            push @{ $skills{$row->{text}} }, $row;
        }
    }

    $self->stash(
        languages => \%languages,
        skills => \%skills,
    );
}


1;