use utf8;
package FindmJob::Schema::Result::Tag;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

FindmJob::Schema::Result::Tag

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<tag>

=cut

__PACKAGE__->table("tag");

=head1 ACCESSORS

=head2 id

  data_type: 'varchar'
  is_nullable: 0
  size: 22

=head2 text

  data_type: 'varchar'
  is_nullable: 0
  size: 64

=head2 category

  data_type: 'varchar'
  is_nullable: 1
  size: 24

=cut

__PACKAGE__->add_columns(
  "id",
  { data_type => "varchar", is_nullable => 0, size => 22 },
  "text",
  { data_type => "varchar", is_nullable => 0, size => 64 },
  "category",
  { data_type => "varchar", is_nullable => 1, size => 24 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");

=head1 UNIQUE CONSTRAINTS

=head2 C<text>

=over 4

=item * L</text>

=back

=cut

__PACKAGE__->add_unique_constraint("text", ["text"]);


# Created by DBIx::Class::Schema::Loader v0.07035 @ 2013-04-07 09:59:31
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:F5cO1DRFLSlE83jeacTCnw


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
