use Mojo::Base -strict;
use Config::App;
use Test::Most;
use Mojo::File;

package PnwQuizzing {
    use Mojo::Base -base, -signatures;
}
$INC{'PnwQuizzing.pm'} = 1;

my $obj;
lives_ok( sub { $obj = PnwQuizzing->new->with_roles('+Logging') }, q{new->with_roles('+Logging')} );

ok( $obj->can($_), "can $_()" ) for ( qw(
    log_level
    log_dispatch
    dp
    log_date
    log_levels
) );

open( my $save_out, '>&STDOUT' );
close STDOUT;
open( STDOUT, '>', \my $output );

lives_ok( sub { $obj->debug('Test-generated message') }, 'debug()' );

close STDOUT;
open( STDOUT, '>&', $save_out );

like(
    $output,
    qr/\w{3}\s+\d+\s+\d+:\d+:\d+\s+\d{4}\s+\[DEBUG\]\s+Test-generated message/,
    'test-generated message looks proper',
);

my $log_file = join( '/',
    $obj->conf->get( qw( config_app root_dir ) ),
    $obj->conf->get( qw( logging log_dir ) ),
    $obj->conf->get( qw( logging log_file ) ),
);

ok( -f $log_file, 'log file exists' );
ok( index( Mojo::File->new($log_file)->slurp, $output ) != -1, 'log line exists in log file' );

package MockDispatch {
    sub new {
        return bless( {}, $_[0] );
    }
    sub AUTOLOAD {}
}

$obj->log_dispatch( MockDispatch->new );

lives_ok( sub { $obj->$_('Message') }, "can $_()" ) for ( qw(
    debug
    info
    notice
    warning
    warn
    error
    err
    critical
    crit
    alert
    emergency
    emerg
) );

done_testing();
