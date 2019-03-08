package PnwQuizzing::Roles::Conf;
use Mojo::Base -role, -signatures;
use Config::App;

has conf => sub { Config::App->new };

1;
