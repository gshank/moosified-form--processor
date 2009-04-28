use Test::More tests => 7;


use_ok( 'Form::Processor' );

my $form1 = My::Form::One->new;
ok( $form1, 'get first form' );

my $form2 = My::Form::Two->new;
ok( $form2, 'get second form' );

my $params = {
   'One.field_one' => 'First field in first form',
   'One.field_two' => 'Second field in first form',
   'One.field_three' => 'Third field in first form',
   $form2->field('field_one')->prename => 
             'First field in second form',
   $form2->field('field_two')->prename => 
              'Second field in second form',
   $form2->field('field_three')->prename => 
              'Third field in second form',
};

$form1->validate( $params );
ok( $form1->validated, 'validated first form' );
is( $form1->value('field_one'), 'First field in first form',
   'value of field in first form is correct' );

$form2->validate( $params );
ok( $form2->validated, 'validated second form' );
is( $form2->value('field_three'), 'Third field in second form',
   'value of field in second form is correct' );

package My::Form::One;
use strict;
use warnings;
use base 'Form::Processor';

# this form specifies the form name
sub init_name { 'One' };
sub init_html_prefix { 1 };

sub profile {
    return {
        fields    => {
            field_one => 'Text',
            field_two => 'Text',
            field_three => 'Text',
        },
    };
}

package My::Form::Two;
use strict;
use warnings;
use base 'Form::Processor';

# this form uses the default random form name generation
sub init_html_prefix{ 1 };

sub profile {
    return {
        fields    => {
            field_one => 'Text',
            field_two => 'Text',
            field_three => 'Text',
        },
    };
}

