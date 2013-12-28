use utf8;
package FindmJob::Schema::Result::UserFollow;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

FindmJob::Schema::Result::UserFollow

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<user_follow>

=cut

__PACKAGE__->table("user_follow");

=head1 ACCESSORS

=head2 user_id

  data_type: 'char'
  is_nullable: 0
  size: 22

=head2 follow_id

  data_type: 'char'
  is_nullable: 0
  size: 22

=cut

__PACKAGE__->add_columns(
  "user_id",
  { data_type => "char", is_nullable => 0, size => 22 },
  "follow_id",
  { data_type => "char", is_nullable => 0, size => 22 },
);

=head1 PRIMARY KEY

=over 4

=item * L</follow_id>

=item * L</user_id>

=back

=cut

__PACKAGE__->set_primary_key("follow_id", "user_id");


# Created by DBIx::Class::Schema::Loader v0.07038 @ 2013-12-28 19:30:31
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:JK0WdMDNi5tF9eahO1x4yw


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
