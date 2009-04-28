use strict;
use warnings;

use Test::More;
my $tests = 5;
plan tests => $tests;

my $class = 'Form::Processor::Field::Money';

my $name = $1 if $class =~ /::([^:]+)$/;

use_ok( $class );
my $field = $class->new(
    name    => 'test_field',
    type    => $name,
    form    => undef,
);

ok( defined $field,  'new() called' );

$field->input( $field->trim_value('   $123.45  ') );
$field->validate_field;
ok( !$field->has_error, 'Test for errors "   $123.00  "' );
is( $field->value, 123.45, 'Test value == 123.45' );


$field->input( $field->trim_value('   $12x3.45  ') );
$field->validate_field;
ok( $field->has_error, 'Test for errors "   $12x3.45  "' );




