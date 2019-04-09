package PnwQuizzing::Control::Tool;
use Mojo::Base 'Mojolicious::Controller', -signatures;
use parent 'PnwQuizzing';
use Role::Tiny::With;

with 'PnwQuizzing::Role::Secret';

sub hash ($self) {
    $self->stash(
        payload =>
        (
            ( $self->param('action') eq 'secret' ) ?
                join( "\n", map { $self->secret($_) } split( /\r?\n/, $self->param('payload') ) ) :
            ( $self->param('action') eq 'transcode' ) ? $self->transcode( $self->param('payload') ) :
            ( $self->param('action') eq 'translate' ) ? $self->translate( $self->param('payload') ) : ''
        )
    );
}

1;
