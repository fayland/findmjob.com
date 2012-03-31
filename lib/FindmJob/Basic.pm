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

use DBI; use Carp;
use DBIx::Connector;
has 'conn' => ( is => 'ro', lazy_build => 1 );
sub _build_conn {
    my $self = shift;
    return DBIx::Connector->new( @{ $self->config->{DBI} } );
}
has 'dbh' => (is => 'ro', lazy_build => 1);
sub _build_dbh {
    my $self = shift;
    my $dbh = $self->conn->dbh or croak $DBI::errstr;
    $dbh->{mysql_enable_utf8} = 1; $dbh->do("set names 'utf8';");
    return $dbh;
}

1;
