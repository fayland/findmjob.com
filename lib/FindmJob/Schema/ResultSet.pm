package FindmJob::Schema::ResultSet;

use Moose;
use MooseX::NonMoose;
use namespace::autoclean;
extends qw/DBIx::Class::ResultSet/;

use FindmJob::Utils 'uuid';
my @uuid_tables = ('job', 'tag', 'company');
my @tags_tables = ('job', 'company');

around 'create' => sub {
    my $orig = shift;
    my ($self, $attrs) = @_;

    my $tags = delete $attrs->{tags}; # all object will have tags
    my $table = $self->result_source->from;
    if (grep { $_ eq $table } @uuid_tables) {
        $attrs->{id} ||= uuid();
    }

    my $row = $self->$orig($attrs);

    # create related in object
    if (grep { $_ eq $table } @uuid_tables) {
        my $schema = $self->result_source->schema;
        $schema->resultset('Object')->create( {
            id => $row->id,
            tbl => $table,
            time => time(),
        } );
    }
    if ((grep { $_ eq $table } @tags_tables) and defined $tags) {
        my $schema = $self->result_source->schema;
        foreach my $tag (@$tags) {
            my $tag_id = $schema->resultset('Tag')->get_id_by_text($tag);
            $schema->resultset('ObjectTag')->create( {
                object => $row->id,
                tag    => $tag_id,
                time   => time(),
            } );
        }
    }

    return $row;
};

around 'update' => sub {
    my $orig = shift;
    my ($self, $values) = @_;

    my $tags = delete $values->{tags};
    my $st = $self->$orig($values);

    my $table = $self->result_source->from;
    if ((grep { $_ eq $table } @tags_tables) and defined $tags) {
        my $schema = $self->result_source->schema;

        # loop on each matched rows
        while (my $row = $self->next) {
            $schema->resultset('ObjectTag')->search( { object => $row->id } )->delete;
            foreach my $tag (@$tags) {
                my $tag_id = $schema->resultset('Tag')->get_id_by_text($tag);
                $schema->resultset('ObjectTag')->create( {
                    object => $row->id,
                    tag    => $tag_id,
                    time   => time(),
                } );
            }
        }
    }

    return $st;
};

1;