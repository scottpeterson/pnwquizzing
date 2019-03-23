package PnwQuizzing::Role::Bcrypt;
use Mojo::Base -role, -signatures;
use Role::Tiny::With;

with 'PnwQuizzing::Role::Conf';

sub bcrypt ( $self, $input ) {
    return Digest
        ->new( 'Bcrypt', %{ $self->conf->get('bcrypt') } )
        ->add($input)->hexdigest;
}

1;
