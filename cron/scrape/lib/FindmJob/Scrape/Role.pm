package FindmJob::Scrape::Role;

use Moose::Role;

with 'FindmJob::Role::Basic';
with 'FindmJob::Role::UA';
with 'FindmJob::Role::TextFormatter';
with 'FindmJob::Role::Logger';

has 'opt_update' => ( is => 'ro', isa => 'Bool', default => '0' );

has 'language_regex' => ( is => 'ro', lazy_build => 1 );
sub _build_language_regex {
    my $self = shift;
    my $schema = $self->schema;
    my @tags = $schema->resultset('Tag')->search( { category => ['language', 'skill'] } )->all;
    @tags = map { $_->text } @tags;
    my $tags = join('|', map { quotemeta($_) } @tags);
    return $tags;
}
sub get_extra_tags_from_desc {
    my ($self, $desc) = @_;

    return unless $desc and length $desc;

    my $language_regex = $self->language_regex;
    my @tags = ($desc =~ /(?:^|[\s\,\/\(\)]+)($language_regex)(?:[\s\,\/\(\)\.]+|$)/isg);

    return @tags;
}

1;