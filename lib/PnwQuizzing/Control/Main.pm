package PnwQuizzing::Control::Main;
use Mojo::Base 'Mojolicious::Controller', -signatures;
use parent 'PnwQuizzing';
use Mojo::Asset::File;
use Text::Markdown 'markdown';
use Text::CSV_XS 'csv';
use Role::Tiny::With;

with 'PnwQuizzing::Role::Secret';

sub home_page ($self) {
    my $asset = Mojo::Asset::File->new(
        path => $self->conf->get( qw( config_app root_dir ) ) . '/docs/index.md'
    );
    my $payload = ( $self->stash('user') ) ? $self->translate( $asset->slurp ) : $asset->slurp;
    my $title   = ( $payload =~ s/^#\s*([^#]+?)\s*$//ms ) ? $1 : '';

    $self->stash( payload => markdown($payload), title => $title );
}

sub content ($self) {
    my $file = join( '/', grep { defined }
        $self->conf->get( qw( config_app root_dir ) ),
        'docs',
        $self->stash('name'),
    );

    ( my $name = $self->stash('name') ) =~ s/\.[^\.\/]+$//;
    $self->stash( 'title' => join( ' / ',
        map {
            join( ' ', map { ucfirst } split('_') )
        } split( '/', $name )
    ) );

    $file .= '/index.md' unless ( -f $file );
    unless ( -f $file ) {
        $self->notice( '404 in Main content: ' . ( $self->stash('name') || '>undef<' ) );
        $self->app->renderer->default_handler('ep');
        return $self->reply->not_found;
    }

    my ($type) = lc($file) =~ /\.([^\.\/]+)$/;
    $type ||= '';

    my $asset = Mojo::Asset::File->new( path => $file );

    if ( not $self->param('download') and ( $type eq 'md' or $type eq 'csv' ) ) {
        my $payload = ( $self->stash('user') ) ? $self->translate( $asset->slurp ) : $asset->slurp;

        return $self->stash( html => markdown($payload) ) if ( $type eq 'md' );
        return $self->stash( csv => csv( in => \$payload ) ) if ( $type eq 'csv' );
    }

    my ($filename) = $file =~ /\/([^\/]+)$/;

    $self->res->headers->content_type(
        ( $self->app->types->type($type) || 'application/x-download' ) . ';name=' . $filename
    );
    $self->res->headers->content_length( $asset->size );
    $self->res->content->asset($asset);

    return $self->rendered(200);
}

1;
