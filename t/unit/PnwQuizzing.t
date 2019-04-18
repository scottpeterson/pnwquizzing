use Mojo::Base -strict;
use Config::App;
use Test::Most;
use Role::Tiny::With;

my $roles;
BEGIN {
    no warnings 'redefine';
    *Role::Tiny::With::with = sub { $roles = \@_ };
}

use_ok('PnwQuizzing');

is_deeply( $roles, [ qw(
    PnwQuizzing::Role::Conf
    PnwQuizzing::Role::Logging
    PnwQuizzing::Role::Database
    PnwQuizzing::Role::Bcrypt
) ], 'roles list' );

my $pnw;
lives_ok( sub { $pnw = PnwQuizzing->new }, 'new()' );

done_testing();
