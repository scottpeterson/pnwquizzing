use Mojo::Base -strict;
use Config::App;
use Test::Most;
use Test::Mojo;
use Test::MockModule;

my $user = Test::MockModule->new('PnwQuizzing::Model::User');
$user->redefine( 'load', sub {
    my ($self) = @_;
    $self->data({});
    return $self;
} );

$ENV{MOJO_LOG_LEVEL} = 'fatal';
my $log = Test::MockModule->new('PnwQuizzing::Control');
$log->redefine( 'setup_access_log', 1 );
my $t = Test::Mojo->new('PnwQuizzing::Control');

$t->get_ok('/tool/hash')
    ->status_is(302)
    ->header_is( 'Location' => $t->app->url_for('/') );

$t->app->hook( before_dispatch => sub {
    my ($self) = @_;
    my $user = PnwQuizzing::Model::User->new->load(1);
    $self->stash( user => $user );
} );

$t->get_ok('/tool/hash')
    ->status_is(200)
    ->text_is( 'title' => 'PNWBQ: Secrets Hashing Tool' )
    ->element_exists('form#hash_tool');

done_testing();
