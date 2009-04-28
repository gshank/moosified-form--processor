use Test::More;
use lib 't/lib';

BEGIN {
   eval "use DBIx::Class";
   plan skip_all => 'DBIX::Class required' if $@;
   plan tests => 13;
}

use_ok( 'Form::Processor' );

use_ok( 'BookDB::Form::BookAuto');

use_ok( 'BookDB::Schema::DB');

my $schema = BookDB::Schema::DB->connect('dbi:SQLite:t/db/book.db');
ok($schema, 'get db schema');

my $book_id = 1;

my $form = BookDB::Form::BookAuto->new(item_id => undef, schema => $schema);

ok( !$form->validate, 'Empty data' );

$form->clear;

# This is munging up the equivalent of param data from a form
my $good = {
    'book.title' => 'How to Test Perl Form Processors',
    'book.author' => 'I.M. Author',
    'book.isbn'   => '123-02345-0502-2' ,
    'book.publisher' => 'EreWhon Publishing',
};

ok( $form->validate( $good ), 'Good data' );

ok( $form->update_model, 'Update validated data');

my $book = $form->item;
ok ($book, 'get book object from form');

# clean up book db & form
$book->delete;
$form->clear;

my $bad_1 = {
    notitle => 'not req',
    silly_field   => 4,
};

ok( !$form->validate( $bad_1 ), 'bad 1' );
$form->clear;

my $bad_2 = {
    'book.title' => "Another Silly Test Book",
    'book.author' => "C. Foolish",
    'book.year' => '1590',
    'book.pages' => 'too few',
    'book.format' => '22',
};

ok( !$form->validate( $bad_2 ), 'bad 2');

ok( $form->field('year')->has_error, 'year has error' );

ok( !$form->field('pages')->has_error, 'pages has no error' );

ok( !$form->field('author')->has_error, 'author has no error' );

$form->clear;


