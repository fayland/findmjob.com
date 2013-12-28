use utf8;
package FindmJob::Schema::Result::CompanyCorrection;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

FindmJob::Schema::Result::CompanyCorrection

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<company_correction>

=cut

__PACKAGE__->table("company_correction");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_auto_increment: 1
  is_nullable: 0

=head2 company_id

  data_type: 'char'
  is_nullable: 0
  size: 22

=head2 edited_by

  data_type: 'varchar'
  is_nullable: 1
  size: 255

=head2 edited_on

  data_type: 'timestamp'
  datetime_undef_if_invalid: 1
  default_value: current_timestamp
  is_nullable: 0

=head2 data

  data_type: 'text'
  is_nullable: 1

=head2 is_reviewed

  data_type: 'tinyint'
  default_value: 0
  extra: {unsigned => 1}
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_auto_increment => 1,
    is_nullable => 0,
  },
  "company_id",
  { data_type => "char", is_nullable => 0, size => 22 },
  "edited_by",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "edited_on",
  {
    data_type => "timestamp",
    datetime_undef_if_invalid => 1,
    default_value => \"current_timestamp",
    is_nullable => 0,
  },
  "data",
  { data_type => "text", is_nullable => 1 },
  "is_reviewed",
  {
    data_type => "tinyint",
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


# Created by DBIx::Class::Schema::Loader v0.07038 @ 2013-12-15 20:45:02
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:NZyOzfUMQSXuWP+621rZKQ

__PACKAGE__->belongs_to(
    company => 'Company',
    { 'foreign.id' => 'self.company_id' }
);

__PACKAGE__->load_components('InflateColumn::Serializer');
__PACKAGE__->add_columns('+data', { serializer_class => 'JSON' });

1;
