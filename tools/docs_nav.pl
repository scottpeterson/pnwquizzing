#!/usr/bin/env perl
use Mojo::Base -strict, -signatures;
use Config::App;
use PnwQuizzing;
use DDP;

my $docs_nav = PnwQuizzing->new->with_roles('+DocsNav')->generate_docs_nav;
p $docs_nav;
