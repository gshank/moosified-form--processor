use strict;
use warnings;

use Test::More;
my $tests = 9;
plan tests => $tests;

my $class = 'Form::Processor::Field::Month';

my $name = $1 if $class =~ /::([^:]+)$/;

use_ok( $class );
my $field = $class->new(
    name    => 'test_field',
    type    => $name,
    form    => undef,
);

ok( defined $field,  'new() called' );

$field->input( 1 );
$field->validate_field;
ok( !$field->has_error, '1 in range' );

$field->input( 12 );
$field->validate_field;
ok( !$field->has_error, '59 in range' );

$field->input( 6 );
$field->validate_field;
ok( !$field->has_error, '6 in range' );

$field->input( 0  );
$field->validate_field;
ok( $field->has_error, '0 out of range' );


$field->input( 13 );
$field->validate_field;
ok( $field->has_error, '60 out of range' );


$field->input( 'March' );
$field->validate_field;
ok( $field->has_error, 'March is not numeric' );

is( $field->errors->[0], "'March' is not a valid value", 'is error message' );

