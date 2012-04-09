package FindmJob::Basic;

use MooseX::Singleton;

use File::Spec; use Cwd qw/abs_path/;
has 'root' => ( is => 'ro', isa => 'Str', lazy_build => 1 );
sub _build_root {
    my ( undef, $path ) = File::Spec->splitpath(__FILE__);
    return abs_path( File::Spec->catdir( $path, '..', '..' ) );
}

use YAML::Any ();
has 'config' => ( is => 'ro', isa => 'HashRef', lazy_build => 1 );
sub _build_config {
    my $self = shift;
    my $config = YAML::Any::LoadFile( File::Spec->catfile($self->root, 'conf', 'findmjob.yml') );
    my $local_config_file = File::Spec->catfile($self->root, 'conf', 'findmjob_local.yml');
    if (-e $local_config_file) {
        my $local_config = YAML::Any::LoadFile($local_config_file);
        $config = { %$config, %$local_config }; # simple hash merge
    }
    return $config;
}

use FindmJob::Schema;
has 'schema' => ( is => 'ro', lazy_build => 1 );
sub _build_schema {
    my $self = shift;
    my $schema = FindmJob::Schema->connect( @{ $self->config->{DBI} } );
    $schema->storage->dbh->{mysql_enable_utf8} = 1;
    $schema->storage->dbh->do("SET names utf8");
    return $schema;
}
has 'dbh' => (is => 'ro', lazy_build => 1);
sub _build_dbh {
    my $self = shift;
    return $self->schema->storage->dbh;
}

# we may have standalone database later, but not now
sub dbh_log { (shift)->dbh }

1;
