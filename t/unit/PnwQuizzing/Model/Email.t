use Mojo::Base -strict;
use Config::App;
use Test::Most;
use Test::MockModule;

my $log = Test::MockModule->new('PnwQuizzing::Role::Logging');
$log->redefine( 'info', 1 );

my $mailer = Test::MockModule->new('Email::Mailer');
$mailer->redefine( 'send', 1 );

use_ok('PnwQuizzing::Model::Email');

my $obj;
throws_ok(
    sub { $obj = PnwQuizzing::Model::Email->new() },
    qr/Failed new\(\) because "type" must be defined/,
    'new() throws',
);
lives_ok( sub { $obj = PnwQuizzing::Model::Email->new( type => 'verify_email' ) }, 'new( type => $type )' );
ok( $obj->isa('PnwQuizzing::Model'), 'isa PnwQuizzing::Model' );
ok( $obj->can($_), "can $_()" ) for ( qw(
    type
    subject
    html
    new
    send
) );

lives_ok( sub { $obj->send({}) }, 'send()' );

done_testing();
