use strict;
use warnings;
use Test::More;
use lib 't/lib';

BEGIN {
   eval "use DBIx::Class";
   plan skip_all => 'DBIX::Class required' if $@;
   plan tests => 18;
}

use_ok( 'Form::Processor' );

use_ok( 'BookDB::Form::Book');

use_ok( 'BookDB::Schema::DB');

my $schema = BookDB::Schema::DB->connect('dbi:SQLite:t/db/book.db');
ok($schema, 'get db schema');

my $book_id = 1;

my $form = BookDB::Form::Book->new(item_id => undef, schema => $schema);

ok( !$form->validate, 'Empty data' );

$form->clear;

# This is munging up the equivalent of param data from a form
my $good = {
    'title' => 'How to Test Perl Form Processors',
    'author' => 'I.M. Author',
    'books_genres' => [2, 4],
    'format'       => 2,
    'isbn'   => '123-02345-0502-2' ,
    'publisher' => 'EreWhon Publishing',
};

ok( $form->validate( $good ), 'Good data' );

ok( $form->update_model, 'Update validated data');

my $book = $form->item;
END { $book->delete };

ok ($book, 'get book object from form');

my $num_genres = $book->genres->count;
is( $num_genres, 2, 'multiple select list updated ok');

is( $form->field('format')->value, 2, 'get value for format' );

my $id = $book->id;
$form->clear;

my $bad_1 = {
    notitle => 'not req',
    silly_field   => 4,
};

ok( !$form->validate( $bad_1 ), 'bad 1' );
$form->clear;

my $bad_2 = {
    'title' => "Another Silly Test Book",
    'author' => "C. Foolish",
    'year' => '1590',
    'pages' => 'too few',
    'format' => '22',
};

ok( !$form->validate( $bad_2 ), 'bad 2');

ok( $form->field('year')->has_error, 'year has error' );

ok( $form->field('pages')->has_error, 'pages has error' );

ok( !$form->field('author')->has_error, 'author has no error' );

ok( $form->field('format')->has_error, 'format has error' );

$form->clear;

$form = BookDB::Form::Book->new(item => $book, schema => $schema);
ok( $form, 'create form from db object');

my $genres_field = $form->field('books_genres');
is_deeply( sort $genres_field->value, [2, 4], 'value of multiple field is correct');

