package PnwQuizzing::Control::Main;
use exact 'Mojolicious::Controller', 'PnwQuizzing';
use Encode 'decode_utf8';
use Mojo::Asset::File;
use Mojo::JSON 'decode_json';
use Text::CSV_XS 'csv';
use Text::MultiMarkdown 'markdown';

with 'PnwQuizzing::Role::Secret';

sub home_page ($self) {
    my $asset = Mojo::Asset::File->new(
        path => $self->conf->get( qw( config_app root_dir ) ) . '/docs/index.md'
    );
    my $payload = decode_utf8( ( $self->stash('user') ) ? $self->translate( $asset->slurp ) : $asset->slurp );
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
    $name =~ s|/_|/|g;
    $self->stash( 'title' => join( ' / ',
        map {
            ucfirst( join( ' ', map {
                ( /^(?:a|an|the|and|but|or|for|nor|on|at|to|from|by)$/i ) ? $_ : ucfirst
            } split('_') ) )
        } split( '/', $name )
    ) );

    $file .= '/index.md' unless ( -f $file );

    unless ( -f $file ) {
        $self->notice( '404 in Main content: ' . ( $self->stash('name') || '>undef<' ) );

        my $default_handler = $self->app->renderer->default_handler;
        $self->app->renderer->default_handler('ep');
        $self->reply->not_found;
        $self->rendered(404);
        $self->app->renderer->default_handler($default_handler);
        return;
    }

    my ($type) = lc($file) =~ /\.([^\.\/]+)$/;
    $type ||= '';

    my $asset = Mojo::Asset::File->new( path => $file );

    if ( not $self->param('download') and ( $type eq 'md' or $type eq 'csv' ) ) {
        my $payload = decode_utf8(
            ( $self->stash('user') ) ? $self->translate( $asset->slurp ) : $asset->slurp
        );

        if ( $type eq 'md' ) {
            $payload =~ s|(\[[^\]]+\]\([^\)]+\.)(\w+)\)|
                my ( $x, $y, $z ) = map { $_ // '' } $1, $2, $3;

                my $ft   = lc $y;
                my $icon =
                    ( $ft eq 'pdf'  ) ? 'file-pdf'   :
                    ( $ft eq 'doc'  ) ? 'file-word'  :
                    ( $ft eq 'docx' ) ? 'file-word'  :
                    ( $ft eq 'xls'  ) ? 'file-excel' :
                    ( $ft eq 'xlsm' ) ? 'file-excel' :
                    ( $ft eq 'xlsx' ) ? 'file-excel' : undef;

                ($icon)
                    ? ( qq{$x$y) <i class="la la-} . $icon . q{-o"></i>} )
                    : "$x$y$z)";
            |eg;

            my $header_photos = $self->stash('header_photos');
            my $header_photo  = $header_photos->[ rand @$header_photos ];

            return $self->stash( html => markdown($payload), header_photo => $header_photo );
        }
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

sub git_push ($self) {
    my $payload = decode_json( $self->req->param('payload') );

    my $response;
    if ( $payload and $payload->{ref} and $payload->{ref} eq 'refs/heads/master' ) {
        if ( my $git_push_command = $self->conf->get( qw( git push ) ) ) {
            $self->notice('git push triggered release');
            $response = { action => 1, message => 'release', output => `$git_push_command` };
        }
        else {
            $self->notice('git push webhook called but no action taken');
            $response = { action => 2, message => 'no git push command in conf' };
        }
    }
    else {
        $self->notice('git push webhook called but not of ref master');
        $response = { action => 0, message => 'no action' };
    }

    return $self->render( json => { response => $response, payload => $payload } );
}

1;
