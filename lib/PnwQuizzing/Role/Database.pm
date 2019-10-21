package PnwQuizzing::Role::Database;
use exact -role;
use App::Dest;
use DBIx::Query;
use File::Path 'make_path';
use PnwQuizzing;

with 'PnwQuizzing::Role::Conf';

sub import {
    my $self     = PnwQuizzing->new;
    my $conf     = $self->conf->get('database');
    my $root_dir = $self->conf->get( qw( config_app root_dir ) );
    my $dir      = join( '/', $root_dir, $conf->{dir} );

    make_path($dir) unless ( -d $dir );

    unless ( -f $dir . '/' . $conf->{file} ) {
        chdir $root_dir;

        try {
            App::Dest->init;
            App::Dest->update;
        };
    }
}

has dq => sub ($self) {
    my $conf     = $self->conf->get('database');
    my $root_dir = $self->conf->get( qw( config_app root_dir ) );
    my $dir      = join( '/', $root_dir, $conf->{dir} );

    my $dq = DBIx::Query->connect(
        'dbi:SQLite:dbname=' . $dir . '/' . $conf->{file},
        undef,
        undef,
        $conf->{settings},
    );

    $dq->do('PRAGMA foreign_keys = ON');
    return $dq;
};

1;
