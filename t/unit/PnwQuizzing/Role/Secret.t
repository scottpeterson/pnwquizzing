use Mojo::Base -strict;
use Config::App;
use Test::Most;

package PnwQuizzing {
    use Mojo::Base -base, -signatures;
}
$INC{'PnwQuizzing.pm'} = 1;

my $obj;
lives_ok( sub { $obj = PnwQuizzing->new->with_roles('+Secret') }, q{new->with_roles('+Secret')} );
ok( $obj->can($_), "can $_()" ) for ( qw( secret desecret translate transcode ) );

my $phrase = '__test_pnwquizzing_role_secret_' . $$;
my $hash;
lives_ok( sub { $hash = $obj->secret($phrase) }, 'secret() returns hash' );
isnt( $hash, $phrase, 'hash is not the phrase' );
is( $hash, $obj->secret($phrase), 'secret() returns saved value' );
is( $phrase, $obj->desecret($hash), 'desecret() returns phrase for hash' );
is( "embedded $phrase secret", $obj->translate("embedded $hash secret"), 'translate()' );
is( "embedded $hash secret", $obj->transcode("embedded $phrase secret"), 'transcode()' );

$obj->dq->sql('DELETE FROM secret WHERE phrase = ?')->run($phrase);
done_testing();
