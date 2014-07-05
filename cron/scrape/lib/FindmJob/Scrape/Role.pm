package FindmJob::Scrape::Role;

use Moo::Role;
use FindmJob::Utils 'uuid';

with 'FindmJob::Role::Basic';
with 'FindmJob::Role::UA';
with 'FindmJob::Role::TextFormatter';
with 'FindmJob::Role::Logger';

has 'opt_update' => ( is => 'ro', default => sub { '0' } );

has 'language_regex' => ( is => 'lazy' );
sub _build_language_regex {
    my $self = shift;
    my $schema = $self->schema;
    my @tags = $schema->resultset('Tag')->search( { category => ['language', 'skill', 'software'] } )->all;
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