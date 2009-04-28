use DateTime;
use Test::More tests => 5;

use_ok('Form::Processor::Model');

my $model = Form::Processor::Model->new();

ok( $model, 'get model object');

my $date = DateTime->now;

my $date_model = Form::Processor::Model->new(item => $date);
ok( $date_model, 'get date model object');


ok( $date_model->object_class eq 'DateTime', 'get object class');

my $alt_model = Form::Processor::Model->new(object_class => 'Some::Metadata');
ok( $alt_model->object_class eq 'Some::Metadata', 'new and get object class');

