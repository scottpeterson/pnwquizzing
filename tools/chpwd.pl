#!/usr/bin/env perl
use Mojo::Base -strict, -signatures;
use Config::App;
use Util::CommandLine qw( options pod2usage );
use Term::ReadKey 'ReadMode';
use TryCatch;
use PnwQuizzing::Model::User;

my $settings = options( qw( username|u=s password|p=s ) );
pod2usage('Must supply "username" value') unless ( $settings->{username} );

my $user;
try {
    $user = PnwQuizzing::Model::User->new->load( { username => $settings->{username} } );
}
catch {
    die 'Failed to find user "' . $settings->{username} . '"' . "\n";
}

unless ( defined $settings->{password} ) {
    ReadMode('noecho');

    print 'Password: ';
    $settings->{password} = <STDIN>;
    print "\n";
    chomp $settings->{password};

    print 'Password (again): ';
    my $password = <STDIN>;
    print "\n";
    chomp $password;

    ReadMode('original');

    die "Passwords entered do not match\n" unless ( $settings->{password} eq $password );
}

$user->passwd( $settings->{password} );

=head1 NAME

chpwd.pl - Change a user's password

=head1 SYNOPSIS

    chpwd.pl OPTIONS
        -u|username USERNAME
        -p|password PASSWORD (optional)
        -h|help
        -m|man

=head1 DESCRIPTION

This program will change a user's password. If password is not supplied on the
command-line (which is recommended), it will be queried.
