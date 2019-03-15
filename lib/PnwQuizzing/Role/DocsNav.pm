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

    for my $file (@files) {
        # my $content = Mojo::File->new($file)->slurp;
        # my @headers = $content =~ /^\s*(#[^\n]*)/msg;
        my $href = substr( $file, $docs_dir_length );
    }
}

1;
