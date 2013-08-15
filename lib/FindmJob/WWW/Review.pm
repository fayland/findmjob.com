package FindmJob::WWW::Review;

use Mojo::Base 'Mojolicious::Controller';
use Mojo::JSON;

sub company_review_new {
    my $self = shift;

    my $schema = $self->schema;
    my $companyid = $self->stash('id');

    my $company = $schema->resultset('Company')->find($companyid);
    $self->stash(company => $company);

    if ($self->req->method eq 'POST') {
        my $role  = $self->param('role');
        my $title = $self->param('title');
        my $pros  = $self->param('pros');
        my $cons  = $self->param('cons');
        my $score = $self->param('score');

        my @errors;
        if (not length($title)) {
            push @errors, "Title is required.";
        }
        if (not length($pros)) {
            push @errors, "Pros is required.";
        }
        if (not length($cons)) {
            push @errors, "Cons is required.";
        }

        $self->recaptcha;
        push @errors, $self->stash('recaptcha_error') if $self->stash('recaptcha_error');

        if (@errors) {
            $self->stash('errors' => \@errors);
            return $self->render(template => 'company_review_new');
        }

        # create
        $schema->resultset('CompanyReview')->create( {
            title => $title,
            rating => $score || 0,
            pros => $pros,
            cons => $cons,
            role => $role,
            inserted_at => time(),
            company_id => $company->id,
        } );

        return $self->redirect_to('/company/' . $companyid);
    }

    $self->render(template => 'company_review_new');
}


1;