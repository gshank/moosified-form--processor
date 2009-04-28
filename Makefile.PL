use inc::Module::Install;


name 'Form-Processor';
all_from 'lib/Form/Processor.pm';

requires 'Moose'              => '0.59';
requires 'MooseX::AttributeHelpers' => '0.14';
requires 'Scalar::Util'       => '1.18';
requires 'UNIVERSAL::require' => '0';
requires 'Locale::Maketext'   => '1.09';
requires 'Module::Find'       => '0.05';

build_requires 'Test::More' => 0;


my %recommended = (

    'DateTime'                    => '0.34',
    'Date::Manip'                 => '5.44',
    'DateTime::Format::DateManip' => '0.04',
    'Email::Valid'                => '0.179',
    'Template'                    => '2.19',
    'HTML::Tidy'                  => '1.06',
    'File::Temp'                  => '0.16',
    'Net::CIDR'                   => '0.11',
    'Digest::MD5'                 => '2.36',
);

recommends $_ => $recommended{$_} for keys %recommended;

tests ( join ' ', ( glob('t/*.t'), glob('t/Field/*.t') ) );

auto_install;
WriteAll;

