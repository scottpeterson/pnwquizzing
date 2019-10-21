package PnwQuizzing::Role::Secret;
use exact -role;

with qw( PnwQuizzing::Role::Bcrypt PnwQuizzing::Role::Database );

sub secret ( $self, $phrase ) {
    my $hash = $self->dq->sql('SELECT hash FROM secret WHERE phrase = ?')->run($phrase)->value;
    unless ($hash) {
        $hash = substr( $self->bcrypt($phrase), 0, 7 );
        $self->dq->sql('INSERT INTO secret ( hash, phrase ) VALUES ( ?, ? )')->run( $hash, $phrase );
    }

    return $hash;
}

sub desecret ( $self, $hash ) {
    return $self->dq->sql('SELECT phrase FROM secret WHERE hash = ?')->run($hash)->value;
}

sub translate ( $self, $content ) {
    $content =~ s/\b([0-9a-f]{7})\b/ $self->desecret($1) || $1 /ge;
    return $content;
}

sub transcode ( $self, $content ) {
    $content =~ s/\b$_->{phrase}\b/$_->{hash}/g for ( @{
        $self->dq->sql('SELECT phrase, hash FROM secret ORDER BY LENGTH(phrase) DESC')->run->all({})
    } );

    return $content;
}

1;
