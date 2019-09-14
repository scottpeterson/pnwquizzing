package PnwQuizzing::Model::Register;
use Mojo::Base 'PnwQuizzing::Model', -signatures;
use PnwQuizzing::Model::Email;

my $singleton;

sub new ( $self, @params ) {
    return $singleton //= $self->SUPER::new(@params);
}

sub next_meet ( $self, $user = undef ) {
    my $next_meet;
    my $meet = $self->dq->sql(q{
        SELECT
            schedule_id,
            meet, location, address, address_url, start, deadline,
            STRFTIME( '%s', deadline ) < STRFTIME( '%s', 'NOW', 'LOCALTIME' ) AS past_deadline,
            STRFTIME( '%s', 'NOW', 'LOCALTIME' ) > strftime( '%s', start, '-2 month' ) AS notice_active,
            ROUND( JULIANDAY(deadline) - JULIANDAY( 'NOW', 'LOCALTIME' ) ) AS days_before_deadline
        FROM schedule
        WHERE STRFTIME( '%s', start ) > STRFTIME( '%s', 'NOW', 'LOCALTIME' )
        ORDER BY start
        LIMIT 1
    })->run->next;

    @$next_meet{ qw(
        schedule_id
        meet location address address_url start deadline
        past_deadline notice_active days_before_deadline
    ) } = @{ ($meet) ? $meet->row : [] };

    if ($user) {
        $next_meet->{no_edit} = (
            not $meet or
            $next_meet->{past_deadline} or
            not scalar( grep { $_->{has_role} and $_->{name} eq 'Coach' } @{ $user->roles } )
        ) ? 1 : 0;
    }

    return $next_meet;
}

sub show_notice ( $self, $user, $url ) {
    my $next_meet = $self->next_meet($user);

    return if (
        $next_meet->{no_edit} or not $next_meet->{notice_active} or
        $self->dq->sql(q{
            SELECT last_modified
            FROM schedule_church
            WHERE schedule_id = ? AND church_id = ?
        })->run(
            $next_meet->{schedule_id},
            $user->church->{church_id},
        )->value
    );

    return {
        type => 'notice',
        text => q{
            It appears you
            (as a coach representing } . $user->church->{acronym} . q{)
            have not registered for the next upcoming quiz meet.
            Please register before the deadline. To register, visit the
            <a href="} . $url . q{">Online Registration System</a>.
        },
    };
}

sub persons ( $self, $user ) {
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
    })->run( $user->id )->all({}) } ) {
        if ( $_->{team} ) {
            $teams{ $_->{team} }{ $_->{bib} || 0 } = $_;
        }
        else {
            $non_quizzers{ $_->{bib} } = $_;
        }
    }

    return {
        teams => [
            map {
                my $team = $_;
                [ map { $teams{$team}{$_} } sort { $a || 0 <=> $b || 0 } keys %{ $teams{$team} } ];
            } sort { $a <=> $b } keys %teams
        ],
        non_quizzers => [
            map { $non_quizzers{$_} } sort { $a <=> $b } keys %non_quizzers
        ],
    };
}

sub save_registration ( $self, $data, $user, $next_meet = undef ) {
    $next_meet //= $self->next_meet($user);
    return if ( $next_meet->{no_edit} );

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
                    $user->church->{church_id},
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
                        rookie = ?,
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
                        rookie
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
                $user->church->{church_id},
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
                $user->church->{church_id},
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
                $user->church->{church_id},
            );
        }
    }

    return $next_meet;
}

sub current_data ( $self, $user ) {
    my $next_meet = $self->next_meet($user);

    my $current_data;
    push( @{ $current_data->{ ( $_->{team} ) ? 'quizzers' : 'non_quizzers' } }, $_ ) for ( @{
        $self->dq->sql(q{
            SELECT
                c.name AS church,
                c.acronym,
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
                r.created,
                (
                    SELECT sc.last_modified
                    FROM schedule_church AS sc
                    WHERE sc.schedule_id = ? AND sc.church_id = c.church_id
                ) AS registration_last_modified
            FROM registration AS r
            JOIN church AS c USING (church_id)
            ORDER BY
                c.acronym,
                CASE WHEN r.team IS NOT NULL THEN r.team ELSE r.role END,
                CASE WHEN r.team IS NOT NULL THEN r.bib ELSE NULL END,
                r.name
        })->run( $next_meet->{schedule_id} )->all({})
    } );

    return {
        %$next_meet,
        current_data => $current_data,
    };
}

sub send_reminders ($self) {
    my $email                 = PnwQuizzing::Model::Email->new( type => 'registration_reminder' );
    my $next_meet             = $self->next_meet;
    my @registered_church_ids = map { @$_ } @{
        $self->dq->sql(q{
            SELECT church_id
            FROM schedule_church
            WHERE schedule_id = ?
        })->run( $next_meet->{schedule_id} )->all
    };

    if ( $next_meet->{days_before_deadline} == 10 or $next_meet->{days_before_deadline} == 2 ) {
        for my $user ( @{ $self->dq->sql(
            q{
                SELECT c.church_id, c.name AS church, c.acronym, u.first_name, u.last_name, u.email
                FROM user AS u
            } .
            (
                ( $next_meet->{days_before_deadline} == 2 )
                    ? q{
                        JOIN church AS c USING (church_id)
                        WHERE c.active AND u.active
                    }
                    : q{
                        JOIN user_role AS ur USING (user_id)
                        JOIN role AS r USING (role_id)
                        JOIN church AS c USING (church_id)
                        WHERE r.name = 'Coach' AND c.active AND u.active
                    }
            )
        )->run->all({}) } ) {
            next if ( grep { $_ == $user->{church_id} } @registered_church_ids );

            $email->send({
                to   => sprintf( '%s %s <%s>', map { $user->{$_} } qw( first_name last_name email ) ),
                data => {
                    %{$user},
                    %{$next_meet},
                    url => $self->conf->get('base_url'),
                },
            });
        }
    }
}

1;
