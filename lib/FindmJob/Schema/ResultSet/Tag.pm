package FindmJob::Schema::ResultSet::Tag;

use Moose;
use namespace::autoclean;
extends 'FindmJob::Schema::ResultSet';

use FindmJob::Utils 'uuid';

sub get_id_by_text {
    my ($self, $text) = @_;

    my $row = $self->get_row_by_text($text);
    return $row->id if $row;
    return;
}

sub get_row_by_text {
    my ($self, $text) = @_;

    my $row = $self->search( { text => $text } )->first;
    return $row;
}

sub get_or_create_by_text {
    my ($self, $text) = @_;

    my $row = $self->get_row_by_text($text);
    $row  ||= $self->create( { text => $text } );
    return $row;
}

1;