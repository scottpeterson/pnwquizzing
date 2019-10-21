package PnwQuizzing::Role::DocsNav;
use exaxct -role;
use File::Find 'find';
use Mojo::File;

with 'PnwQuizzing::Role::Conf';

sub generate_docs_nav ($self) {
    my $docs_dir = $self->conf->get( qw( config_app root_dir ) ) . '/docs';
    my @files;
    find(
        {
            wanted => sub {
                push( @files, $File::Find::name ) if (
                    /\.(?:md|csv|pdf|xls|xlsx|doc|docx|ppt|pptx)$/i
                );
            },
            preprocess => sub {
                sort {
                    ( $a eq 'index.md' and $b ne 'index.md' ) ? 0 :
                    ( $a ne 'index.md' and $b eq 'index.md' ) ? 1 :
                    lc $a cmp lc $b
                } @_;
            },
        },
        $docs_dir,
    );

    my $docs_dir_length = length($docs_dir) + 1;
    my $docs_nav        = [];

    for (@files) {
        next if (m|/_|);

        my $href = substr( $_, $docs_dir_length );
        my @path = ( 'Home Page', map {
            ucfirst( join( ' ', map {
                ( /^(?:a|an|the|and|but|or|for|nor|on|at|to|from|by)$/i ) ? $_ : ucfirst
            } split('_') ) )
        } split( /\/|\.[^\.]+$/, $href ) );

        my $type = (/\.([^\.]+)$/) ? lc($1) : '';
        $type =~ s/x$// if ( length $type == 4 );

        my $name  = pop @path;
        my $title = $name;

        if ( $type eq 'md' ) {
            my $content = Mojo::File->new($_)->slurp;
            my @headers = $content =~ /^\s*(#[^\n]*)/msg;
            ( $title = $headers[0] ) =~ s/^\s*#+\s*//g if ( $headers[0] );
        }

        my $set = $docs_nav;
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
            $parent->[-1]{href}  = '/' . $href;
            $parent->[-1]{title} = $title;
            delete $parent->[-1]{nodes};
        }
        else {
            push( @$set, {
                name  => $name,
                href  => '/' . $href,
                title => $title,
                type  => $type,
            } );
        }
    }

    push( @$docs_nav, @{ delete $docs_nav->[0]{nodes} } );

    $docs_nav->[0]{name}  = delete $docs_nav->[0]{folder};
    $docs_nav->[0]{href}  = '/';
    $docs_nav->[0]{title} = 'PNW Bible Quizzing Home Page';
    $docs_nav->[0]{type}  = 'md';

    return $docs_nav;
}

1;
