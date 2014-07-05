use utf8;
package FindmJob::Schema::Result::PeopleUrl;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

FindmJob::Schema::Result::PeopleUrl

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<people_url>

=cut

__PACKAGE__->table("people_url");

=head1 ACCESSORS

=head2 url

  data_type: 'varchar'
  is_nullable: 0
  size: 255

=head2 scraped_at

  data_type: 'integer'
  default_value: 0
  extra: {unsigned => 1}
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "url",
  { data_type => "varchar", is_nullable => 0, size => 255 },
  "scraped_at",
  {
    data_type => "integer",
    default_value => 0,
    extra => { unsigned => 1 },
    is_nullable => 0,
  },
);

=head1 PRIMARY KEY

=over 4

=item * L</url>

=back

=cut

__PACKAGE__->set_primary_key("url");


# Created by DBIx::Class::Schema::Loader v0.07039 @ 2014-07-05 20:05:06
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:BU3UL7F6vO7aj2cgut2acQ


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
