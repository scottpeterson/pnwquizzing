package PnwQuizzing::Model::User;
use Mojo::Base 'PnwQuizzing::Model', -signatures;
use Carp 'croak';
use Digest;
use TryCatch;

has name => 'user';

sub create ( $self, $data ) {
    for ( qw(
        username
        passwd
        first_name
        last_name
    ) ) {
        croak( qq{"$_" appears to not be a valid input value} ) unless ( length $data->{$_} );
    }

    croak( q{"email" appears to not be a valid input value} )
        unless ( length $data->{email} and $data->{email} =~ /\w\@\w/ );

    $data->{passwd} = $self->bcrypt( $data->{passwd} );

    return $self->SUPER::create($data);
}

sub login ( $self, $username, $passwd ) {
    for ( qw( username passwd ) ) {
        croak( qq{"$_" appears to not be a valid input value} ) unless ( length $_ );
    }

    $passwd = $self->bcrypt($passwd);

    try {
        $self->load( { username => $username, passwd => $passwd } );
    }
    catch {
        $self->info('Login failure (in model)');
        croak('Failed user login');
    }

    return $self;
}

sub passwd ( $self, $passwd ) {
    $passwd = $self->bcrypt($passwd);
    $self->save( passwd => $passwd ) if ( $self->data );
    return $passwd;
}

1;
