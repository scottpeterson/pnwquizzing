package PnwQuizzing::Model::User;
use Mojo::Base 'PnwQuizzing::Model', -signatures;
use Carp 'croak';
use TryCatch;
use PnwQuizzing::Model::Email;

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
        $self->load( { username => $username, passwd => $passwd, active => 1 } );
        $self->save( last_login => \q{ DATETIME('NOW') } );
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

sub verify_email ( $self, $url = undef ) {
    croak('Cannot verify_email() because user data not loaded in user object') unless ( $self->data );
    $url ||= $self->conf->get('base_url');
    $url .= '/user/verify/' . $self->id . '/' . substr( $self->prop('passwd'), 0, 12 );

    PnwQuizzing::Model::Email->new( type => 'verify_email' )->send({
        to   => sprintf( '%s %s <%s>', map { $self->prop($_) } qw( first_name last_name email ) ),
        data => {
            %{ $self->data },
            url => $url,
        },
    });
}

sub verify ( $self, $user_id, $passwd ) {
    my $verified = $self->dq->sql(q{
        SELECT COUNT(*) FROM user WHERE user_id = ? AND passwd LIKE ?
    })->run( $user_id, $passwd . '%' )->value;

    $self->dq->sql('UPDATE user SET active = 1 WHERE user_id = ?')->run($user_id) if ($verified);
    return $verified;
}

1;
