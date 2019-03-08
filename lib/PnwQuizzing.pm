package PnwQuizzing;
use Mojo::Base -base, -signatures;
use Role::Tiny::With;

with qw(
    PnwQuizzing::Roles::Conf
    PnwQuizzing::Roles::Logging
    PnwQuizzing::Roles::Database
);

1;
