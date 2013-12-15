package FindmJob::WWWAdmin::CompanyCorrection;

use Mojo::Base 'Mojolicious::Controller';

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
			$data->{$k} = $params->{"data[$k]"};
		}
		$company->data($data);
		$company->update();

		$correction->is_reviewed(1);
		$correction->update();

		$self->stash('message' => 'Saved.');
	}

	$self->stash(correction => $correction);
    $self->stash(company => $company);

	$self->render(template => 'companycorrection/edit');
}

1;