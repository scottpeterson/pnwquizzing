package PnwQuizzing::Model::Email;
use exact 'PnwQuizzing::Model';
use Email::Mailer;

with 'PnwQuizzing::Role::Template';

has type    => undef;
has subject => undef;
has html    => undef;

my $settings;
my $root_dir;
my $mailer;

sub new ( $self, @params ) {
    $self = $self->SUPER::new(@params);
    croak('Failed new() because "type" must be defined') unless ( $self->type );

    $settings ||= $self->tt_settings('email');
    $root_dir ||= $self->conf->get( 'config_app', 'root_dir' );
    $mailer   ||= Email::Mailer->new(
        from    => $self->conf->get( qw( email from ) ),
        process => sub {
            my ( $template, $data ) = @_;
            my $content;
            $self->tt('email')->process( \$template, $data, \$content );
            return $content;
        },
    );

    my ($file) =
        grep { -f $_ }
        map { join( '/', $_, $self->type . '.html.tt' ) }
        @{ $settings->{config}{INCLUDE_PATH} };

    croak( 'Failed to find email template of type: ' . $self->type ) unless ($file);

    open( my $html, '<', $file ) or croak("Unable to open email template: $file");
    $html = join( '', <$html> );
    my $subject = ( $html =~ s|<title>(.*?)</title>||ms ) ? $1 : '';
    $subject =~ s/\s+/ /msg;
    $subject =~ s/(^\s|\s$)//msg;

    $self->subject($subject);
    $self->html($html);

    return $self;
}

sub send ( $self, $data ) {
    $data->{subject} = \$self->subject;
    $data->{html}    = \$self->html;

    return undef unless ( $self->conf->get( 'email', 'active' ) );
    $self->info(
        'Sent email "' . $self->type . '"' . (
            ( $data->{to} and not ref $data->{to} ) ? ' to: ' . $data->{to}               :
            ( ref $data->{to} eq 'ARRAY'          ) ? ' to: ' . join( ', ', $data->{to} ) : ''
        )
    );
    return $mailer->send($data);
}

1;
