use Test::More tests => 6;
use lib 't/lib';


my $form = My::Form->new; 
ok( $form, 'get form' );

my $params = {
   field_one => 'one two three four',
   field_two => 'one three four',
   field_three => 'one three four',
};

$form->validate( $params );

ok( !$form->validated, 'form validated' );

ok( !$form->field('field_one')->has_error, 'field one has no error');

is( $form->field('field_two')->has_error, 1, 'field two has one error');
is( $form->field('field_two')->errors->[0], 
   'Fails AltText validation', 'get error message' );

ok( !$form->field('field_three')->has_error, 'field three has no error');

package My::Form;
use strict;
use warnings;
use base 'Form::Processor';

# this form specifies the form name
sub init_field_name_space { 'BookDB::Form::Field' }

sub profile {
    return {
        fields    => {
            field_one => {
               type => '+AltText',
               another_attribute => 'one',
            },
            field_two => {
               type => '+AltText',
               another_attribute => 'two',
            },
            field_three => {
               type => '+AltText',
               another_attribute => 'three',
            },
        },
    };
}
