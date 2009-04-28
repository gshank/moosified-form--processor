use strict;
use warnings;

use Test::More;
my $tests = 7;
plan tests => $tests;

my $class = 'Form::Processor::Field::MonthDay';

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

$field->input( 31 );
$field->validate_field;
ok( !$field->has_error, '31 in range' );

$field->input( 12 );
$field->validate_field;
ok( !$field->has_error, '12 in range' );

$field->input( 0  );
$field->validate_field;
ok( $field->has_error, '0 out of range' );


$field->input( 32 );
$field->validate_field;
ok( $field->has_error, '32 out of range' );

