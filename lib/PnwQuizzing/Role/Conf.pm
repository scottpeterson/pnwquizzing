package PnwQuizzing::Role::Conf;
use exact -role, -conf;

has conf => sub { conf() };

1;
