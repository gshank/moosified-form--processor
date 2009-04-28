use strict;
use warnings;

use Test::More;
my $tests = 5;
plan tests => $tests;

my $class = 'Form::Processor::Field::Year';

my $name = $1 if $class =~ /::([^:]+)$/;

use_ok( $class );
my $field = $class->new(
    name    => 'test_field',
    type    => $name,
    form    => undef,
);



ok( defined $field,  'new() called' );

$field->input( 0 );
$field->validate_field;
ok( $field->has_error, '0 is bad year' );

$field->input( (localtime)[5] + 1900 );
$field->validate_field;
ok ( !$field->has_error, 'Now is just a fine year' );


$field->input( 2100 );
$field->validate_field;
ok( $field->has_error, '2100 makes the author really old' );

