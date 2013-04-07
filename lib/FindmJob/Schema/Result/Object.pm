use utf8;
package FindmJob::Schema::Result::Object;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

FindmJob::Schema::Result::Object

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<object>

=cut

__PACKAGE__->table("object");

=head1 ACCESSORS

=head2 id

  data_type: 'varchar'
  is_nullable: 0
  size: 22

=head2 tbl

  data_type: 'varchar'
  is_nullable: 0
  size: 12

=head2 time

  data_type: 'integer'
  default_value: 0
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "id",
  { data_type => "varchar", is_nullable => 0, size => 22 },
  "tbl",
  { data_type => "varchar", is_nullable => 0, size => 12 },
  "time",
  { data_type => "integer", default_value => 0, is_nullable => 0 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");


# Created by DBIx::Class::Schema::Loader v0.07035 @ 2013-04-07 09:59:31
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:rv4m8baP9bXuX7veRPSjBQ


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
