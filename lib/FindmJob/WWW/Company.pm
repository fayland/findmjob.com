package FindmJob::WWW::Company;

use Mojo::Base 'Mojolicious::Controller';
use JSON;
use FindmJob::Email 'sendmail';

sub index {
    my $c = shift;

    my $schema = $c->schema;
    my $companyid = $c->stash('id');

    my $company = $schema->resultset('Company')->find($companyid);
    $c->stash(company => $company);

    unless ($company) {
        $c->res->code(410); # Gone
        return $c->render(template => 'gone', object => 'company');
    }

    my $job_rs = $schema->resultset('Job')->search( {
        company_id => $companyid
    }, {
        order_by => 'inserted_at DESC',
        rows => 12,
        page => 1
    });
    $c->stash(jobs => [ $job_rs->all ]);

    my $review_rs = $schema->resultset('CompanyReview')->search( {
        company_id => $companyid
    }, {
        order_by => 'inserted_at DESC',
        rows => 12,
        page => 1
    });
    $c->stash(reviews => [ $review_rs->all ]);
}

sub jobs {
    my $c = shift;

    my $schema = $c->schema;
    my $companyid = $c->stash('id');

    my $company = $schema->resultset('Company')->find($companyid);
    $c->stash(company => $company);

    my $p = $c->stash('page');
    $p = 1 unless $p and $p =~ /^\d+$/;
    my $job_rs = $schema->resultset('Job')->search( {
        company_id => $companyid
    }, {
        order_by => 'inserted_at DESC',
        rows => 12,
        page => $p
    });
    $c->stash(pager => $job_rs->pager);
    $c->stash(jobs  => [ $job_rs->all ]);
}

sub correct {
    my $c = shift;

    my $schema = $c->schema;
    my $companyid = $c->stash('id');

    my $company = $schema->resultset('Company')->find($companyid);
    $c->stash(company => $company);

    if ($c->req->method eq 'POST') {
        my $params = $c->req->body_params->to_hash;

        my @errors;
        $c->recaptcha;
        push @errors, $c->stash('recaptcha_error') if $c->stash('recaptcha_error');

        if (@errors) {
            $c->stash('errors' => \@errors);
            return;
        }

        # create
        delete $params->{recaptcha_response_field};
        delete $params->{recaptcha_challenge_field};
        $schema->resultset('CompanyCorrection')->create( {
            company_id => $companyid,
            edited_by  => delete $params->{edited_by},
            data => $params,
        } );

        # sendmail
        use Data::Dumper;
        sendmail( {
            to => $c->sconfig->{email}->{default_to},
            subject => 'Correction for ' . $company->name,
            body => Dumper(\$params), # FIXME
        } );

        $c->flash('message' => "Correction sent, we'll review it asap, Thanks for your contribution.");
        return $c->redirect_to('/company/' . $companyid);
    }
}

1;