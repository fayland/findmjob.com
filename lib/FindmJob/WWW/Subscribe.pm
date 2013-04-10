package FindmJob::WWW::Subscribe;

use Mojo::Base 'Mojolicious::Controller';
use Digest::MD5 'md5_hex';

sub subscribe {
    my $self = shift;

    my $keyword = $self->param('keyword');
    my $frm = $self->param('frm') || 'search';
    $frm = 'search' unless grep { $_ eq $frm } ('search', 'tag', 'company');
    my $loc = $self->param('loc') || '';
    my $frequency_days = $self->param('frequency_days');
    $frequency_days = 1 unless $frequency_days and $frequency_days eq '7';
    my $email = $self->param('email');

    # we do not validate email now, instead, we drop invalid email in cron when started
    if ($email and $keyword) {
        my $schema = $self->schema;
        my $r = $schema->resultset('Subscriber')->create( {
            email => $email,
            frm   => $frm,
            keyword => $keyword,
            loc => $loc,
            frequency_days => $frequency_days,
            created_at => time(),
            last_sent => 0,
            is_active => 0,
        } );
        $self->stash(subscriber => $r);
    }

    $self->render(template => 'subscribe');
}

sub confirm {
    my $self = shift;

    my $id   = $self->param('id');
    my $hash = $self->param('hash');

    my $suc = 0;
    if ($id and $hash) {
        ## check cron/emails/subscribe_confirm.pl
        my $config = $self->sconfig;
        my $sec = md5_hex($id . $config->{secret_hash});
        if ($hash eq $sec) {
            $suc = 1;
            my $schema = $self->schema;
            $schema->resultset('Subscriber')->search( { id => $id } )->update( { is_active => 1 } );
        }
    }
    $self->stash(suc => $suc);

    $self->render(template => 'subscribe_confirm');
}

1;