package FindmJob::WWWAdmin::CompanyCorrection;

use Mojo::Base 'Mojolicious::Controller';
use FindmJob::Email 'sendmail';

sub index {
	my $self = shift;

	my $schema = $self->schema;

	$self->stash(
		corrections => [ $schema->resultset('CompanyCorrection')->search({ is_reviewed => 0 })->all ],
	);

	$self->render(template => 'companycorrection/index');
}

sub edit {
	my $self = shift;

	my $schema = $self->schema;

	my $id = $self->param('id');
	my $correction = $schema->resultset('CompanyCorrection')->find($id);
	my $company = $schema->resultset('Company')->find($correction->company_id);

	if ($self->req->method eq 'POST') {
		my $params = $self->req->body_params->to_hash;

		my $data = $company->data || {};
		$company->website($params->{website}) if $params->{website};
		foreach my $k ('employeeCountRange', 'desc', 'foundedYear', 'facebookId', 'twitterId', 'googleplusId', 'linkedinId', 'githubId') {
			next unless exists $params->{"data[$k]"};
			my $v = $params->{"data[$k]"};
			$v =~ s{https?://(www.)?(facebook|twitter|linkedin|github).com/}{}i if $k =~ /Id$/;
			$v =~ s{https://plus.google.com/u/0/}{}i if $k eq 'googleplusId';
			$data->{$k} = $v;
		}
		$company->data($data);
		$company->update();

		$correction->is_reviewed(1);
		$correction->update();

		if ($correction->edited_by) {
			my $company_url = $company->url;
			sendmail( {
	            to => $correction->edited_by,
	            subject => '[Findmjob.com] Correction for ' . $company->name . ' Applied',
	            body => <<'B',
Hi

Thanks for your contribution. and your changes are applied. Please take a look at
$company_url
B
	        } );
		}

		$self->stash('message' => 'Saved.');
	}

	$self->stash(correction => $correction);
    $self->stash(company => $company);

	$self->render(template => 'companycorrection/edit');
}

1;