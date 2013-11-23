package FindmJob::Role::Basic;

use Moo::Role;

use FindmJob::Basic;
sub root { FindmJob::Basic->root }
sub config { FindmJob::Basic->config }
sub schema { FindmJob::Basic->schema }
sub dbh { FindmJob::Basic->dbh }

1;