package PnwQuizzing::Control::Main;
use Mojo::Base 'Mojolicious::Controller', -signatures;
use parent 'PnwQuizzing';
use Mojo::Asset::File;
use Text::Markdown 'markdown';
use Text::CSV_XS 'csv';
use Role::Tiny::With;

with 'PnwQuizzing::Role::Secret';

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

    if ( $type eq 'md' or $type eq 'csv' ) {
        my $payload = $self->transcode( $asset->slurp );

        return $self->stash( html => markdown($payload) ) if ( $type eq 'md' );
        return $self->stash( csv => csv( in => \$payload ) ) if ( $type eq 'csv' );
    }

    my ($filename) = $file =~ /\/([^\/]+)$/;
    my $content_type = $self->app->types->type($type) || 'application/x-download';

    my $headers = Mojo::Headers->new;
    $headers->add( 'Content-Type'   => $content_type . ';name=' . $filename );
    $headers->add( 'Content-Length' => $asset->size                         );

    $self->res->content->headers($headers);
    $self->res->content->asset($asset);
    return $self->rendered(200);
}

1;
