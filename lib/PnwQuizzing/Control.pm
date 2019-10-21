package PnwQuizzing::Control;
use exact 'Mojolicious', 'PnwQuizzing';
use CSS::Sass;
use File::Path 'make_path';
use Mojo::File;
use Mojo::Loader 'load_class';
use MojoX::Log::Dispatch::Simple;
use PnwQuizzing::Model::User;
use PnwQuizzing::Model::Register;

with qw( PnwQuizzing::Role::Template PnwQuizzing::Role::DocsNav );

sub startup ($self) {
    my $root_dir = $self->conf->get( 'config_app', 'root_dir' );

    $self->plugin('RequestBase');

    $self->build_css($root_dir);
    $self->setup_mojo_logging;
    $self->setup_templating($root_dir);
    $self->setup_session_login;

    $self->static->paths->[0] =~ s|/public$|/static|;
    $self->config( $self->conf->get( 'mojolicious', 'config' ) );
    $self->secrets( $self->conf->get( 'mojolicious', 'secrets' ) );
    $self->sessions->cookie_name( $self->conf->get( qw( mojolicious session cookie_name ) ) );
    $self->sessions->default_expiration( $self->conf->get( qw( mojolicious session default_expiration ) ) );

    if ( $self->mode eq 'production' ) {
        load_class( 'PnwQuizzing::Control::' . $_ ) for qw( Main Tool User );
    }

    $self->hook( 'before_dispatch' => sub ($self) { $self->session_login } );

    $self->hook( 'after_dispatch' => sub ($self) {
        my $url = $self->req->url->to_string;

        if ( $url =~ m|^/downloads/| ) {
            my ($type) = lc($url) =~ /\.([^\.\/]+)$/;
            $type ||= '';
            my ($filename) = $url =~ /\/([^\/]+)$/;

            $self->res->headers->content_type(
                ( $self->app->types->type($type) || 'application/x-download' ) . ';name=' . $filename
            );
        }
    } );

    my $docs_nav     = $self->generate_docs_nav;
    my $registration = PnwQuizzing::Model::Register->new;
    my $header       = length( $root_dir . '/static' );
    my $photos       = Mojo::File
        ->new( $root_dir . '/static/photos' )
        ->list_tree
        ->map( sub { substr( $_->to_string, $header ) } )
        ->grep(qr/\.(?:jpg|png)$/)
        ->to_array;

    my $all = $self->routes->under( sub ($self) {
        $self->stash(
            docs_nav      => $docs_nav,
            header_photos => $photos,
            registration  => $registration,
        );
    } );

    my $users = $all->under( sub ($self) {
        return 1 if ( $self->stash('user') );
        $self->info('Login required but not yet met');
        $self->flash( message => 'Login required for the previously requested resource.' );
        $self->redirect_to('/');
        return 0;
    } );

    $users->any('/tool/:action')->to( controller => 'tool' );

    $users->any( '/user/' . $_ )->to( 'user#' . $_ ) for ( qw( logout list ) );

    $all->any('/user/verify/:verify_user_id/:verify_passwd')->to('user#verify');
    $all->any('/user/reset_password/:reset_user_id/:reset_passwd')->to('user#reset_password');
    $all->any( '/user/' . $_ )->to( 'user#' . $_ ) for ( qw( login account reset_password ) );

    $all->any('/search')->to('tool#search');
    $all->any('/git/push')->to('main#git_push');
    $all->any('/')->to('main#home_page');
    $all->any('/*name')->to('main#content');
}

sub build_css ( $self, $root_dir ) {
    Mojo::File->new(
        $root_dir . '/static/' . $self->conf->get( 'css', 'compile_to' )
    )->spurt(
        (
            CSS::Sass->new(
                source_comments => 1,
            )->compile_file(
                $root_dir . '/' . $self->conf->get( 'css', 'scss_src' )
            )
        )[0]
    );
}

sub setup_mojo_logging ($self) {
    my $log_dir = join( '/',
        $self->conf->get( qw( config_app root_dir ) ),
        $self->conf->get( qw( logging log_dir ) ),
    );
    make_path($log_dir) unless ( -d $log_dir );

    $self->setup_access_log;

    $self->log(
        MojoX::Log::Dispatch::Simple->new(
            dispatch  => $self->log_dispatch,
            level     => $self->conf->get( 'logging', 'log_level', $self->mode ),
            format_cb => sub { join( '',
                $self->log_date(shift),
                ' [' . uc(shift) . '] ',
                join( "\n", $self->dp( [ @_, '' ], colored => 0 ) ),
            ) },
        )
    );

    for my $level ( $self->log_levels ) {
        $self->helper( $level => sub {
            shift;
            $self->log->$level($_) for ( $self->dp(\@_) );
            return;
        } );
    }
}

sub setup_access_log ($self) {
    $self->log->level('error'); # temporarily raise log level to skip AccessLog "warn" status
    $self->plugin(
        'AccessLog',
        {
            'log' => join( '/',
                $self->conf->get( 'logging', 'log_dir' ),
                $self->conf->get( 'mojolicious', 'access_log' ),
            )
        },
    );
}

sub setup_templating ( $self, $root_dir ) {
    push( @INC, $root_dir );
    $self->plugin(
        'ToolkitRenderer',
        $self->tt_settings('web'),
    );
    $self->renderer->default_handler('tt');
}

sub setup_session_login ($self) {
    $self->helper( session_login => sub ($self) {
        if ( my $user_id = $self->session('user_id') ) {
            my $user;
            try {
                $user = PnwQuizzing::Model::User->new->load($user_id);
            }
            catch {
                $self->notice( 'Failed user load based on session "user_id" value: "' . $user_id . '"' );
            };

            if ($user) {
                $self->stash( 'user' => $user );
            }
            else {
                delete $self->session->{'user_id'};
            }
        }
    } );
}

1;
