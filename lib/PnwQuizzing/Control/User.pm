package PnwQuizzing::Control::User;
use Mojo::Base 'Mojolicious::Controller', -signatures;
use parent 'PnwQuizzing';
use Role::Tiny::With;
use PnwQuizzing::Model::User;
use TryCatch;

with 'PnwQuizzing::Role::DocsNav';

sub login ($self) {
    my $user = PnwQuizzing::Model::User->new;

    try {
        $user = $user->login( map { $self->param($_) } qw( username passwd ) );
    }
    catch {
        $self->info('Login failure (in controller)');
        $self->flash( message => 'Login failed. Please try again.' );
        return $self->redirect_to('/');
    }

    $self->info( 'Login success for: ' . $user->prop('username') );

    $self->session(
        'user_id'           => $user->id,
        'last_request_time' => time,
    );

    return $self->redirect_to('/');
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

sub signup ($self) {
    $self->stash( docs_nav => $self->generate_docs_nav );
}

sub create ($self) {
    my $user;

    try {
        $user = PnwQuizzing::Model::User->new->create({
            map { $_ => $self->param($_) } qw(
                username
                passwd
                first_name
                last_name
                email
            )
        });
    }
    catch ($e) {
        $e =~ s/\s+at\s+(?:(?!\s+at\s+).)*[\r\n]*$//;

        $self->info('User create failure');
        $self->flash( message => $e ); # TODO: cleanup error reporting messaging

        return $self->redirect_to('/user/signup');
    }

    return $self->redirect_to('/');
}

1;
