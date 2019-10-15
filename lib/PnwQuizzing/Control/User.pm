package PnwQuizzing::Control::User;
use Mojo::Base 'Mojolicious::Controller', -signatures;
use parent 'PnwQuizzing';
use PnwQuizzing::Model::User;
use TryCatch;

sub login ($self) {
    my $user = PnwQuizzing::Model::User->new;

    try {
        $user = $user->login( map { $self->param($_) } qw( username passwd ) );
    }
    catch {
        $self->info('Login failure (in controller)');
        $self->flash( message =>
            'Login failed. Please try again, or try the ' .
            '<a href="' . $self->url_for('/user/reset_password') . '">Reset Password page</a>.'
        );
        return $self->redirect_to('/');
    }

    $self->_login($user);
    return $self->redirect_to('/');
}

sub _login ( $self, $user ) {
    $self->info( 'Login success for: ' . $user->prop('username') );
    $self->session(
        'user_id'           => $user->id,
        'last_request_time' => time,
    );
}

sub logout ($self) {
    $self->info(
        'Logout requested from: ' .
        ( ( $self->stash('user') ) ? $self->stash('user')->prop('username') : '(Unlogged-in user)' )
    );
    $self->session(
        'user_id'           => undef,
        'last_request_time' => undef,
    );

    return $self->redirect_to('/');
}

sub account ($self) {
    my $user = PnwQuizzing::Model::User->new;

    if ( $self->param('form_submit') ) {
        my %form_params = map { $_ => $self->param($_) } qw(
            username
            passwd
            first_name
            last_name
            email
            church
        );

        my $handle_user_error = sub ($e) {
            $e =~ s/\s+at\s+(?:(?!\s+at\s+).)*[\r\n]*$//;
            $e =~ s/^"([^""]+)"/ '"' . join( ' ', map { ucfirst($_) } split( '_', $1 ) ) . '"' /e;
            $e .= '. Please try again.';

            $self->info('User create failure');
            $self->stash(
                message => $e,
                %form_params,
            );
        };

        unless ( $self->stash('user') ) {
            try {
                $user = $user->create( { %form_params, active => 0 });
                $user->roles( $self->every_param('role') );
            }
            catch ($e) {
                $handle_user_error->($e);
            }

            if ( $user and $user->data ) {
                my $url = $self->req->url->to_abs;
                $user->verify_email( $url->protocol . '://' . $url->host_port );
                $self->stash( successful_create_user => 1 );
            }
        }
        else {
            try {
                $self->stash('user')->edit( \%form_params );
                $self->stash('user')->roles( $self->every_param('role') );
                $self->stash(
                    message => {
                        type => 'success',
                        text => 'Successfully edited site account profile.',
                    }
                );
            }
            catch ($e) {
                $handle_user_error->($e);
            }
        }
    }

    $user = $self->stash('user') if ( $self->stash('user') );
    $self->stash(
        churches => $user->churches,
        roles    => $user->roles,
    );
}

sub verify ($self) {
    if (
        PnwQuizzing::Model::User->new->verify(
            $self->stash('verify_user_id'),
            $self->stash('verify_passwd'),
        )
    ) {
        $self->flash(
            message => {
                type => 'success',
                text => 'Successfully verified this user account. Please now login with your credentials.',
            }
        );
    }
    else {
        $self->flash( message => 'Unable to verify user account using the link provided.' );
    }

    return $self->redirect_to('/');
}

sub list ($self) {
    $self->stash( users => PnwQuizzing::Model::User->new->all_users_data );
}

sub reset_password ($self) {
    return $self->redirect_to('/') if ( $self->stash('user') );

    if ( $self->param('username') or $self->param('email') ) {
        my $url = $self->req->url->to_abs;
        try {
            PnwQuizzing::Model::User->new->reset_password_email(
                $self->param('username'),
                $self->param('email'),
                $url->protocol . '://' . $url->host_port,
            );
            $self->stash(
                message => {
                    type => 'success',
                    text => 'Successfully send a reset password confirmation email.',
                }
            );
        }
        catch ($e) {
            $self->warn( $e->message );
            $self->stash( message => 'Unable to locate user account using the input values provided.' );
        }
    }
    elsif ( $self->param('form_post') ) {
        $self->stash( message => 'Unable to locate user account using the input values provided.' );
    }
    elsif ( $self->stash('reset_user_id') and $self->stash('reset_passwd') ) {
        try {
            my $new_passwd = PnwQuizzing::Model::User->new->reset_password(
                $self->stash('reset_user_id'),
                $self->stash('reset_passwd'),
            );

            $self->_login( PnwQuizzing::Model::User->new->load( $self->stash('reset_user_id') ) );
            $self->session_login;
            $self->stash( new_passwd => $new_passwd );
        }
        catch ($e) {
            $self->warn( $e->message );
            $self->stash( message =>
                'Unable to reset user password. ' .
                'This is likely due to an expired link in an email. ' .
                'Please try filling out the form again for a fresh reset link.'
            );
        }
    }
}

1;
