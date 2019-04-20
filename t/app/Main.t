use Mojo::Base -strict;
use Config::App;
use Test::Most;
use Test::Mojo;
use Test::MockModule;
use Mojo::File;

$ENV{MOJO_LOG_LEVEL} = 'fatal';
my $log = Test::MockModule->new('PnwQuizzing::Control');
$log->redefine( 'setup_access_log', 1 );
my $t = Test::Mojo->new('PnwQuizzing::Control');

my $content = (
    Mojo::File->new( Config::App->new->get( 'config_app', 'root_dir' ) . '/docs/index.md'
)->slurp =~ /\n\s*##\s*([^\n]+)\n/ms ) ? '<h2>' . quotemeta($1) . '</h2>' : undef;

$t->get_ok('/')
    ->status_is(200)
    ->text_is( 'title' => 'PNW Bible Quizzing' )
    ->element_exists('div#nav')
    ->element_exists('div#header div#header_user form input[name="username"]')
    ->element_exists('h1#home_page_title')
    ->element_exists('div#home_page_nav h2')
    ->element_exists('div#home_page_nav div a span')
    ->element_exists('div#content_footer')
    ->content_like( qr|$content|, '<h2> renders properly' );

my $docs_nav = PnwQuizzing->new->with_roles('+DocsNav')->generate_docs_nav;
my $md_nodes;
$md_nodes = sub {
    grep { $_->{type} and $_->{type} eq 'md' }
    map { ( $_->{nodes} ) ? $md_nodes->( $_->{nodes} ) : $_ }
    @{ $_[0] }
};
my @nodes = $md_nodes->($docs_nav);
my $node  = $nodes[-1];

$t->get_ok( $node->{href} )
    ->status_is(200)
    ->element_exists('div#nav')
    ->element_exists('div#header div#header_user form input[name="username"]')
    ->element_exists('div#content_footer');

done_testing();
