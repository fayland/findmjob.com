use utf8;
package FindmJob::Schema::Result::People;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

FindmJob::Schema::Result::People

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<people>

=cut

__PACKAGE__->table("people");

=head1 ACCESSORS

=head2 people_id

  data_type: 'char'
  is_nullable: 0
  size: 22

=head2 name

  data_type: 'varchar'
  is_nullable: 0
  size: 64

=head2 email

  data_type: 'varchar'
  is_nullable: 1
  size: 128

=head2 website

  data_type: 'varchar'
  is_nullable: 1
  size: 128

=head2 title

  data_type: 'varchar'
  is_nullable: 1
  size: 128

=head2 bio

  data_type: 'text'
  is_nullable: 1

=head2 data

  data_type: 'text'
  is_nullable: 1

=head2 updated_at

  data_type: 'integer'
  default_value: 0
  extra: {unsigned => 1}
  is_nullable: 0

=head2 location

  data_type: 'varchar'
  is_nullable: 1
  size: 64

=head2 location_id

  data_type: 'char'
  is_nullable: 1
  size: 22

=cut

__PACKAGE__->add_columns(
  "people_id",
  { data_type => "char", is_nullable => 0, size => 22 },
  "name",
  { data_type => "varchar", is_nullable => 0, size => 64 },
  "email",
  { data_type => "varchar", is_nullable => 1, size => 128 },
  "website",
  { data_type => "varchar", is_nullable => 1, size => 128 },
  "title",
  { data_type => "varchar", is_nullable => 1, size => 128 },
  "bio",
  { data_type => "text", is_nullable => 1 },
  "data",
  { data_type => "text", is_nullable => 1 },
  "updated_at",
  {
    data_type => "integer",
    default_value => 0,
    extra => { unsigned => 1 },
    is_nullable => 0,
  },
  "location",
  { data_type => "varchar", is_nullable => 1, size => 64 },
  "location_id",
  { data_type => "char", is_nullable => 1, size => 22 },
);

=head1 PRIMARY KEY

=over 4

=item * L</people_id>

=back

=cut

__PACKAGE__->set_primary_key("people_id");


# Created by DBIx::Class::Schema::Loader v0.07039 @ 2014-07-05 21:42:39
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:3K8UpAiMCb8HATCbygRzVQ


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
