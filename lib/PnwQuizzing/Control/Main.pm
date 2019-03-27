package PnwQuizzing::Control::Main;
use Mojo::Base 'Mojolicious::Controller', -signatures;
use parent 'PnwQuizzing';
use Role::Tiny::With;
use Mojo::Asset::File;
use Text::Markdown 'markdown';
use Text::CSV_XS 'csv';
use PnwQuizzing::Model::User;
use TryCatch;

with 'PnwQuizzing::Role::DocsNav';

sub content ($self) {
    my $file = join( '/', grep { defined }
        $self->conf->get( qw( config_app root_dir ) ),
        'docs',
        $self->stash('name'),
    );

    $file .= '/index.md' unless ( -f $file );
    unless ( -f $file ) {
        $self->notice( '404 in Main content: ' . ( $self->stash('name') || '>undef<' ) );
        $self->app->renderer->default_handler('ep');
        return $self->reply->not_found;
    }

    my ($type) = lc($file) =~ /\.([^\.\/]+)$/;
    $type ||= '';

    my $asset = Mojo::Asset::File->new( path => $file );

    $self->stash( docs_nav => $self->generate_docs_nav ) if ( $type eq 'md' or $type eq 'csv' );

    return $self->stash( html => markdown( $asset->slurp ) ) if ( $type eq 'md' );
    return $self->stash( csv => csv( in => $file ) ) if ( $type eq 'csv' );

    my ($filename) = $file =~ /\/([^\/]+)$/;
    my $content_type = $self->app->types->type($type) || 'application/x-download';

    my $headers = Mojo::Headers->new;
    $headers->add( 'Content-Type'   => $content_type . ';name=' . $filename );
    $headers->add( 'Content-Length' => $asset->size                         );

    $self->res->content->headers($headers);
    $self->res->content->asset($asset);
    return $self->rendered(200);
}

sub login ($self) {
    my $user = PnwQuizzing::Model::User->new;

    try {
        $user = $user->login( map { $self->param($_) } qw( username passwd ) );
    }
    catch {
        $self->info('Login failure (in controller)');
        $self->flash( message => "Login failed. Please try again." );
        return $self->redirect_to('/');
    }

    $self->info( 'Login success for: ' . $user->prop('username') );

    $self->session(
        'user_id'           => $user->id,
        'last_request_time' => time,
    );

    return $self->redirect_to('/');
}

sub logout ($self) {
    $self->info(
        'Logout requested from: ' .
        ( ( $self->stash('user') ) ? $self->stash('user')->prop('username') : '(Unlogged-in user)' )
    );
    $self->session(
        'user_id'           => undef,
        'last_request_time' => undef,
    );

    return $self->redirect_to('/');
}

1;
