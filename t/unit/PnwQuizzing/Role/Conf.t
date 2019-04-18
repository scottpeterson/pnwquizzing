use Mojo::Base -strict;
use Config::App;
use Test::Most;

package PnwQuizzing {
    use Mojo::Base -base, -signatures;
}
$INC{'PnwQuizzing.pm'} = 1;

my $obj;
lives_ok( sub { $obj = PnwQuizzing->new->with_roles('+Conf') }, q{new->with_roles('+Conf')} );

ok( $obj->can('conf'), 'can conf()' );
is( ref $obj->conf, 'Config::App', 'conf() is a Config::App' );

ok( $obj->conf($_), "conf exits for: $_" ) for ( qw(
    base_url
    logging
    template
    database
    mojolicious
    bcrypt
    email
) );

done_testing();
