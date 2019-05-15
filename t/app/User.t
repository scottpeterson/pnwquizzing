use Mojo::Base -strict;
use Config::App;
use Test::Most;
use Test::Mojo;
use Test::MockModule;

$ENV{MOJO_LOG_LEVEL} = 'fatal';
my $log = Test::MockModule->new('PnwQuizzing::Control');
$log->redefine( 'setup_access_log', 1 );
my $t = Test::Mojo->new('PnwQuizzing::Control');

$t->get_ok('/user/account')
    ->status_is(200)
    ->text_is( 'title' => 'PNWBQ: New User Sign-Up' )
    ->element_exists('form fieldset label input[name="email"]');

my $stash;
$t->app->hook( after_dispatch => sub { $stash = shift->stash } );

my $user = Test::MockModule->new('PnwQuizzing::Model::User');
$user->redefine( 'login', sub { die } );

$t->post_ok('/user/login' => form => {} )
    ->status_is(302)
    ->header_is( 'Location' => $t->app->url_for('/') );

is( $stash->{'mojo.session'}{new_flash}{message}, 'Login failed. Please try again.', 'login fail message' );

$user->redefine( 'login', sub {
    my ($self) = @_;
    $self->data({ user_id => 1, username => 'test' });
    return $self;
} );

$t->post_ok('/user/login' => form => {} )
    ->status_is(302)
    ->header_is( 'Location' => $t->app->url_for('/') );

ok( not( exists $stash->{'mojo.session'}{new_flash} ), 'login fail message' );

$t->post_ok('/user/logout')
    ->status_is(302)
    ->header_is( 'Location' => $t->app->url_for('/') );

$user->redefine( 'create', sub { die 'Failed in automated testing' } );
$user->redefine( 'verify_email', 1 );

$t->post_ok( '/user/account' => form => {
    form_submit => 1,
} )
    ->status_is(200)
    ->text_is( 'title' => 'PNWBQ: New User Sign-Up' );

is( $stash->{message}, 'Failed in automated testing. Please try again.', 'error message set correctly' );

$user->redefine( 'create', sub {
    my ($self) = @_;
    $self->data({});
    return $self;
} );

$t->post_ok( '/user/account' => form => {
    username    => 'username',
    passwd      => 'passwd',
    first_name  => 'first_name',
    last_name   => 'last_name',
    email       => 'email',
    form_submit => 1,
} )
    ->status_is(200)
    ->text_is( 'title' => 'PNWBQ: Account Created' )
    ->text_is( 'h1' => 'New PNW Quizzing Site Account Created' );

$user->redefine( 'verify', 1 );
$t->post_ok('/user/verify/1/hash')
    ->status_is(302)
    ->header_is( 'Location' => $t->app->url_for('/') );

is( $stash->{'mojo.session'}{new_flash}{message}{type}, 'success', 'verify success' );

$user->redefine( 'verify', 0 );
$t->post_ok('/user/verify/1/hash')
    ->status_is(302)
    ->header_is( 'Location' => $t->app->url_for('/') );

is(
    $stash->{'mojo.session'}{new_flash}{message},
    'Unable to verify user account using the link provided.',
    'verify failure',
);

done_testing();
