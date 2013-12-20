use utf8;
package FindmJob::Schema::Result::User;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

FindmJob::Schema::Result::User

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<user>

=cut

__PACKAGE__->table("user");

=head1 ACCESSORS

=head2 id

  data_type: 'char'
  is_nullable: 0
  size: 22

=head2 email

  data_type: 'varchar'
  is_nullable: 0
  size: 128

=head2 name

  data_type: 'varchar'
  is_nullable: 1
  size: 64

=cut

__PACKAGE__->add_columns(
  "id",
  { data_type => "char", is_nullable => 0, size => 22 },
  "email",
  { data_type => "varchar", is_nullable => 0, size => 128 },
  "name",
  { data_type => "varchar", is_nullable => 1, size => 64 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");

=head1 UNIQUE CONSTRAINTS

=head2 C<email>

=over 4

=item * L</email>

=back

=cut

__PACKAGE__->add_unique_constraint("email", ["email"]);


# Created by DBIx::Class::Schema::Loader v0.07038 @ 2013-12-20 19:49:41
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:hMSwV+1IjqhvJeooV/9qRg


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
