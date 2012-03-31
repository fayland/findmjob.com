package FindmJob::Schema::ResultSet::Tag;

use Moose;
use namespace::autoclean;
extends 'DBIx::Class::ResultSet';

sub get_id_by_text {
    my ($self, $text) = @_;

    my $row = $self->search( { text => $text } )->first;
    return $row->id if $row;
    # FIXME
}

1;