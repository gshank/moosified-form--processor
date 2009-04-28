use Test::More tests => 3;

use_ok( 'Form::Processor::Field::Select' );

my $select_field = Form::Processor::Field::Select->new(name => 'MySelect', type => 'Select' );
ok( $select_field, 'new select field' );

$select_field->value('Testing');
$select_field->options([{value => 'Testing', label => 'This is the label for Testing'}, {value => 'Again', label => 'This is the label for Again'}] );
ok( $select_field->as_label eq 'This is the label for Testing', 'field as label' ); 

