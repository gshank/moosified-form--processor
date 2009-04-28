use Test::More tests => 2;


use_ok( 'Form::Processor' );

my $form = My::Form->new;

my $params = {
   price => '1234',
};

$form->validate($params);

my $price = $form->field('price')->value;
is( $price, '1234.00', 'format value' );

package My::Form;
use strict;
use warnings;
use base 'Form::Processor';

sub profile {
    return {
        fields    => {
            price       => {
               type => 'Integer',
               value_format => "%.2f",
            }
        },
    };
}







