package FindmJob::WWW;
use Dancer ':syntax';

our $VERSION = '0.1';

use FindmJob::Basic;

# different template dir than default one
setting 'views'  => path( FindmJob::Basic->root, 'templates' );
setting 'public' => path( FindmJob::Basic->root, 'static' );

get '/' => sub {
    template 'index';
};

true;
