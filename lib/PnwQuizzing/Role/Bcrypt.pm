package PnwQuizzing::Role::Bcrypt;
use exact -role;
use Digest;

with 'PnwQuizzing::Role::Conf';

sub bcrypt ( $self, $input ) {
    return Digest
        ->new( 'Bcrypt', %{ $self->conf->get('bcrypt') } )
        ->add($input)->hexdigest;
}

1;
