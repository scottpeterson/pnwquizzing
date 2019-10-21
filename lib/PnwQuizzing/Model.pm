package PnwQuizzing::Model;
use exact 'PnwQuizzing';

has data => undef;
has name => undef;

sub create ( $self, $data ) {
    croak('Cannot create() without has "name"') unless ( $self->name );

    my @columns = keys %$data;

    $self->dq->sql(
        'INSERT INTO ' . $self->name . '( ' . join( ', ', map { $self->dq->quote($_) } @columns ) . ' ) ' .
        'VALUES ( ' . join( ', ', ('?') x @columns ) . ' )'
    )->run(
        map { $data->{$_} } @columns
    );

    $self->load( $self->dq->sqlite_last_insert_rowid );
    return $self;
}

sub load ( $self, $search ) {
    croak('Cannot load() without has "name"') unless ( $self->name );

    $search = { $self->name . '_id' => $search } unless ( ref $search );

    my $data = $self->dq->get( $self->name )->where($search)->run->next;
    croak('Failed to load ' . $self->name ) unless ($data);

    $self->data( $data->data );
    return $self;
}

sub prop ( $self, @input ) {
    if ( ref $input[0] eq 'HASH' ) {
        $self->data->{$_} = $input[0]->{$_} for ( keys %{ $input[0] } );
    }
    elsif ( ref $input[0] eq 'ARRAY' ) {
        my @data = map { $self->data->{$_} } @input;
        return (wantarray) ? @data : \@data;
    }
    elsif ( @input == 1 ) {
        return $self->data->{ $input[0] };
    }
    elsif ( not @input % 2 ) {
        my %input = @input;
        $self->data->{$_} = $input{$_} for ( keys %input );
    }
    else {
        croak('Bad input in call to prop()');
    }

    return $self;
}

sub id ($self) {
    croak('Cannot id() without has "name"') unless ( $self->name );
    croak('Cannot id() on unloaded object') unless ( $self->data );
    croak('No id available on loaded object') unless ( $self->data->{ $self->name . '_id' } );

    return $self->data->{ $self->name . '_id' };
}

sub save ( $self, @input ) {
    croak('Cannot save() without has "name"') unless ( $self->name );

    if (@input) {
        try {
            $self->prop(@input);
        }
        catch ($e) {
            croak( ( $e =~ /^Bad input/ ) ? 'Bad input in call to save()' : $e );
        };
    }

    my %data    = %{ $self->data };
    my $id      = delete $data{ $self->name . '_id' };
    my @columns = keys %data;

    $self->dq->sql(
        'UPDATE ' . $self->name .
        ' SET ' . join( ', ',
            map {
                $self->dq->quote($_) . ' = ' .
                ( ( ref $data{$_} ) ? ${ $data{$_} } : $self->dq->quote( $data{$_} ) )
            } @columns
        ) .
        ' WHERE ' . $self->name . '_id = ?'
    )->run($id);

    return $self;
}

1;
