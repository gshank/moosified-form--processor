use Test::More tests => 4;
use lib 't/lib';


my $loaded_form = My::Form::One->load_form;

ok($loaded_form, 'get loaded form with field_name_space' );


is( $loaded_form->field('field_two')->name, 'field_two', 'get field name' );

my $loaded_form2 = My::Form::Two->load_form;
ok( $loaded_form2, 'get loaded form w/o field_name_space' ); 
is( $loaded_form2->field('field_one')->name, 'field_one', 'get field name' );

package My::Form::One;
use strict;
use warnings;
use base 'Form::Processor';

sub init_field_name_space { 'BookDB::Form::Field' }

sub profile {
    return {
        fields    => {
            field_one => '+AltText',
            field_two => 'Text',
        },
    };
}

package My::Form::Two;
use strict;
use warnings;
use base 'Form::Processor';

sub profile {
    return {
        fields    => {
            field_one => '+BookDB::Form::Field::AltText',
            field_two => 'Text',
        },
    };
}
