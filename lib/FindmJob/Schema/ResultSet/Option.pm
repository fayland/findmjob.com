package FindmJob::Schema::ResultSet::Option;

use Moo;
extends 'DBIx::Class::ResultSet';

use JSON::XS;

sub get {
    my ($self, $k) = @_;
    my $r = $self->find($k);
    return decode_json($r->v) if $r and $r->v =~ /^[\{\[]/; # simple check
    return $r->v if $r;
    return;
}

sub set {
    my ($self, $k, $v) = @_;

    $self->update_or_create({
        k => $k,
        v => ref($v) ? encode_json($v) : $v
    });
}

1;