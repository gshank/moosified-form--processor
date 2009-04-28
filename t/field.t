use Test::More tests => 9;

use_ok('Form::Processor::Field');

my $field = Form::Processor::Field->new( name => 'somefield' );

ok( $field, 'create field');

$field = Form::Processor::Field->new(
     name => 'AnotherField',
     type => 'Text',
     label => 'FIELD:',
     widget => 'select1',
     required => 1,
     required_message => 'This field is REQUIRED'
); 

ok( $field, 'more complicated field' );

ok( $field->full_name eq 'AnotherField', 'full name' );

ok( $field->id eq 'fld-AnotherField', 'field id' );

ok( $field->widget eq 'select1', 'field widget' );

$field->order(3);
ok( $field->order == 3, 'field order' );

$field->add_error('This is an error string');
ok( $field->errors, 'added error' );

$field->input('128');
$field->input_to_value;
ok( $field->value == 128, 'move input to value');

