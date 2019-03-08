package PnwQuizzing::Roles::Template;
use Mojo::Base -role, -signatures;
use Role::Tiny::With;
use Template;

with 'PnwQuizzing::Roles::Conf';

has version => time;

{
    my $tt;
    sub tt ( $self, $type = 'web' ) {
        unless ( $tt->{$type} ) {
            my $settings = $self->tt_settings($type);
            $tt->{$type} = Template->new( $settings->{config} );
            $settings->{context}->( $tt->{$type}->context );
        }
        return $tt->{$type};
    }
}

sub tt_settings ( $self, $type = 'web' ) {
    my $tt_conf = $self->conf->get('template');

    return {
        config => {
            INCLUDE_PATH => $tt_conf->{$type}{include_path},
            COMPILE_EXT  => $tt_conf->{compile_ext},
            COMPILE_DIR  => $tt_conf->{compile_dir},
            WRAPPER      => $tt_conf->{$type}{wrapper},
            FILTERS => {
                ucfirst => sub { return ucfirst shift },
                round   => sub { return int( $_[0] + 0.5 ) },
            },
            ENCODING  => 'utf8',
            CONSTANTS => {
                version => $self->version,
            },
        },
        context => sub ($context) {
            $context->define_vmethod( 'scalar', 'lower',   sub { return lc( $_[0] ) } );
            $context->define_vmethod( 'scalar', 'upper',   sub { return uc( $_[0] ) } );
            $context->define_vmethod( 'scalar', 'ucfirst', sub { return ucfirst( lc( $_[0] ) ) } );

            $context->define_vmethod( $_, 'ref', sub { return ref( $_[0] ) } ) for ( qw( scalar list hash ) );

            $context->define_vmethod( 'scalar', 'commify', sub {
                return scalar( reverse join( ',', unpack( '(A3)*', scalar( reverse $_[0] ) ) ) );
            } );

            $context->define_vmethod( 'list', 'sort_by', sub {
                my ( $arrayref, $sort_by, $sort_order ) = @_;
                return $arrayref unless ($sort_by);

                return [ sort {
                    my ( $c, $d ) = ( $a, $b );
                    ( $c, $d ) = ( $d, $c ) if ( $sort_order and $sort_order eq 'desc' );

                    ( $c->{$sort_by} =~ /^\d+$/ and $d->{$sort_by} =~ /^\d+$/ )
                        ? $c->{$sort_by} <=> $d->{$sort_by}
                        : $c->{$sort_by} cmp $d->{$sort_by}
                } @$arrayref ];
            } );
        },
    };
}

1;
