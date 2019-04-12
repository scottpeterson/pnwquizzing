package PnwQuizzing::Role::DocsNav;
use Mojo::Base -role, -signatures;
use Role::Tiny::With;
use File::Find 'find';
use Mojo::File;

with 'PnwQuizzing::Role::Conf';

sub generate_docs_nav ($self) {
    my $docs_dir = $self->conf->get( qw( config_app root_dir ) ) . '/docs';
    my @files;
    find(
        {
            wanted     => sub { push( @files, $File::Find::name ) if (/\.md$/i) },
            preprocess => sub {
                sort {
                    ( $a eq 'index.md' and $b ne 'index.md' ) ? 0 :
                    ( $a ne 'index.md' and $b eq 'index.md' ) ? 1 :
                    $a cmp $b
                } @_;
            },
        },
        $docs_dir,
    );

    my $docs_dir_length = length($docs_dir) + 1;
    my $docs_nav        = [];

    for (@files) {
        my $content = Mojo::File->new($_)->slurp;
        my @headers = $content =~ /^\s*(#[^\n]*)/msg;
        my $href    = substr( $_, $docs_dir_length );
        ( my $title = $headers[0] ) =~ s/^\s*#+\s*//g;

        my @path = ( 'Home Page', map {
            join( ' ', map { ucfirst } split('_') )
        } split( /\/|\.md$/, $href ) );

        my $name = pop @path;
        my $set  = $docs_nav;
        my $parent;

        for my $node (@path) {
            my @items = grep { $_->{folder} and $_->{folder} eq $node } @$set;
            $parent   = $set;

            if (@items) {
                $items[0]->{nodes} = [] unless ( $items[0]->{nodes} );
                $set = $items[0]->{nodes};
            }
            else {
                my $nodes = [];
                push( @$set, {
                    folder => $node,
                    nodes  => $nodes,
                } );
                $set = $nodes;
            }
        }

        if ( $name eq 'Index' ) {
            $parent->[-1]{href}  = $href;
            $parent->[-1]{title} = $title;
            delete $parent->[-1]{nodes};
        }
        else {
            push( @$set, {
                name  => $name,
                href  => '/' . $href,
                title => $title,
            } );
        }
    }

    push( @$docs_nav, @{ delete $docs_nav->[0]{nodes} } );

    $docs_nav->[0]{href}  = '/';
    $docs_nav->[0]{title} = 'PNW Bible Quizzing Home Page';

    return $docs_nav;
}

1;
