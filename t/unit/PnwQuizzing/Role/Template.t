use Mojo::Base -strict;
use Config::App;
use Test::Most;

package PnwQuizzing {
    use Mojo::Base -base, -signatures;
}
$INC{'PnwQuizzing.pm'} = 1;

my $obj;
lives_ok( sub { $obj = PnwQuizzing->new->with_roles('+Template') }, q{new->with_roles('+Template')} );
ok( $obj->can($_), "can $_()" ) for ( qw( version tt tt_settings ) );

my $tt;
lives_ok( sub { $tt = $obj->tt }, 'tt() executes' );
is( ref $tt, 'Template', 'tt() returns Template' );

done_testing();
