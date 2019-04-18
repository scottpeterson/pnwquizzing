use Mojo::Base -strict;
use Config::App;
use Test::Most;
use Test::Mojo;

my $t = Test::Mojo->new('PnwQuizzing::Control');
$t->get_ok('/')->status_is(200);

done_testing();
