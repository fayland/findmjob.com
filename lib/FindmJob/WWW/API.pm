package FindmJob::WWW::API;

use Mojo::Base 'Mojolicious::Controller';
use JSON::XS 'encode_json';
use URI;
use Mojo::UserAgent;
use Mojo::Util qw/xml_escape/;

sub __raise {
    my ($c, $err) = @_;

    $c->render(json => {status => 0, error => $err});
}

sub POST_job {
    my $c = shift;

    __post($c, 'Job');
}

sub __post {
    my ($c, $table) = @_;

    my $schema = $c->schema;

    my $app_id     = $c->param('app_id');
    return __raise($c, "Param app_id is required.") unless $app_id;

    my $app = $schema->resultset('App')->find($app_id);
    return __raise($c, "App is not found.") unless $app;
    return __raise($c, "App is not verified.") unless $app->is_verified;
    return __raise($c, "App is disabled, please contact us.") unless $app->is_disabled;

    my $source_url = $c->param('url');
    return __raise($c, "Param url is required.") unless $source_url;

    my $uri = URI->new($source_url);
    return __raise($c, "URL is not valid") unless $uri and $uri->can('host');
    my $source_host = $uri->host;
    return __raise($c, "You're only allowed post url from " . $app->website) unless $source_host eq $app->website;

    # test url valid
    my $ua = Mojo::UserAgent->new;
    $ua->max_redirects(3);
    $ua->inactivity_timeout(30);
    my $tx = $ua->get($source_url);
    unless ($tx->success) {
        return __raise($c, "Failed to fetch $source_url: " . $tx->res->error->{message});
    }

    my $title = $c->param('title');
    return __raise($c, "Param title is required.") unless $title;
    my $description = $c->param('description');
    return __raise($c, "Param description is required.") unless $description;

    $title = xml_escape($title);
    $description = __format_text($description);

    my $tags = $c->param('tags');
    my @tags = ref($tags) eq 'ARRAY' ? @$tags : split(/\s*\,\s*/, $tags);
    @tags = map { xml_escape($_) } @tags;

    my $row = {
        source_url => $source_url,
        title => $title,
        description => $description,
        tags  => \@tags
    };

    if ($table eq 'Job') {
        if (my $company_name = $c->param('company_name')) {
            $row->{company}->{name} = xml_escape($company_name);
        }
        if (my $company_website = $c->param('company_website')) {
            $row->{company}->{website} = $company_website;
        }
        if (my $contact = $c->param('contact')) {
            $row->{contact} = xml_escape($contact);
        }
        if (my $type = $c->param('type')) {
            $row->{type} = xml_escape($type);
        }
        if (my $location = $c->param('location')) {
            $row->{location} = xml_escape($location);
        }

        if (my $posted_at = $c->param('posted_at')) {
            if (is_valid_datetime($posted_at)) {
                $row->{posted_at} = $posted_at;
            }
        }
        $row->{posted_at} ||= \"NOW()";
    }

    my $job_row;
    my $rs = $schema->resultset($table);
    my $is_inserted = $rs->is_inserted_by_url($row->{source_url});
    if ( $is_inserted ) {
        $rs->update_job($row);
        $job_row = $rs->search({ source_url => $row->{source_url} })->first;
    } else {
        $job_row = $rs->create_job($row);
    }

    $c->render(json => { status => 1, id => $job_row->id });
}

use HTML::TreeBuilder;
use FindmJob::HTML::FormatText;
sub __format_text {
    my $text = shift;

    my $formatter = FindmJob::HTML::FormatText->new(leftmargin => 0, rightmargin => 999);
    my $tree = HTML::TreeBuilder->new_from_content($text);
    my $txt = $self->formatter->format($ele);

    my $x100 = '-' x 100;
    $txt =~ s/\-{80,}/$x100/sg;
    $txt =~ s/^\s+|\s+$//g;
    $txt =~ s/\n{3,}/\n\n/g;
    $txt =~ s/\xA0/ /g;

    $tree = $tree->delete;

    return $txt;
}

sub is_valid_datetime {
    my $s = shift;
    return ($s =~ /^20\d{2}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}$/);
}

1;