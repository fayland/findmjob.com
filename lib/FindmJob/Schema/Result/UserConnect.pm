use utf8;
package FindmJob::Schema::Result::UserConnect;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

FindmJob::Schema::Result::UserConnect

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<user_connect>

=cut

__PACKAGE__->table("user_connect");

=head1 ACCESSORS

=head2 user_id

  data_type: 'char'
  is_nullable: 0
  size: 22

=head2 service

  data_type: 'varchar'
  is_nullable: 0
  size: 16

=head2 token

  data_type: 'varchar'
  is_nullable: 1
  size: 255

=head2 info

  data_type: 'text'
  is_nullable: 1

=head2 last_connected

  data_type: 'integer'
  default_value: 0
  extra: {unsigned => 1}
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "user_id",
  { data_type => "char", is_nullable => 0, size => 22 },
  "service",
  { data_type => "varchar", is_nullable => 0, size => 16 },
  "token",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "info",
  { data_type => "text", is_nullable => 1 },
  "last_connected",
  {
    data_type => "integer",
    default_value => 0,
    extra => { unsigned => 1 },
    is_nullable => 0,
  },
);

=head1 PRIMARY KEY

=over 4

=item * L</user_id>

=item * L</service>

=back

=cut

__PACKAGE__->set_primary_key("user_id", "service");


# Created by DBIx::Class::Schema::Loader v0.07038 @ 2013-12-20 19:49:41
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:yVdatmG4gjHV4PD6ESl3aw


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
