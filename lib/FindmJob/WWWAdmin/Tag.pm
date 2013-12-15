package FindmJob::WWWAdmin::Tag;

use Mojo::Base 'Mojolicious::Controller';

sub index {
	my $self = shift;

	my $schema = $self->schema;

	if ($self->req->method eq 'POST') {
		my $category = $self->param('category');
		my $text = $self->param('text');

		my $rs = $schema->resultset('Tag')->search( {
			($category) ? (category => $category) : (),
			($text) ? (text => { 'LIKE', '%' . $text . '%' }) : (),
		});
		$self->stash(tags => [$rs->all]);
	}
}

sub edit {
	my $self = shift;

	my $schema = $self->schema;

	my $id = $self->param('id');
	my $tag = $schema->resultset('Tag')->find($id);

	if ($self->req->method eq 'POST') {
		my $params = $self->req->body_params->to_hash;
		$tag->text($params->{text});
		$tag->category($params->{category});
		my $data = $tag->data || {};
		foreach my $i ('logo', 'url', 'desc') {
			$data->{$i} = $params->{"data[$i]"};
		}
		$tag->data($data);
		$tag->update();
		$self->stash('message' => 'Saved.');
	}

	$self->stash(tag => $tag);
}

1;