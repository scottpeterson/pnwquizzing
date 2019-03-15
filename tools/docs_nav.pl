#!/usr/bin/env perl
use Mojo::Base -strict, -signatures;
use Config::App;
use PnwQuizzing;

my $pnw = PnwQuizzing->new->with_roles('+DocsNav');

$pnw->generate_docs_nav;
