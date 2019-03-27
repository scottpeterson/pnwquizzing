#!/usr/bin/env perl
use Mojo::Base -strict, -signatures;
use Config::App;
use PnwQuizzing;
use Util::CommandLine 'podhelp';

my $pnw = PnwQuizzing->new;
$pnw->info( $pnw->with_roles('+DocsNav')->generate_docs_nav );

=head1 NAME

docs_nav.pl - Print the "docs nav" data structure

=head1 SYNOPSIS

    docs_nav.pl
        -h|help
        -m|man

=head1 DESCRIPTION

This program will print the data structure of the "docs nav" or DocsNav role's
C<generate_docs_nav()> method.
