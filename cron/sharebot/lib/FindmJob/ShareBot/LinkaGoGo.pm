package FindmJob::ShareBot::LinkaGoGo;

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

    my $cookie_jar = $self->ua->cookie_jar;
    $cookie_jar->set_cookie(0, 'cookies', 'Y', '/', 'www.linkagogo.com', 80,0,0,86400,0);
    $cookie_jar->set_cookie(0, 'user', '1566009', '/', 'www.linkagogo.com', 80,0,0,86400,0);
    $cookie_jar->set_cookie(0, 'userName', 'findmjob', '/', 'www.linkagogo.com', 80,0,0,86400,0);
    $cookie_jar->set_cookie(0, 'LastFolder', '5306677', '/', 'www.linkagogo.com', 80,0,0,86400,0);
    $self->ua->cookie_jar($cookie_jar);

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
    my $resp = $self->ua->post("http://www.linkagogo.com/go/AddMenu", [
        url => $config->{sites}->{main} . $job->url,
        title => $job->title,
        keywords => join(', ', @tags),
        comments => '',
        alias => '',
        rating => 0,
        remind => '-9',
        target => 'null',
        folder => '5306677', # Home
        user   => 'findmjob',
        password => 'findjob',
        submit => 'Add'
    ] );

    my $job_id = $job->id;
    my $st = ($resp->is_success and $resp->decoded_content =~ /$job_id/ and $resp->decoded_content =~ /added/) ? 1 : 0;
    $self->log_debug("# added " . $job->url . " $st");
    return $st;
}

__PACKAGE__->meta->make_immutable;

1;