use Mojo::Base -strict;
use Config::App;
use Test::Most;
use Test::MockModule;
use DBIx::Query;

package MockBlank {
    sub new { return bless( {}, $_[0] ) }
    sub AUTOLOAD { return $_[0] }
}
my $dq = Test::MockModule->new('DBIx::Query::st', no_auto => 1 );
$dq->redefine( 'run', sub { return MockBlank->new } );

package PnwQuizzing::Model::Email {
    sub new { return bless( {}, $_[0] ) }
    sub AUTOLOAD { return $_[0] }
}
$INC{'PnwQuizzing/Model/Email.pm'} = 1;

my $model = Test::MockModule->new('PnwQuizzing::Model');
$model->redefine( 'load', 1 );
$model->redefine( 'save', 1 );

use_ok('PnwQuizzing::Model::User');

my $obj;
lives_ok( sub { $obj = PnwQuizzing::Model::User->new }, 'new()' );
ok( $obj->isa('PnwQuizzing::Model'), 'isa PnwQuizzing::Model' );
ok( $obj->can($_), "can $_()" ) for ( qw(
    login
    passwd
    verify_email
    verify
) );

throws_ok(
    sub { $obj->create({}) },
    qr/"username" appears to not be a valid input value/,
    'create() with incomplete params'
);

my $user_data = {
    username   => '__test_pnwquizzing_model_user_' . $$,
    passwd     => 'passwd',
    first_name => 'first_name',
    last_name  => 'last_name',
    email      => 'invalid',
};

throws_ok(
    sub { $obj->create($user_data) },
    qr/"email" appears to not be a valid input value/,
    'create() with invalid email'
);

$user_data->{email} = 'example@example.com';

lives_ok(
    sub { $obj = $obj->create($user_data) },
    'create() with valid input'
);

lives_ok(
    sub { $obj = $obj->login( @$user_data{ qw( username passwd ) } ) },
    'login() with valid input'
);

lives_ok(
    sub { $obj->passwd('new_passwd') },
    'passwd()'
);

$user_data->{user_id} = 1;
$obj->data($user_data);
lives_ok(
    sub { $obj->verify_email('url') },
    'verify_email()'
);

lives_ok(
    sub { $obj->verify( 1, 'hash' ) },
    'verify()'
);

done_testing();
