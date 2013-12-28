use utf8;
package FindmJob::Schema::Result::UserUpdate;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

FindmJob::Schema::Result::UserUpdate

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<user_update>

=cut

__PACKAGE__->table("user_update");

=head1 ACCESSORS

=head2 user_id

  data_type: 'char'
  is_nullable: 0
  size: 22

=head2 object_id

  data_type: 'char'
  is_nullable: 0
  size: 22

=head2 tbl

  data_type: 'varchar'
  is_nullable: 0
  size: 12

=head2 follow_id

  data_type: 'char'
  is_nullable: 0
  size: 22

=head2 pushed_at

  data_type: 'integer'
  default_value: 0
  extra: {unsigned => 1}
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "user_id",
  { data_type => "char", is_nullable => 0, size => 22 },
  "object_id",
  { data_type => "char", is_nullable => 0, size => 22 },
  "tbl",
  { data_type => "varchar", is_nullable => 0, size => 12 },
  "follow_id",
  { data_type => "char", is_nullable => 0, size => 22 },
  "pushed_at",
  {
    data_type => "integer",
    default_value => 0,
    extra => { unsigned => 1 },
    is_nullable => 0,
  },
);


# Created by DBIx::Class::Schema::Loader v0.07038 @ 2013-12-28 19:58:24
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:fNfadOwMN4+qktITgEAH4g


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
