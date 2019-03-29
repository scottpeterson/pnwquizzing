package PnwQuizzing::Control;
use Mojo::Base 'Mojolicious', -signatures;
use Role::Tiny::With;
use parent 'PnwQuizzing';
use MojoX::Log::Dispatch::Simple;
use Mojo::Loader 'load_class';
use CSS::Sass;
use Mojo::File;
use TryCatch;
use PnwQuizzing::Model::User;

with 'PnwQuizzing::Role::Template';

sub startup ($self) {
    my $root_dir = $self->conf->get( 'config_app', 'root_dir' );

    $self->plugin('RequestBase');

    $self->build_css($root_dir);
    $self->setup_mojo_logging;
    $self->setup_templating($root_dir);

    $self->static->paths->[0] =~ s|/public$|/static|;
    $self->config( $self->conf->get( 'mojolicious', 'config' ) );
    $self->secrets( $self->conf->get( 'mojolicious', 'secrets' ) );
    $self->sessions->cookie_name( $self->conf->get( qw( mojolicious session cookie_name ) ) );
    $self->sessions->default_expiration( $self->conf->get( qw( mojolicious session default_expiration ) ) );

    if ( $self->mode eq 'production' ) {
        load_class( 'PnwQuizzing::Control::' . $_ ) for qw( Main User );
    }

    $self->hook( 'before_dispatch' => sub ($self) {
        if ( my $user_id = $self->session('user_id') ) {
            my $user;
            try {
                $user = PnwQuizzing::Model::User->new->load($user_id);
            }
            catch {
                $self->notice( 'Failed user load based on session "user_id" value: "' . $user_id . '"' );
            }

            if ($user) {
                $self->stash( 'user' => $user );
            }
            else {
                delete $self->session->{'user_id'};
            }
        }
    } );

    my $all = $self->routes;

    ## TODO:

    # my $users = $anyone->under( sub ($self) {
    #     return 1 if ( $self->stash('user') );
    #     $self->info('Login required but not yet met');
    #     $self->flash( message => 'Login required for the previously requested resource.' );
    #     $self->redirect_to('/');
    #     return 0;
    # } );

    # $users->any('/register')->to('register#main');

    $all->any( '/user/' . $_ )->to( controller => 'user', action => $_ ) for ( qw( login logout signup ) );
    $all->any('/user/verify/:verify_user_id/:verify_passwd')->to('user#verify');

    $all->any('/')->to('main#content');
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

sub setup_templating ( $self, $root_dir ) {
    push( @INC, $root_dir );
    $self->plugin(
        'ToolkitRenderer',
        $self->tt_settings('web'),
    );
    $self->renderer->default_handler('tt');
}

1;