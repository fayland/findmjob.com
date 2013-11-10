package FindmJob::ShareBot::GooglePlus;

use Moo;
with 'FindmJob::ShareBot::Role';
with 'FindmJob::Role::Shorten';

use List::Util 'shuffle';

sub share {
    my ($self, $job) = @_;

    my @tags = @{ $job->tags };
    @tags = map { $_->{text} } @tags;
    @tags = $self->remove_useless_tags(@tags);
    @tags = map { s/[\&\#\+\s\.\-\'\"]+//g; $_ } @tags; # no &, # in tags
    @tags = grep { length($_) and $_ ne 'c' } @tags;
    @tags = shuffle @tags; # shuffle should work better so every tag has the chance
    @tags = splice(@tags, 0, 2);
    push @tags, 'jobs', 'hiring', 'careers';
    @tags = map { '+' . $_ } @tags;
    my $tags = join(' ', @tags);

    my $config = $self->config;
    my $url = $config->{sites}->{main} . $job->url;
    my $shorten_url = $self->shorten($url);

    my $left_len = 140 - (length($tags) + length($shorten_url) + 2);
    my $title = $job->title;
    $title = substr($title, 0, $left_len - 3) . '...' if length($title) > $left_len;

    my $t = $config->{share}->{GooglePlus};
    my $root = $self->root;
    my $username = $t->{email};
    my $password = $t->{password};

    my $casperjs  = "$root/bin/casperjs/bin/casperjs";
    my $js_file   = "$root/bin/googleplus.js";

    my $update = "$title $shorten_url $tags";
    $self->log_debug("# ++ $update");

    my $command = qq~$casperjs $js_file --username=$username --password=$password --text="$update"~;
    my $out = `$command 2>&1`;
    $self->log_debug( "# out: $out" );

    return ($out =~ /Posted to google/i) ? 1: 0;
}

1;