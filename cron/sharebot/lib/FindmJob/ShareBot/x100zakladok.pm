package FindmJob::ShareBot::x100zakladok;

use Moose;
use namespace::autoclean;
with 'FindmJob::ShareBot::Role';
with 'FindmJob::Role::UA';

sub share {
    my ($self, $job) = @_;

    my $config = $self->config;
    my $t = $config->{share}->{'100zakladok'};

    my @tags = @{ $job->tags };
    @tags = map { $_->{text} } @tags;
    @tags = $self->remove_useless_tags(@tags);
    push @tags, 'findmjob', 'job';

    my $config = $self->config;
    my $resp = $self->ua->post('http://www.100zakladok.ru/save/', [
        ln  => $t->{u},
        lp  => $t->{p},
        bm_url => $config->{sites}->{main} . $job->url,
        bm_title => $job->title
    ] );
    my $st = $resp->is_success ? 1 : 0;
    print $resp->decoded_content;
    $self->log_debug("# added " . $job->url . " $st");

    return $st;
}

__PACKAGE__->meta->make_immutable;

1;