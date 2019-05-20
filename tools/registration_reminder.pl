#!/usr/bin/env perl
use Mojo::Base -strict, -signatures;
use Config::App;
use Util::CommandLine 'podhelp';
use PnwQuizzing::Model::Register;

PnwQuizzing::Model::Register->new->send_reminders;

=head1 NAME

registeration_reminder.pl - Send registration reminders as appropriate

=head1 SYNOPSIS

    chpwd.pl OPTIONS
        -h|help
        -m|man

=head1 DESCRIPTION

This program will send registration reminder emails as appropriate.
