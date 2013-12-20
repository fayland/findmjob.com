package FindmJob::Schema::ResultSet;

use Moo;
extends qw/DBIx::Class::ResultSet/;

use List::MoreUtils 'uniq';
use FindmJob::Utils 'uuid';
my @uuid_tables = ('job', 'freelance', 'tag', 'company', 'subscriber', 'company_review', 'user');
my @tags_tables = ('job', 'freelance', 'company');

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
        my @tags = @$tags; @tags = uniq @tags;
        my %dups;
        foreach my $tag (@tags) {
            next if $dups{lc $tag};
            $dups{lc $tag} = 1;
            my $tag_row = $schema->resultset('Tag')->get_or_create_by_text($tag);
            $schema->resultset('ObjectTag')->create( {
                object => $row->id,
                tag    => $tag_row->id,
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
            my @tags = @$tags; @tags = uniq @tags;
            my %dups;
            foreach my $tag (@tags) {
                next if $dups{lc $tag};
                $dups{lc $tag} = 1;
                my $tag_row = $schema->resultset('Tag')->get_or_create_by_text($tag);
                $schema->resultset('ObjectTag')->create( {
                    object => $row->id,
                    tag    => $tag_row->id,
                    time   => time(),
                } );
            }
        }
    }

    return $st;
};

1;