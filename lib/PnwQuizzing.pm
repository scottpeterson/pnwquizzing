package PnwQuizzing;
use Mojo::Base -base, -signatures;
use Role::Tiny::With;

with qw(
    PnwQuizzing::Role::Conf
    PnwQuizzing::Role::Logging
    PnwQuizzing::Role::Database
);

1;
