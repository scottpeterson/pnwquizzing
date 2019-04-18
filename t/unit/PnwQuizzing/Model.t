use Mojo::Base -strict;
use Config::App;
use Test::Most;

use_ok('PnwQuizzing::Model');

my $obj;
lives_ok( sub { $obj = PnwQuizzing::Model->new }, 'new()' );
ok( $obj->can($_), "can $_()" ) for ( qw(
    data
    name
    create
    load
    prop
    id
    save
) );

my $phrase = '__test_pnwquizzing_model_' . $$;
my $data   = { hash => $phrase, phrase => $phrase };

throws_ok(
    sub { $obj->create($data) },
    qr/Cannot create\(\) without has "name"/,
    'create() without name throws',
);

throws_ok(
    sub { $obj->load(1) },
    qr/Cannot load\(\) without has "name"/,
    'load() without name throws',
);

throws_ok(
    sub { $obj->save },
    qr/Cannot save\(\) without has "name"/,
    'save() without name throws',
);

throws_ok(
    sub { $obj->id },
    qr/Cannot id\(\) without has "name"/,
    'id() without name throws',
);

lives_ok( sub { $obj->name('secret') }, 'set name()' );
lives_ok( sub { $obj = $obj->create($data) }, 'create() with name' );

my $id;
like( $id = $obj->id, qr/^\d+$/, 'id() returns primary key' );
lives_ok( sub { $obj->save( hash => $phrase . '_2' ) }, 'save()' );
lives_ok( sub { $obj = $obj->load($id) }, 'new()->load()' );
is( $obj->prop('hash'), $phrase . '_2', 'prop()' );

throws_ok(
    sub { $obj->create($data) },
    qr/UNIQUE constraint failed/,
    'create() with duplicate name throws'
);

$obj->dq->sql('DELETE FROM secret WHERE phrase = ?')->run($phrase);

done_testing();
