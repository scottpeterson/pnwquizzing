#!/usr/bin/env perl
use Mojo::Base -strict, -signatures;
use Config::App;
use Util::CommandLine qw( options pod2usage );
use Mojo::File;
use Text::CSV_XS 'csv';
use PnwQuizzing;

my $settings = options( qw(
    secret|s
    desecret|d
    translate|t
    input|i=s
    filename|f=s
    column|c=s
    name|n=s
) );

pod2usage('Must stipulate an action: secret, desecret, or translate')
    unless ( $settings->{secret} || $settings->{desecret} || $settings->{translate} );

pod2usage('Must stipulate content source: input or filename')
    unless ( $settings->{input} || $settings->{filename} );

pod2usage( $settings->{filename} . ' is not a readable file')
    if ( $settings->{filename} and not -r $settings->{filename} );

my $pnw = PnwQuizzing->new->with_roles('+Secret');

if ( $settings->{input} ) {
    say $pnw->secret( $settings->{input} ) if ( $settings->{secret} );
    say $pnw->desecret( $settings->{input} ) if ( $settings->{desecret} );
    say $pnw->translate( $settings->{input} ) if ( $settings->{translate} );
}

print $pnw->translate( Mojo::File->new( $settings->{filename} )->slurp )
    if ( $settings->{filename} and $settings->{translate} );

if ( $settings->{filename} and $settings->{secret} ) {
    if ( $settings->{column} or $settings->{name} ) {
        my $data = ( $settings->{name} )
            ? csv( in => $settings->{filename}, headers => 'auto' )
            : csv( in => $settings->{filename} );

        for (@$data) {
            if ( $settings->{name} ) {
                $_->{ $settings->{name} } = $pnw->secret( $_->{ $settings->{name} } );
            }
            else {
                $_->[ $settings->{column} - 1 ] = $pnw->secret( $_->[ $settings->{column} - 1 ] );
            }
        }

        csv( in => $data, out => \*STDOUT );
    }
    else {
        print $pnw->transcode( Mojo::File->new( $settings->{filename} )->slurp );
    }
}

=head1 NAME

secret.pl - Change a user's password

=head1 SYNOPSIS

    secret.pl OPTIONS
        -s|secret     # secret-ize content
        -d|desecret   # de-secret-ize content
        -t|translate  # translate content
        -i|input      # input content
        -f|filename   # filename for content
        -c|column     # CSV column number (starting at 1)
        -n|name       # CSV column name (assuming header row)
        -h|help
        -m|man

=head1 DESCRIPTION

This program execute "secret" operations, either hashing real data or returning
real data for a previously generated hash. It will also translate content with
hashed values within, including Markdown and CSV files.

=head2 Secret

To create a secret (create a hash) of a given input, perform the following:

    ./secret.pl -s -i test

=head3 Secret Columns

It's possible to specify a column of a CSV file and then make all its content
be secret hashes. You can specify a column by its number (starting at 1) or by
it's name, which assumes the first row is a header row.

    ./secret.pl -s -f data.csv -c 5
    ./secret.pl -s -f data.csv -n Quizzer

=head2 Desecret

To revert a secret to its desecret (non-hashed) original input, perform the
following:

    ./secret.pl -d -i fdc66e6

=head2 Translation

Translation is when you have a set of secrets already created and you want to
find and replace all instances of those secrets in input for their hash
counterparts.

    ./secret.pl -t -i 'This is a fdc66e6 sentence.'
    ./secret.pl -t -f content.md

=head2 Bulk-Secret-ing or Transcoding

Given a set of secrets already created, you can bulk replace parts of content
with those hashes (or transcode the content):

    ./secret.pl -s -f content.md
