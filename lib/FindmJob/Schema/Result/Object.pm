use utf8;
package FindmJob::Schema::Result::Object;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

FindmJob::Schema::Result::Object

=cut

use strict;
use warnings;

use Moose;
use MooseX::NonMoose;
use MooseX::MarkAsMethods autoclean => 1;
extends 'DBIx::Class::Core';

=head1 TABLE: C<object>

=cut

__PACKAGE__->table("object");

=head1 ACCESSORS

=head2 id

  data_type: 'varchar'
  is_nullable: 0
  size: 32

=head2 tbl

  data_type: 'varchar'
  is_nullable: 0
  size: 12

=cut

__PACKAGE__->add_columns(
  "id",
  { data_type => "varchar", is_nullable => 0, size => 32 },
  "tbl",
  { data_type => "varchar", is_nullable => 0, size => 12 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");


# Created by DBIx::Class::Schema::Loader v0.07019 @ 2012-03-31 23:20:26
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:lnw1bmu6II3hWmEK1feFVQ


# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
