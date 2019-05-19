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
    my $meet = $self->dq->sql(q{
        SELECT
            schedule_id,
            meet, location, address, address_url, start, deadline,
            STRFTIME( '%s', deadline ) < STRFTIME( '%s', 'now' ) AS past_deadline
        FROM schedule
        WHERE STRFTIME( '%s', start ) > STRFTIME( '%s', 'now' )
        ORDER BY start
        LIMIT 1
    })->run->next;

    @$next_meet{ qw(
        schedule_id
        meet location address address_url start deadline
        past_deadline
    ) } = @{ ($meet) ? $meet->row : [] };

    my $no_edit = (
        not $meet or
        $next_meet->{past_deadline} or
        not scalar( grep { $_->{has_role} and $_->{name} eq 'Coach' } @{ $self->stash('user')->roles } )
    ) ? 1 : 0;

    $self->stash(
        %$next_meet,
        no_edit => $no_edit,
    );

    if ( $self->param('data') and not $no_edit ) {
        my $data = decode_json( $self->param('data') );

        $self->dq->sql(
            'DELETE FROM registration WHERE registration_id IN (' .
                join( ', ', map { $self->dq->quote($_) } @{ $data->{deleted_persons} } )
            . ')'
        )->run if ( ref $data->{deleted_persons} eq 'ARRAY' and @{ $data->{deleted_persons} } );

        my ( $team_number, $bib );
        for my $team ( @{ $data->{teams} } ) {
            $team_number++;

            for my $quizzer (@$team) {
                unless ( $quizzer->{registration_id} ) {
                    $self->dq->sql(q{
                        INSERT INTO registration (
                            church_id,
                            role,
                            team,
                            bib,
                            name,
                            grade,
                            rookie,
                            m_f,
                            attend,
                            house,
                            lunch,
                            notes
                        ) VALUES ( ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ? )
                    })->run(
                        $self->stash('user')->church->{church_id},
                        'Quizzer',
                        $team_number,
                        ++$bib,
                        @{$quizzer}{ qw(
                            name
                            grade
                            rookie
                            m_f
                            attend
                            house
                            lunch
                            notes
                        ) },
                    );
                }
                else {
                    $self->dq->sql(q{
                        UPDATE registration SET
                            team = ?,
                            bib = ?,
                            name = ?,
                            role = ?,
                            m_f = ?,
                            attend = ?,
                            house = ?,
                            lunch = ?,
                            notes = ?
                        WHERE registration_id = ?
                    })->run(
                        $team_number,
                        ++$bib,
                        @{$quizzer}{ qw(
                            name
                            role
                            m_f
                            attend
                            house
                            lunch
                            notes
                            registration_id
                        ) },
                    );
                }
            }
        }

        $bib = 0;
        for my $non_quizzer ( @{ $data->{non_quizzers} } ) {
            unless ( $non_quizzer->{registration_id} ) {
                $self->dq->sql(q{
                    INSERT INTO registration (
                        church_id,
                        bib,
                        name,
                        role,
                        m_f,
                        attend,
                        house,
                        lunch,
                        notes
                    ) VALUES ( ?, ?, ?, ?, ?, ?, ?, ?, ? )
                })->run(
                    $self->stash('user')->church->{church_id},
                    ++$bib,
                    @{$non_quizzer}{ qw(
                        name
                        role
                        m_f
                        attend
                        house
                        lunch
                        notes
                    ) },
                );
            }
            else {
                $self->dq->sql(q{
                    UPDATE registration SET
                        bib = ?,
                        name = ?,
                        role = ?,
                        m_f = ?,
                        attend = ?,
                        house = ?,
                        lunch = ?,
                        notes = ?
                    WHERE registration_id = ?
                })->run(
                    ++$bib,
                    @{$non_quizzer}{ qw(
                        name
                        role
                        m_f
                        attend
                        house
                        lunch
                        notes
                        registration_id
                    ) },
                );
            }
        }

        if ( $data->{final_registration} ) {
            if (
                my $schedule_church_id = $self->dq->sql(q{
                    SELECT schedule_church_id
                    FROM schedule_church
                    WHERE schedule_id = ? AND church_id = ?
                })->run(
                    $next_meet->{schedule_id},
                    $self->stash('user')->church->{church_id},
                )->value
            ) {
                $self->dq->sql(q{
                    UPDATE schedule_church
                    SET last_modified = STRFTIME( '%Y-%m-%d %H:%M:%S:%s', 'NOW', 'LOCALTIME' )
                    WHERE schedule_id = ?
                })->run( $next_meet->{schedule_id} );
            }
            else {
                $self->dq->sql(q{
                    INSERT INTO schedule_church ( schedule_id, church_id ) VALUES ( ?, ? )
                })->run(
                    $next_meet->{schedule_id},
                    $self->stash('user')->church->{church_id},
                );
            }
        }
    }
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
            $teams{ $_->{team} }{ $_->{bib} || 0 } = $_;
        }
        else {
            $non_quizzers{ $_->{bib} } = $_;
        }
    }

    $self->render( json => {
        church => $self->stash('user')->church,
        teams  => [
            map {
                my $team = $_;
                [ map { $teams{$team}{$_} } sort { $a || 0 <=> $b || 0 } keys %{ $teams{$team} } ];
            } sort { $a <=> $b } keys %teams
        ],
        non_quizzers => [
            map { $non_quizzers{$_} } sort { $a <=> $b } keys %non_quizzers
        ],
    } );
}

1;
