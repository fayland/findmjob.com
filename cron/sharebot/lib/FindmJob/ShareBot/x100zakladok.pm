package FindmJob::ShareBot::x100zakladok;

use Moose;
use namespace::autoclean;
with 'FindmJob::ShareBot::Role';
with 'FindmJob::Role::UA';

has '+ua_args'  => (is => 'rw', isa => 'HashRef', default => sub { {
    agent => 'Mozilla/4.0 (compatible; MSIE 7.0; Windows NT 6.0; Trident/5.0)',
    cookie_jar => {},
} });

has 'login' => ( is => 'rw', isa => 'Bool', lazy_build => 1 );
sub _build_login {
    my $self = shift;

    my $config = $self->config;
    my $t = $config->{share}->{'100zakladok'};

    # login
    my $resp = $self->ua->post('http://www.100zakladok.ru/login/', [
        ln  => $t->{u},
        lp  => $t->{p},
        mem => 1,
        su2 => 'B',
    ]);
    $self->log_fatal("# [x100zakladok] Login failed???") unless $resp->decoded_content =~ /Redirect\(/;
    return 1;
};

sub share {
    my ($self, $job) = @_;

    $self->login; # once login, will not to try login again

    my @tags = @{ $job->tags };
    @tags = map { $_->{text} } @tags;
    @tags = $self->remove_useless_tags(@tags);
    push @tags, 'findmjob', 'job';

    my $config = $self->config;
    my $u = $config->{share}->{'100zakladok'}->{u};
    my $resp = $self->ua->post("http://www.100zakladok.ru/$u/", [
        bm_url_1 => $config->{sites}->{main} . $job->url,
        title_1 => $job->title,
        id_cat_1 => 1, # default
        tags_1 => join(', ', @tags),
        id_bm_1 => 0,
        form_type => 1,
        id_form => 1,
        add_proc => '%C4%EE%E1%E0%E2%E8%F2%FC+%E7%E0%EA%EB%E0%E4%EA%F3',
    ] );
    my $job_id = $job->id;
    my $st = ($resp->is_success and $resp->decoded_content =~ /$job_id/) ? 1 : 0;
    $self->log_debug("# added " . $job->url . " $st");
    return $st;
}

__PACKAGE__->meta->make_immutable;

1;