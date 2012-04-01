package FindmJob::Schema::ResultSet;

use Moose;
use MooseX::NonMoose;
use namespace::autoclean;
extends qw/DBIx::Class::ResultSet/;

use FindmJob::Utils 'uuid';
my @uuid_tables = ('job', 'tag', 'company');

around 'create' => sub {
    my $orig = shift;
    my ($self, $attrs) = @_;

    my $table = $self->result_source->from;
    if (grep { $_ eq $table } @uuid_tables) {
        $attrs->{id} ||= uuid();
    }

    my $row = $self->$orig($attrs);

    # create related in object
    if (grep { $_ eq $table } @uuid_tables) {
        $self->result_source->schema->resultset('Object')->create( {
            id => $row->id,
            tbl => $table,
            time => time(),
        } );
    }

    return $row;
};

1;