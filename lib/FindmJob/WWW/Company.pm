package FindmJob::WWW::Company;

use Mojo::Base 'Mojolicious::Controller';
use JSON;
use FindmJob::Email 'sendmail';

sub index {
    my $self = shift;

    my $schema = $self->schema;
    my $companyid = $self->stash('id');

    my $company = $schema->resultset('Company')->find($companyid);
    $self->stash(company => $company);

    unless ($company) {
        $self->res->code(410); # Gone
        return $self->render(template => 'gone', object => 'company');
    }

    my $job_rs = $schema->resultset('Job')->search( {
        company_id => $companyid
    }, {
        order_by => 'inserted_at DESC',
        rows => 12,
        page => 1
    });
    $self->stash(jobs => [ $job_rs->all ]);

    my $review_rs = $schema->resultset('CompanyReview')->search( {
        company_id => $companyid
    }, {
        order_by => 'inserted_at DESC',
        rows => 12,
        page => 1
    });
    $self->stash(reviews => [ $review_rs->all ]);
}

sub jobs {
    my $self = shift;

    my $schema = $self->schema;
    my $companyid = $self->stash('id');

    my $company = $schema->resultset('Company')->find($companyid);
    $self->stash(company => $company);

    my $p = $self->stash('page');
    $p = 1 unless $p and $p =~ /^\d+$/;
    my $job_rs = $schema->resultset('Job')->search( {
        company_id => $companyid
    }, {
        order_by => 'inserted_at DESC',
        rows => 12,
        page => $p
    });
    $self->stash(pager => $job_rs->pager);
    $self->stash(jobs  => [ $job_rs->all ]);
}

sub correct {
    my $self = shift;

    my $schema = $self->schema;
    my $companyid = $self->stash('id');

    my $company = $schema->resultset('Company')->find($companyid);
    $self->stash(company => $company);

    if ($self->req->method eq 'POST') {
        my $params = $self->req->body_params->to_hash;

        my @errors;
        $self->recaptcha;
        push @errors, $self->stash('recaptcha_error') if $self->stash('recaptcha_error');

        if (@errors) {
            $self->stash('errors' => \@errors);
            return;
        }

        # create
        delete $params->{recaptcha_response_field};
        delete $params->{recaptcha_challenge_field};
        $schema->resultset('CompanyCorrection')->create( {
            company_id => $companyid,
            data => $params,
        } );

        # sendmail
        use Data::Dumper;
        sendmail( {
            to => $self->sconfig->{email}->{default_to},
            subject => 'Correction for ' . $company->name,
            body => Dumper(\$params), # FIXME
        } );

        $self->flash('message' => "Correction sent, we'll review it asap, Thanks for your contribution.");
        return $self->redirect_to('/company/' . $companyid);
    }
}

1;