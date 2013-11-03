use utf8;
package FindmJob::Schema::Result::Job;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

FindmJob::Schema::Result::Job

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<job>

=cut

__PACKAGE__->table("job");

=head1 ACCESSORS

=head2 id

  data_type: 'char'
  is_nullable: 0
  size: 22

=head2 source_url

  data_type: 'varchar'
  is_nullable: 0
  size: 255

=head2 title

  data_type: 'varchar'
  is_nullable: 0
  size: 128

=head2 company_id

  data_type: 'char'
  is_nullable: 0
  size: 22

=head2 posted_at

  data_type: 'datetime'
  datetime_undef_if_invalid: 1
  is_nullable: 0

=head2 expired_at

  data_type: 'datetime'
  datetime_undef_if_invalid: 1
  is_nullable: 0

=head2 description

  data_type: 'text'
  is_nullable: 0

=head2 location

  data_type: 'varchar'
  is_nullable: 0
  size: 64

=head2 location_id

  data_type: 'char'
  is_nullable: 0
  size: 22

=head2 type

  data_type: 'varchar'
  is_nullable: 0
  size: 64

=head2 contact

  data_type: 'text'
  is_nullable: 0

=head2 inserted_at

  data_type: 'integer'
  extra: {unsigned => 1}
  is_nullable: 0

=head2 extra

  data_type: 'text'
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "id",
  { data_type => "char", is_nullable => 0, size => 22 },
  "source_url",
  { data_type => "varchar", is_nullable => 0, size => 255 },
  "title",
  { data_type => "varchar", is_nullable => 0, size => 128 },
  "company_id",
  { data_type => "char", is_nullable => 0, size => 22 },
  "posted_at",
  {
    data_type => "datetime",
    datetime_undef_if_invalid => 1,
    is_nullable => 0,
  },
  "expired_at",
  {
    data_type => "datetime",
    datetime_undef_if_invalid => 1,
    is_nullable => 0,
  },
  "description",
  { data_type => "text", is_nullable => 0 },
  "location",
  { data_type => "varchar", is_nullable => 0, size => 64 },
  "location_id",
  { data_type => "char", is_nullable => 0, size => 22 },
  "type",
  { data_type => "varchar", is_nullable => 0, size => 64 },
  "contact",
  { data_type => "text", is_nullable => 0 },
  "inserted_at",
  { data_type => "integer", extra => { unsigned => 1 }, is_nullable => 0 },
  "extra",
  { data_type => "text", is_nullable => 0 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");

=head1 UNIQUE CONSTRAINTS

=head2 C<source_url>

=over 4

=item * L</source_url>

=back

=cut

__PACKAGE__->add_unique_constraint("source_url", ["source_url"]);


# Created by DBIx::Class::Schema::Loader v0.07035 @ 2013-08-15 18:56:42
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:Cns8cXkiNVd4RgEA6Bswaw

__PACKAGE__->belongs_to(
    company => 'Company',
    { 'foreign.id' => 'self.company_id' }
);

use FindmJob::Utils 'seo_title';
sub url {
    my ($self) = @_;

    return "/job/" . $self->id . "/" . seo_title($self->title) . ".html";
}

sub tags {
    my ($self) = @_;

    my $schema = $self->result_source->schema;
    return [ $schema->resultset('ObjectTag')->get_tags_by_object($self->id) ];
}

# extra data
use JSON::XS;
sub extra_data {
    my $extra = (shift)->extra;
    return ($extra and $extra =~ /^\{/) ? JSON::XS->new->utf8->decode($extra) : {};
}

1;
