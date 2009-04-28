use Test::More;
use lib 't/lib';

BEGIN {
   eval "use DBIx::Class";
   plan skip_all => 'DBIX::Class required' if $@;
   plan tests => 7;
}

use_ok( 'BookDB::Form::Book');

use BookDB::Schema::DB;

my $schema = BookDB::Schema::DB->connect('dbi:SQLite:t/db/book.db');
ok($schema, 'get db schema');

my $duplicate_isbn = $schema->resultset('Book')->find(1)->isbn;

my $form = BookDB::Form::Book->new(item_id => undef, schema => $schema);

ok( !$form->validate, 'Empty data' );

$form->clear;

# This is munging up the equivalent of param data from a form
my $params = {
    'title' => 'How to Test Perl Form Processors',
    'author' => 'I.M. Author',
    'isbn'   => $duplicate_isbn, 
    'publisher' => 'EreWhon Publishing',
};

ok( !$form->validate( $params ), 'duplicate isbn fails validation' );

my @errors = $form->field('isbn')->errors;

is( $errors[0], 'Value must be unique in the database', 'error message for duplicate');

my $form2 = My::Form->new( item_id => undef, schema => $schema );

ok( ! $form2->validate( $params ), 'duplicate isbn again' );

@errors = $form2->field('isbn')->errors;

is( $errors[0], 'Duplicate ISBN number', 'field error message for duplicate');



package My::Form;
use strict;
use warnings;
use base 'Form::Processor::Model::DBIC';

sub object_class{ 'Book' };

sub profile {
    return {
        fields    => [
            title     => {
               type => 'Text',
               required => 1,
            },
            author    => 'Text',
            isbn => {
               type => 'Text',
               unique => 1,
               unique_message => 'Duplicate ISBN number',
            }
        ],
    };
}
