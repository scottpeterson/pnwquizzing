package PnwQuizzing::Control;
use Mojo::Base 'Mojolicious', -signatures;
use Role::Tiny::With;
use parent 'PnwQuizzing';
use MojoX::Log::Dispatch::Simple;
use Mojo::Loader 'load_class';

with 'PnwQuizzing::Role::Template';

sub startup ($self) {
    $self->plugin('RequestBase');

    $self->plugin( 'AssetPack' => { pipes => [ qw( Sass Css Combine ExportToDirectory ) ] } );
    $self->asset->pipe('ExportToDirectory')->export_dir('static/assets');
    $self->asset->process( 'app.css' => 'sass/app.scss' );

    $self->setup_mojo_logging;
    $self->setup_templating;

    $self->static->paths->[0] =~ s|/public$|/static|;
    $self->sessions->cookie_name( $self->conf->get( qw( mojolicious session cookie_name ) ) );
    $self->secrets( $self->conf->get( 'mojolicious', 'secrets' ) );
    $self->config( $self->conf->get( 'mojolicious', 'config' ) );
    $self->sessions->default_expiration( $self->conf->get( qw( mojolicious session default_expiration ) ) );

    if ( $self->mode eq 'production' ) {
        load_class( 'PnwQuizzing::Control::' . $_ ) for qw( Main );
    }

    $self->hook( 'before_dispatch' => sub {
        my $last_request_time = $self->session('last_request_time');
        my $duration = $self->conf->get( qw( mojolicious session duration ) );

        if ( $duration and $last_request_time and $last_request_time < time - $duration ) {
            $self->session( expires => 1 );
            $self->redirect_to;
        }
        $self->session( 'last_request_time' => time );
    });

    my $r = $self->routes;
    $r->any('/')->to('main#content');
    $r->any('/*name')->to('main#content');
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

sub setup_templating ($self) {
    push( @INC, $self->conf->get( 'config_app', 'root_dir' ) );
    $self->plugin(
        'ToolkitRenderer',
        $self->tt_settings('web'),
    );
    $self->renderer->default_handler('tt');
}

1;
