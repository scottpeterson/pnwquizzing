package PnwQuizzing::Role::Database;
use Mojo::Base -role, -signatures;
use Role::Tiny::With;
use DBIx::Query;
use File::Path 'make_path';

with 'PnwQuizzing::Role::Conf';

has dq => sub ($self) {
    my $conf = $self->conf->get('database');
    my $dir  = join( '/',
        $self->conf->get( qw( config_app root_dir ) ),
        $conf->{dir},
    );
    make_path($dir) unless ( -d $dir );

    return DBIx::Query->connect( 'dbi:SQLite:dbname=' . $dir . '/' . $conf->{file} );
};

1;
