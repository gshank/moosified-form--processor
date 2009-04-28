use strict;
use warnings;
use Test::More;
use lib 't/lib';

BEGIN {
   eval "use DBIx::Class";
   plan skip_all => 'DBIX::Class required' if $@;
   plan tests => 6;
}

use_ok( 'Form::Processor' );

use_ok( 'BookDB::Form::Borrower');

use_ok( 'BookDB::Schema::DB');
use DBIx::Class::ResultClass::HashRefInflator;

my $schema = BookDB::Schema::DB->connect('dbi:SQLite:t/db/book.db');
ok($schema, 'get db schema');

my $rs = $schema->resultset('Borrower')->find(2)->books;
$rs->result_class('DBIx::Class::ResultClass::HashRefInflator');
my @results = $rs->all;

my $form = BookDB::Form::Borrower->new(item_id => 2, schema => $schema);
ok( $form, 'get borrower form');

# this doesn't actually DO anything... Can't handle anywhere, but
# inflating result of has_many rel for future use
my $value = $form->field('books')->value;
my $count = @{$value};
is( $count, 3, 'get array of 3 values for books');
