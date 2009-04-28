use Test::More tests => 5;

use_ok( 'Form::Processor::Model' );
use_ok( 'Form::Processor' );
use_ok( 'Form::Processor::Field' );

use_ok( 'Form::Processor::Model::CDBI' );

SKIP:
{
   eval 'use DBIx::Class';
   skip( 'DBIx::Class required for Form::Processor::Model::DBIC', 1 ) if $@;
   use_ok( 'Form::Processor::Model::DBIC' );
}

