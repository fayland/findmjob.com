use utf8;
package FindmJob::Schema::Result::Location;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

FindmJob::Schema::Result::Location

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<location>

=cut

__PACKAGE__->table("location");

=head1 ACCESSORS

=head2 id

  data_type: 'varchar'
  is_nullable: 0
  size: 22

=head2 text

  data_type: 'varchar'
  is_nullable: 0
  size: 128

=head2 city

  data_type: 'varchar'
  is_nullable: 1
  size: 128

=head2 country

  data_type: 'varchar'
  is_nullable: 1
  size: 32

=head2 is_verified

  data_type: 'tinyint'
  default_value: 0
  extra: {unsigned => 1}
  is_nullable: 0

=head2 job_num

  data_type: 'mediumint'
  default_value: 0
  extra: {unsigned => 1}
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "id",
  { data_type => "varchar", is_nullable => 0, size => 22 },
  "text",
  { data_type => "varchar", is_nullable => 0, size => 128 },
  "city",
  { data_type => "varchar", is_nullable => 1, size => 128 },
  "country",
  { data_type => "varchar", is_nullable => 1, size => 32 },
  "is_verified",
  {
    data_type => "tinyint",
    default_value => 0,
    extra => { unsigned => 1 },
    is_nullable => 0,
  },
  "job_num",
  {
    data_type => "mediumint",
    default_value => 0,
    extra => { unsigned => 1 },
    is_nullable => 0,
  },
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


# Created by DBIx::Class::Schema::Loader v0.07035 @ 2013-04-11 22:15:20
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:iUrQi15GDTMRX/s7/7UjYA


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
