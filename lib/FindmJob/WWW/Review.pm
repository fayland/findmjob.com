package FindmJob::WWW::Review;

use Mojo::Base 'Mojolicious::Controller';

sub review {
    my $c = shift;

    my $schema = $c->schema;
    my $companyid = $c->stash('cid');
    my $reviewid = $c->stash('rid');

    my $review = $schema->resultset('CompanyReview')->find($reviewid);
    my $company = $schema->resultset('Company')->find($companyid);
    $c->stash(company => $company);
    $c->stash(review  => $review);

    $c->render(template => 'review');
}

sub company_reviews {
    my $c = shift;

    my $schema = $c->schema;
    my $companyid = $c->stash('id');

    my $company = $schema->resultset('Company')->find($companyid);
    $c->stash(company => $company);

    my $p = $c->stash('page');
    $p = 1 unless $p and $p =~ /^\d+$/;
    my $review_rs = $schema->resultset('CompanyReview')->search( {
        company_id => $companyid
    }, {
        order_by => 'inserted_at DESC',
        rows => 12,
        page => $p
    });
    $c->stash(pager => $review_rs->pager);
    $c->stash(reviews => [ $review_rs->all ]);

    $c->render(template => 'company_reviews');
}

sub company_review_new {
    my $c = shift;

    my $schema = $c->schema;
    my $companyid = $c->stash('id');

    my $company = $schema->resultset('Company')->find($companyid);
    $c->stash(company => $company);

    if ($c->req->method eq 'POST') {
        my $role  = $c->param('role');
        my $title = $c->param('title');
        my $pros  = $c->param('pros');
        my $cons  = $c->param('cons');
        my $score = $c->param('score');

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

        $c->recaptcha;
        push @errors, $c->stash('recaptcha_error') if $c->stash('recaptcha_error');

        if (@errors) {
            $c->stash('errors' => \@errors);
            return $c->render(template => 'company_review_new');
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

        return $c->redirect_to('/company/' . $companyid);
    }

    $c->render(template => 'company_review_new');
}


1;