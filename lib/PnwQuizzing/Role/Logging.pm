package PnwQuizzing::Role::Logging;
use exact -role;
use Data::Printer return_value => 'dump', colored => 1;
use File::Path 'make_path';
use Log::Dispatch;
use Term::ANSIColor;

with 'PnwQuizzing::Role::Conf';

has log_level    => undef;
has log_dispatch => sub ($self) {
    $self->log_level(
        $self->conf->get(
            'logging',
            'log_level',
            ( $ENV{CONFIGAPPENV} and $ENV{CONFIGAPPENV} eq 'production' ) ? 'production' : 'development'
        )
    ) unless ( defined $self->log_level );

    my $log_dir = join( '/',
        $self->conf->get( qw( config_app root_dir ) ),
        $self->conf->get( qw( logging log_dir ) ),
    );
    make_path($log_dir) unless ( -d $log_dir );

    my $log_dispatch = Log::Dispatch->new(
        outputs => [
            [
                'Screen',
                name      => 'stdout',
                min_level => _highest_level( $self->log_level, 'debug' ),
                max_level => 'notice',
                newline   => 1,
                callbacks => [ \&_log_cb_label, \&_log_cb_time, \&_log_cb_color ],
                stderr    => 0,
            ],
            [
                'Screen',
                name      => 'stderr',
                min_level => _highest_level( $self->log_level, 'warning' ),
                newline   => 1,
                callbacks => [ \&_log_cb_label, \&_log_cb_time, \&_log_cb_color ],
                stderr    => 1,
            ],
            [
                'File',
                name      => 'log_file',
                min_level => _highest_level( $self->log_level, 'debug' ),
                newline   => 1,
                callbacks => [ \&_log_cb_label, \&_log_cb_time, \&_log_cb_color ],
                mode      => 'append',
                autoflush => 1,
                filename  => join( '/',
                    $self->conf->get( qw( config_app root_dir ) ),
                    $self->conf->get( qw( logging log_dir ) ),
                    $self->conf->get( qw( logging log_file ) ),
                ),
            ],
            [
                'Email::Mailer',
                name      => 'email',
                min_level => _highest_level( $self->log_level, 'alert' ),
                to        => $self->conf->get( 'logging', 'alert_email' ) || 'example@example.com',
                subject   => $self->conf->get( 'logging', 'alert_email_subject' ) || 'Alert Log Message',
            ],
        ],
    );

    my $filter = $self->conf->get( 'logging', 'filter' );
    $filter = ( ref $filter ) ? $filter : ($filter) ? [$filter] : [];
    $filter = [ map { $_->{name} } $log_dispatch->outputs ] if ( grep { lc($_) eq 'all' } @$filter );

    $log_dispatch->remove($_) for (@$filter);
    return $log_dispatch;
};

sub debug     ( $self, @params ) { return $self->log_dispatch->debug    ( $self->dp( \@params ) ) }
sub info      ( $self, @params ) { return $self->log_dispatch->info     ( $self->dp( \@params ) ) }
sub notice    ( $self, @params ) { return $self->log_dispatch->notice   ( $self->dp( \@params ) ) }
sub warning   ( $self, @params ) { return $self->log_dispatch->warning  ( $self->dp( \@params ) ) }
sub warn      ( $self, @params ) { return $self->log_dispatch->warn     ( $self->dp( \@params ) ) }
sub error     ( $self, @params ) { return $self->log_dispatch->error    ( $self->dp( \@params ) ) }
sub err       ( $self, @params ) { return $self->log_dispatch->err      ( $self->dp( \@params ) ) }
sub critical  ( $self, @params ) { return $self->log_dispatch->critical ( $self->dp( \@params ) ) }
sub crit      ( $self, @params ) { return $self->log_dispatch->crit     ( $self->dp( \@params ) ) }
sub alert     ( $self, @params ) { return $self->log_dispatch->alert    ( $self->dp( \@params ) ) }
sub emergency ( $self, @params ) { return $self->log_dispatch->emergency( $self->dp( \@params ) ) }
sub emerg     ( $self, @params ) { return $self->log_dispatch->emerg    ( $self->dp( \@params ) ) }

sub dp ( $self, $params, @np_settings ) {
    return map { ( ref $_ ) ? "\n" . np( $_, @np_settings ) . "\n" : $_ } @$params;
}

{
    my @abbr = qw( Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec );
    sub log_date ( $self = undef, $this_time = time ) {
        my ( $year, $month, @time_bits ) = reverse( ( localtime($this_time) )[ 0 .. 5 ] );
        return sprintf( '%3s %2d %2d:%02d:%02d %4d', $abbr[$month], @time_bits, ( $year + 1900 ) );
    }
}

sub _log_cb_time (%msg) {
    return log_date() . ' ' . $msg{message};
}

sub _log_cb_label (%msg) {
    return '[' . uc( $msg{level} ) . '] ' . $msg{message};
}

{
    my $log_levels = {
        debug => 1,
        info  => 2,
        warn  => 3,
        error => 4,
        fatal => 5,

        notice    => 2,
        warning   => 3,
        critical  => 4,
        alert     => 5,
        emergency => 5,
        emerg     => 5,

        err  => 4,
        crit => 4,
    };

    sub _highest_level (@input) {
        return (
            map { $_->[1] }
            sort { $b->[0] <=> $a->[0] }
            map { [ $log_levels->{$_}, $_ ] }
            @input
        )[0];
    }

    sub log_levels {
        return keys %$log_levels;
    }
}

{
    my %color = (
        reset  => Term::ANSIColor::color('reset'),
        bold   => Term::ANSIColor::color('bold'),

        debug     => 'cyan',
        info      => 'white',
        notice    => 'bright_white',
        warning   => 'yellow',
        error     => 'bright_red',
        critical  => [ qw( underline bright_red ) ],
        alert     => [ qw( underline bright_yellow) ],
        emergency => [ qw( underline bright_yellow on_blue ) ],
    );

    for ( qw( debug info notice warning error critical alert emergency ) ) {
        next unless ( $color{$_} );
        $color{$_} = join ( '', map {
            $color{$_} = Term::ANSIColor::color($_) unless ( $color{$_} );
            $color{$_};
        } ( ( ref $color{$_} ) ? @{ $color{$_} } : $color{$_} ) );
    }

    sub _log_cb_color (%msg) {
        return ( $color{ $msg{level} } )
            ? $color{ $msg{level} } . $msg{message} . $color{reset}
            : $msg{message};
    }
}

1;
