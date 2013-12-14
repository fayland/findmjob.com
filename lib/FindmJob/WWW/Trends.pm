package FindmJob::WWW::Trends;

use Mojo::Base 'Mojolicious::Controller';

sub index {
    my $self = shift;

    my $schema = $self->schema;
    my $dbh = $schema->storage->dbh;

    my (%languages, %skills, %softwares, %total_count);
    my $sth = $dbh->prepare(<<SQL);
SELECT tr.*, tag.text, tag.category FROM stats_trends tr JOIN tag ON tr.tag_id=tag.id WHERE tr.dt > DATE_SUB(NOW(), INTERVAL 30 DAY) order by dt;
SQL
    $sth->execute();
    while (my $row = $sth->fetchrow_hashref) {
        if ($row->{category} eq 'language') {
            push @{ $languages{$row->{text}} }, $row;
        } elsif ($row->{category} eq 'software') {
            push @{ $softwares{$row->{text}} }, $row;
        } else {
            push @{ $skills{$row->{text}} }, $row;
        }
        $total_count{$row->{category}}{$row->{text}} += $row->{num};
    }

    $total_count{language} ||= {};
    $total_count{skill} ||= {};
    $total_count{software} ||= {};
    my @languages = sort { $total_count{language}{$b} <=> $total_count{language}{$a} } keys %{ $total_count{language} };
    my @skills = sort { $total_count{skill}{$b} <=> $total_count{skill}{$a} } keys %{ $total_count{skill} };
    my @softwares = sort { $total_count{software}{$b} <=> $total_count{software}{$a} } keys %{ $total_count{software} };

    $self->stash(
        languages => \%languages,
        skills => \%skills,
        softwares => \%softwares,
        top_languages => [splice(@languages, 0, 15)],
        top_skills => [splice(@skills, 0, 15)],
        top_softwares => [splice(@softwares, 0, 15)],
    );
}


1;