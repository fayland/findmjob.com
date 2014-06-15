use utf8;
package FindmJob::Schema::Result::App;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

FindmJob::Schema::Result::App

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<app>

=cut

__PACKAGE__->table("app");

=head1 ACCESSORS

=head2 id

  data_type: 'char'
  is_nullable: 0
  size: 22

=head2 website

  data_type: 'varchar'
  is_nullable: 0
  size: 255

=head2 user_id

  data_type: 'char'
  is_nullable: 0
  size: 22

=head2 is_verified

  data_type: 'tinyint'
  default_value: 0
  is_nullable: 0

=head2 is_disabled

  data_type: 'tinyint'
  default_value: 0
  is_nullable: 0

=head2 name

  data_type: 'varchar'
  is_nullable: 0
  size: 64

=cut

__PACKAGE__->add_columns(
  "id",
  { data_type => "char", is_nullable => 0, size => 22 },
  "website",
  { data_type => "varchar", is_nullable => 0, size => 255 },
  "user_id",
  { data_type => "char", is_nullable => 0, size => 22 },
  "is_verified",
  { data_type => "tinyint", default_value => 0, is_nullable => 0 },
  "is_disabled",
  { data_type => "tinyint", default_value => 0, is_nullable => 0 },
  "name",
  { data_type => "varchar", is_nullable => 0, size => 64 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");


# Created by DBIx::Class::Schema::Loader v0.07039 @ 2014-06-15 13:32:53
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:N5+M6Pp4G6D9EGiy8YQBXA


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
