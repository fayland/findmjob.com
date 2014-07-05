use utf8;
package FindmJob::Schema::Result::PeopleIdentity;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

FindmJob::Schema::Result::PeopleIdentity

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<people_identity>

=cut

__PACKAGE__->table("people_identity");

=head1 ACCESSORS

=head2 identity

  data_type: 'varchar'
  is_nullable: 0
  size: 128

=head2 people_id

  data_type: 'char'
  is_nullable: 0
  size: 22

=cut

__PACKAGE__->add_columns(
  "identity",
  { data_type => "varchar", is_nullable => 0, size => 128 },
  "people_id",
  { data_type => "char", is_nullable => 0, size => 22 },
);

=head1 PRIMARY KEY

=over 4

=item * L</identity>

=back

=cut

__PACKAGE__->set_primary_key("identity");


# Created by DBIx::Class::Schema::Loader v0.07039 @ 2014-07-05 21:42:39
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:0k5pj5ay7JTWYjEon4mCGw


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
