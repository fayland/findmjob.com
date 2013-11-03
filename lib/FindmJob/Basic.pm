package FindmJob::Basic;

use strict;
use warnings;
use File::Spec; use Cwd qw/abs_path/;
sub root {
    my ( undef, $path ) = File::Spec->splitpath(__FILE__);
    return abs_path( File::Spec->catdir( $path, '..', '..' ) );
}

use Mojo::Util 'slurp';
use JSON::XS;
my $__config;
sub config {
    return $__config if $__config;

    my $root = root();

    my $json  = JSON::XS->new;
    $__config = $json->decode( slurp( File::Spec->catfile($root, 'conf', 'findmjob.json') ) );
    my $local_config_file = File::Spec->catfile($root, 'conf', 'findmjob_local.json');
    if (-e $local_config_file) {
        my $local_config = $json->decode( slurp($local_config_file) );
        $__config = { %$__config, %$local_config }; # simple hash merge
    }
    return $__config;
}

use FindmJob::Schema;
my $__schema;
sub schema {
    return $__schema if $__schema;

    my $config = config();
    $__schema = FindmJob::Schema->connect( @{ $config->{DBI} } );
    $__schema->storage->dbh->{mysql_enable_utf8} = 1;
    $__schema->storage->dbh->do("SET names utf8");
    return $__schema;
}
sub dbh {
    my $schema = schema();
    return $schema->storage->dbh;
}

# we may have standalone database later, but not now
sub dbh_log { dbh() }

1;
