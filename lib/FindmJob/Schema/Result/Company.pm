use utf8;
package FindmJob::Schema::Result::Company;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

FindmJob::Schema::Result::Company

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<company>

=cut

__PACKAGE__->table("company");

=head1 ACCESSORS

=head2 id

  data_type: 'char'
  is_nullable: 0
  size: 22

=head2 name

  data_type: 'varchar'
  is_nullable: 0
  size: 128

=head2 website

  data_type: 'varchar'
  is_nullable: 0
  size: 128

=head2 ref

  data_type: 'varchar'
  is_nullable: 0
  size: 32

=head2 extra

  data_type: 'text'
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "id",
  { data_type => "char", is_nullable => 0, size => 22 },
  "name",
  { data_type => "varchar", is_nullable => 0, size => 128 },
  "website",
  { data_type => "varchar", is_nullable => 0, size => 128 },
  "ref",
  { data_type => "varchar", is_nullable => 0, size => 32 },
  "extra",
  { data_type => "text", is_nullable => 0 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");


# Created by DBIx::Class::Schema::Loader v0.07035 @ 2013-08-15 18:56:42
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:iTHWzl5mceJKPlVq6fhNaw

use FindmJob::Utils 'seo_title';
sub url {
    my ($self) = @_;

    return "/company/" . $self->id . "/" . seo_title($self->name) . ".html";
}

# alias title as name
sub title { (shift)->name }

# extra data
use Mojo::JSON;
sub extra_data {
    my $extra = (shift)->extra;
    return ($extra and $extra =~ /^\{/) ? Mojo::JSON->new->decode($extra) : {};
}

1;
