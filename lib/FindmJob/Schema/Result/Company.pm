use utf8;
package FindmJob::Schema::Result::Company;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

FindmJob::Schema::Result::Company

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<company>

=cut

__PACKAGE__->table("company");

=head1 ACCESSORS

=head2 id

  data_type: 'varchar'
  is_nullable: 0
  size: 32

=head2 name

  data_type: 'varchar'
  is_nullable: 0
  size: 128

=head2 contact

  data_type: 'text'
  is_nullable: 0

=head2 website

  data_type: 'varchar'
  is_nullable: 0
  size: 128

=cut

__PACKAGE__->add_columns(
  "id",
  { data_type => "varchar", is_nullable => 0, size => 32 },
  "name",
  { data_type => "varchar", is_nullable => 0, size => 128 },
  "contact",
  { data_type => "text", is_nullable => 0 },
  "website",
  { data_type => "varchar", is_nullable => 0, size => 128 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");


# Created by DBIx::Class::Schema::Loader v0.07019 @ 2012-03-31 22:36:39
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:UuI9m3awi0pno/aJLKMDdA


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
