#!/usr/bin/env perl
use exact -cli;
use PnwQuizzing::Model::Register;

my $settings = options('dryrun|d');
my $report   = PnwQuizzing::Model::Register->new->send_reminders( $settings->{dryrun} );

if ( $settings->{dryrun} ) {
    say '       Meet: ', $report->{next_meet}{meet};
    say '   Deadline: ', $report->{next_meet}{deadline};
    say 'Days Before: ', $report->{next_meet}{days_before_deadline};
    say '     Emails: ', scalar( @{ $report->{to_emails_addresses} } );
    say "\n", join( "\n", @{ $report->{to_emails_addresses} } ) if ( @{ $report->{to_emails_addresses} } );
}

=head1 NAME

registration.pl - Send email reminders based on registration status

=head1 SYNOPSIS

    registration.pl OPTIONS
        -d|dryrun
        -h|help
        -m|man

=head1 DESCRIPTION

This program will send email reminders based on registration status.
