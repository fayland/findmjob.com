use utf8;
package FindmJob::Schema::Result::CompanyReview;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

FindmJob::Schema::Result::CompanyReview

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<company_review>

=cut

__PACKAGE__->table("company_review");

=head1 ACCESSORS

=head2 id

  data_type: 'char'
  is_nullable: 0
  size: 22

=head2 title

  data_type: 'varchar'
  is_nullable: 0
  size: 255

=head2 rating

  data_type: 'tinyint'
  default_value: 0
  extra: {unsigned => 1}
  is_nullable: 0

=head2 pros

  data_type: 'text'
  is_nullable: 1

=head2 cons

  data_type: 'text'
  is_nullable: 1

=head2 inserted_at

  data_type: 'integer'
  default_value: 0
  extra: {unsigned => 1}
  is_nullable: 0

=head2 company_id

  data_type: 'char'
  is_nullable: 0
  size: 22

=head2 role

  data_type: 'varchar'
  is_nullable: 1
  size: 32

=head2 extra

  data_type: 'text'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "id",
  { data_type => "char", is_nullable => 0, size => 22 },
  "title",
  { data_type => "varchar", is_nullable => 0, size => 255 },
  "rating",
  {
    data_type => "tinyint",
    default_value => 0,
    extra => { unsigned => 1 },
    is_nullable => 0,
  },
  "pros",
  { data_type => "text", is_nullable => 1 },
  "cons",
  { data_type => "text", is_nullable => 1 },
  "inserted_at",
  {
    data_type => "integer",
    default_value => 0,
    extra => { unsigned => 1 },
    is_nullable => 0,
  },
  "company_id",
  { data_type => "char", is_nullable => 0, size => 22 },
  "role",
  { data_type => "varchar", is_nullable => 1, size => 32 },
  "extra",
  { data_type => "text", is_nullable => 1 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");


# Created by DBIx::Class::Schema::Loader v0.07035 @ 2013-08-15 20:02:27
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:RgHeEzfN8UlH9lmLueAabQ


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
