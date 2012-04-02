package FindmJob::Schema::ResultSet::ObjectTag;

use Moose;
use namespace::autoclean;
extends 'FindmJob::Schema::ResultSet';

sub get_tags_by_object {
    my ($self, $object) = @_;

    my @all = $self->search({
        object => $object
    }, {
        join      => 'tag',
        'select' => ['tag.id', 'tag.text'],
        'as'     => ['id', 'text'],
        order_by => 'time',
    })->all;
    my @tags = map { {
        id   => $_->get_column('id'),
        text => $_->get_column('text')
    } } @all;
    return wantarray ? @tags : \@tags;
}

1;