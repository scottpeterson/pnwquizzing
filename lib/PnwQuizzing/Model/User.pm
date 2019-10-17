package PnwQuizzing::Model::User;
use Mojo::Base 'PnwQuizzing::Model', -signatures;
use Carp 'croak';
use TryCatch;
use PnwQuizzing::Model::Email;

has name => 'user';

sub _user_data_prep ( $self, $data ) {
    $data->{passwd}    = $self->bcrypt( $data->{passwd} );
    $data->{church_id} = $self->dq->sql(q{
        SELECT church_id FROM church WHERE acronym = ?
    })->run(
        delete $data->{church}
    )->value or croak( q{"ministry" appears to not be a valid input value} );

    return $data;
}

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

    return $self->SUPER::create( $self->_user_data_prep($data) );
}

sub edit ( $self, $data ) {
    croak( q{"email" appears to not be a valid input value} )
        if ( length $data->{email} and $data->{email} !~ /\w\@\w/ );
    return $self->save( $self->_user_data_prep($data) );
}

sub roles ( $self, $roles = undef ) {
    if ( ref $roles eq 'ARRAY' ) {
        for my $role ( @{ $self->roles } ) {
            my $selected = grep { $_ eq $role->{name} } @$roles;

            if ( not $role->{has_role} and $selected ) {
                $self->dq->sql(q{
                    INSERT INTO user_role ( user_id, role_id )
                    VALUES ( ?, ( SELECT role_id FROM role WHERE name = ? ) )
                })->run(
                    $self->id,
                    $role->{name},
                );
            }
            elsif ( $role->{has_role} and not $selected ) {
                $self->dq->sql(q{
                    DELETE FROM user_role
                    WHERE user_id = ? AND role_id = ( SELECT role_id FROM role WHERE name = ? )
                })->run(
                    $self->id,
                    $role->{name},
                );
            }
        }

        return $self;
    }
    else {
        return $self->dq->sql(q{
            SELECT
                r.name,
                (
                    SELECT 1
                    FROM user_role AS ur
                    WHERE ur.user_id = ? AND ur.role_id = r.role_id
                ) AS has_role
            FROM role AS r
            WHERE r.active
            ORDER BY r.created
        })->run( ( $self->data ) ? $self->id : -1 )->all({});
    }
}

sub churches ($self) {
    return $self->dq->sql(q{
        SELECT
            c.name,
            c.acronym,
            (
                SELECT 1
                FROM user AS u
                WHERE u.user_id = ? AND u.church_id = c.church_id
            ) AS has_church
        FROM church AS c
        WHERE c.active
        ORDER BY c.name
    })->run( ( $self->data ) ? $self->id : -1 )->all({});
}

sub church ($self) {
    return $self->dq->sql(q{
        SELECT c.church_id, c.name, c.acronym
        FROM church AS c
        JOIN user AS u USING (church_id)
        WHERE u.user_id = ?
    })->run( $self->id )->all({})->[0];
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

sub roles_to_emails ( $self, $roles ) {
    return [ map { sprintf( '%s %s <%s>', @$_ ) } @{
        $self->dq->sql(q{
            SELECT u.first_name, u.last_name, u.email
            FROM user AS u
            JOIN user_role USING (user_id)
            JOIN role AS r USING (role_id)
            WHERE r.name IN ( } . join( ', ', map { $self->dq->quote($_) } @$roles ) . q{ )
        })->run->all
    } ];
}

sub all_users_data ($self) {
    return $self->dq->sql(q{
        SELECT
            u.username,
            u.first_name,
            u.last_name,
            u.email,
            u.last_login,
            c.name AS church_name,
            c.acronym AS church_acronym,
            (
                SELECT GROUP_CONCAT( name, ', ' )
                FROM (
                    SELECT ur.user_id, r.role_id, r.name
                    FROM user_role AS ur
                    JOIN role AS r USING (role_id)
                    WHERE ur.user_id = u.user_id
                    ORDER BY r.name
                )
                GROUP BY user_id
            ) AS roles
        FROM user AS u
        JOIN church AS c USING (church_id)
        WHERE u.active
        ORDER BY church_acronym, last_name, first_name
    })->run->all({});
}

sub reset_password_email ( $self, $username = '', $email = '', $url = undef ) {
    my $user_id = $self->dq->sql(q{
        SELECT user_id
        FROM user
        WHERE LOWER(username) = ? OR LOWER(email) = ?
    })->run( lc($username), lc($email) )->value;

    croak('Failed to find user based on username or email') unless ($user_id);

    my $user = PnwQuizzing::Model::User->new->load($user_id);

    $url ||= $self->conf->get('base_url');
    $url .= '/user/reset_password/' . $user->id . '/' . substr( $user->prop('passwd'), 0, 12 );

    PnwQuizzing::Model::Email->new( type => 'reset_password' )->send({
        to   => sprintf( '%s %s <%s>', map { $user->prop($_) } qw( first_name last_name email ) ),
        data => {
            %{ $user->data },
            url => $url,
        },
    });
}

sub reset_password ( $self, $user_id, $passwd ) {
    croak('Unable to locate active user given user ID and password provided') unless (
        $self->dq->sql(q{
            SELECT COUNT(*) FROM user WHERE user_id = ? AND passwd LIKE ? AND active
        })->run( $user_id, $passwd . '%' )->value
    );

    my $user = PnwQuizzing::Model::User->new->load($user_id);
    my $new_passwd = substr( $self->bcrypt( $$ . time() . rand() ), 0, 12 );

    $user->passwd($new_passwd);
    $user->save( active => 1 );

    return $user;
}

1;
