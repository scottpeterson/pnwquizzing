use Mojo::Base -strict;
use Config::App;
use Test::Most;

package PnwQuizzing {
    use Mojo::Base -base, -signatures;
}
$INC{'PnwQuizzing.pm'} = 1;

my $obj;
lives_ok( sub { $obj = PnwQuizzing->new->with_roles('+Database') }, q{new->with_roles('+Database')} );
ok( $obj->can('dq'), 'can dq()' );
is( ref $obj->dq, 'DBIx::Query::db', 'dq() is a DBIx::Query' );

done_testing();
