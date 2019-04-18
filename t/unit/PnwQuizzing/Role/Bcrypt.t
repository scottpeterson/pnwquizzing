use Mojo::Base -strict;
use Config::App;
use Test::Most;
use Role::Tiny::With;

my $roles;
BEGIN {
    no warnings 'redefine';
    *Role::Tiny::With::with = sub { $roles = \@_ };
}

package PnwQuizzing {
    use Mojo::Base -base, -signatures;
    sub conf ($self) { return $self }
    sub get ( $self, $param ) {
        return {
            cost => 1,
            salt => '91da14caf768cff6',
        } if ( $param and $param eq 'bcrypt' );
    }
}
$INC{'PnwQuizzing.pm'} = 1;

my $obj;
lives_ok( sub { $obj = PnwQuizzing->new->with_roles('+Bcrypt') }, q{new->with_roles('+Bcrypt')} );
is_deeply( $roles, ['PnwQuizzing::Role::Conf'], 'roles list' );

is(
    $obj->bcrypt('e2c388ca378a317d422cd1c69558f24684591c1372ec0d'),
    '7a09b5bda25104a63edc4e5cb878a8dd445bfd3810d985',
    'bcrypt()',
);

done_testing();
