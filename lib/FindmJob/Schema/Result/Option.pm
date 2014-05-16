use utf8;
package FindmJob::Schema::Result::Option;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

FindmJob::Schema::Result::Option

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<options>

=cut

__PACKAGE__->table("options");

=head1 ACCESSORS

=head2 k

  data_type: 'varchar'
  is_nullable: 0
  size: 32

=head2 v

  data_type: 'text'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "k",
  { data_type => "varchar", is_nullable => 0, size => 32 },
  "v",
  { data_type => "text", is_nullable => 1 },
);

=head1 PRIMARY KEY

=over 4

=item * L</k>

=back

=cut

__PACKAGE__->set_primary_key("k");


# Created by DBIx::Class::Schema::Loader v0.07039 @ 2014-05-16 16:29:14
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:LPC5OAB0URdhT6QewLw2Wg


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
