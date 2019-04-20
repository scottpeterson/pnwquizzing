package PnwQuizzing::Control::Tool;
use Mojo::Base 'Mojolicious::Controller', -signatures;
use parent 'PnwQuizzing';
use Role::Tiny::With;

with 'PnwQuizzing::Role::Secret';

sub hash ($self) {
    my $action = $self->param('action') || '';

    $self->stash(
        payload =>
        (
            ( $action eq 'secret' ) ?
                join( "\n", map { $self->secret($_) } split( /\r?\n/, $self->param('payload') ) ) :
            ( $action eq 'transcode' ) ? $self->transcode( $self->param('payload') ) :
            ( $action eq 'translate' ) ? $self->translate( $self->param('payload') ) : ''
        )
    );
}

1;
