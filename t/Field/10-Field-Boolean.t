use strict;
use warnings;

use Test::More;
plan tests => 10;

my $class = 'Form::Processor::Field::Boolean';

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
ok( !$field->has_error, 'Test for errors 1' );
is( $field->value, 1, 'Test true == 1' );

$field->input( 0 );
$field->validate_field;
ok( !$field->has_error, 'Test for errors 2' );
is( $field->value, 0, 'Test true == 0' );


$field->input( 'checked' );
$field->validate_field;
ok( !$field->has_error, 'Test for errors 3' );
is( $field->value, 1, 'Test true == 1' );


$field->input( '0' );
$field->validate_field;
ok( !$field->has_error, 'Test for errors 4' );
is( $field->value, 0, 'Test true == 0' );







