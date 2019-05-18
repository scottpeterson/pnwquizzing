package PnwQuizzing::Control::Tool;
use Mojo::Base 'Mojolicious::Controller', -signatures;
use parent 'PnwQuizzing';
use File::Find 'find';
use Role::Tiny::With;
use Mojo::File;
use Email::Mailer;
use Text::MultiMarkdown 'markdown';
use Mojo::JSON 'decode_json';

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
    my $next_meet;

    @$next_meet{ qw(
        schedule_id
        meet location address address_url start deadline
        past_deadline
    ) } = @{
        $self->dq->sql(q{
            SELECT
                schedule_id,
                meet, location, address, address_url, start, deadline,
                STRFTIME( '%s', deadline ) < STRFTIME( '%s', 'now' ) AS past_deadline
            FROM schedule
            WHERE STRFTIME( '%s', start ) > STRFTIME( '%s', 'now' )
            ORDER BY start
            LIMIT 1
        })->run->next->row
    };

    if ( $self->param('data') ) {
        my $data = decode_json( $self->param('data') );

        # TODO: save the data to `registration`
        # TODO: add/update `schedule_church`
    }

    $self->stash(
        %$next_meet,
        no_edit =>
            $next_meet->{past_deadline} ||
            grep { $_->{has_role} and $_->{name} eq 'Coach' } @{ $self->stash('user')->roles }
    );
}

sub register_data ($self) {
    my ( %teams, %non_quizzers );

    for ( @{ $self->dq->sql(q{
        SELECT
            r.registration_id,
            r.team,
            r.name,
            r.bib,
            r.role,
            r.m_f,
            r.grade,
            r.rookie,
            r.attend,
            r.house,
            r.lunch,
            r.notes,
            r.last_modified,
            r.created
        FROM registration AS r
        JOIN user As u USING (church_id)
        WHERE u.user_id = ?
        ORDER BY team, bib
    })->run( $self->stash('user')->id )->all({}) } ) {
        if ( $_->{team} ) {
            $teams{ $_->{team} }{ $_->{bib} } = $_;
        }
        else {
            $non_quizzers{ $_->{bib} } = $_;
        }
    }

    $self->render( json => {
        church => $self->stash('user')->church,
        teams => [
            map {
                my $team = $_;
                [ map { $teams{$team}{$_} } sort { $a <=> $b } keys %{ $teams{$team} } ];
            } sort { $a <=> $b } keys %teams
        ],
        non_quizzers => [
            map { $non_quizzers{$_} } sort { $a <=> $b } keys %non_quizzers
        ],
    } );
}

1;
