package PnwQuizzing;
use exact -class;

with qw(
    PnwQuizzing::Role::Conf
    PnwQuizzing::Role::Logging
    PnwQuizzing::Role::Database
    PnwQuizzing::Role::Bcrypt
);

1;
