#!/usr/bin/env perl
use Mojo::Base -strict, -signatures;
use Config::App;
use PnwQuizzing::Model::Email;

my $email = PnwQuizzing::Model::Email->new( type => 'reset_password' );

$email->send({
    to   => 'Gryphon Shafer <gryphon@goldenguru.com>',
    from => 'PNW Quizzing <site@pnwquizzing.org>',
    data => {
        realname => 'SUPER TAG NAME THANK YOU',
        username => 'gryphon',
        url      => 'https://goldenguru.com',
    },
});
