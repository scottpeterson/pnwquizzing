package PnwQuizzing::Control::Tool;
use exact 'Mojolicious::Controller', 'PnwQuizzing';
use Email::Mailer;
use File::Find 'find';
use Mojo::File;
use Mojo::JSON 'decode_json';
use Text::CSV_XS 'csv';
use Text::MultiMarkdown 'markdown';
use PnwQuizzing::Model::Register;

with 'PnwQuizzing::Role::Secret';

has registration => sub { PnwQuizzing::Model::Register->new };

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

sub search ($self) {
    my $docs_dir = $self->conf->get( qw( config_app root_dir ) ) . '/docs';

    my @files;
    find(
        {
            wanted => sub {
                push( @files, $File::Find::name ) if (
                    /\.(?:md|csv)$/i
                );
            },
        },
        $docs_dir,
    );

    my $for    = quotemeta( $self->param('for') );
    my $length = length $docs_dir;

    $self->stash(
        files => [
            map {
                my $path = substr( $_, $length );
                ( my $name = substr( $path, 1 ) ) =~ s/\.\w+$//;

                {
                    path  => $path,
                    title => [
                        map {
                            ucfirst( join( ' ', map {
                                ( /^(?:a|an|the|and|but|or|for|nor|on|at|to|from|by)$/i ) ? $_ : ucfirst
                            } split('_') ) )
                        } split( '/', $name )
                    ],
                }
            } grep {
                my $content = Mojo::File->new($_)->slurp;
                $content =~ /$for/msi;
            } @files
        ],
    );
}

sub email ($self) {
    if ( $self->param('form_submit') ) {
        my $send_to_self = $self->param('send_to_self');
        my $roles        = $self->every_param('role');

        if ( not $send_to_self and not @$roles ) {
            $self->stash(
                message => 'No recipient targets selected. Select at least one target and resubmit.',
            );
        }
        elsif ( not $self->param('subject') ) {
            $self->stash(
                message => 'No subject provided. Enter an email subject and resubmit.',
            );
        }
        elsif ( not $self->param('payload') ) {
            $self->stash(
                message => 'No email content to send. Enter email content and resubmit.',
            );
        }
        else {
            my $to   = $self->stash('user')->roles_to_emails($roles);
            my $from = sprintf(
                '%s %s <%s>',
                @{ $self->stash('user')->data }{ qw( first_name last_name email ) },
            );
            push( @$to, $from ) if ( $send_to_self and not grep { $_ eq $from } @$to );

            Email::Mailer->new(
                from    => $from,
                to      => $to,
                subject => $self->param('subject'),
                html    => markdown( $self->param('payload') ),
            )->send;

            $self->stash(
                message => {
                    type => 'success',
                    text => 'Successfully sent email to target list.',
                }
            );
        }
    }

    $self->stash(
        roles   => $self->stash('user')->roles,
        payload => $self->param('payload'),
        subject => $self->param('subject'),
    );
}

sub register ($self) {
    my $next_meet = $self->stash('next_meet') || $self->registration->next_meet( $self->stash('user') );
    $self->stash(%$next_meet);
}

sub register_data ($self) {
    $self->render( json => {
        church => $self->stash('user')->church,
        roles  => $self->stash('user')->roles,
        %{ $self->registration->persons( $self->stash('user') ) },
    } );
}

sub register_save ($self) {
    if ( $self->param('data') ) {
        my $next_meet = $self->registration->save_registration(
            decode_json( $self->param('data') ),
            $self->stash('user'),
        );

        $self->flash(
            next_meet => $next_meet,
            message   => {
                type => 'success',
                text => 'Successfully saved quiz meet registration data.',
            }
        ) if ($next_meet);
    }

    return $self->redirect_to('/tool/register');
}

sub registration_list ($self) {
    my $list = $self->registration->current_data( $self->stash('user') );

    unless ( $self->req->url->path->trailing_slash(0)->to_string =~ /\.(\w+)$/ and lc($1) eq 'csv' ) {
        $self->stash(%$list);
    }
    else {
        $self->app->types->type( 'csv' => [ qw( text/csv application/csv ) ] );

        my @fields = qw(
            church
            role
            team
            bib
            name
            captain
            m_f
            drive
            house
            lunch
            rookie
            grade
            notes
            created
            last_modified
            registration_last_modified
        );

        @fields = grep { $_ ne 'house' } @fields unless ( $list->{house} );
        @fields = grep { $_ ne 'lunch' } @fields unless ( $list->{lunch} );

        my ( $last_team, $bib ) = ( '', 0 );

        csv( out => \my $csv, in => [
            [ map { join( ' ', map { ucfirst } split('_') ) } @fields],
            map {
                $_->{created}                    =~ s/:\d{10}$// if ( $_->{created} );
                $_->{last_modified}              =~ s/:\d{10}$// if ( $_->{last_modified} );
                $_->{registration_last_modified} =~ s/:\d{10}$// if ( $_->{registration_last_modified} );

                if ( not $_->{role} or $_->{role} ne 'Quizzer' ) {
                    $_->{team}   = '';
                    $_->{bib}    = '';
                    $_->{rookie} = '';
                    $_->{grade}  = '';
                    $_->{drive}  = ( $_->{drive} ) ? 'Yes' : 'No';
                }
                else {
                    $_->{team} = ( $_->{acronym} || '' ) . ' ' . ( $_->{team} || '' );
                    $_->{rookie} //= 0;

                    if ( $last_team ne $_->{team} ) {
                        $last_team = $_->{team};
                        $bib = 0;
                    }
                    $_->{bib} = ++$bib;
                    $_->{rookie} = ( $_->{rookie} ) ? 'Yes' : 'No';
                }

                $_->{house} = ( $_->{house} ) ? 'Yes' : 'No';

                [ map { defined ? $_ : '' } @$_{@fields} ]
            }
            grep { $_->{attend} }
            @{ $list->{current_data}{quizzers} },
            @{ $list->{current_data}{non_quizzers} }
        ] );

        $self->render( text => $csv );
    }
}

1;
