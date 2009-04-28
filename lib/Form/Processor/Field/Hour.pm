package Form::Processor::Field::Hour;

use Moose;
extends 'Form::Processor::Field::Minute';
our $VERSION = '0.03';

sub init_range_start { 0 }
sub init_range_end { 23 }

__PACKAGE__->meta->make_immutable;

=head1 NAME

Form::Processor::Field:: - accept integer from 0 to 23

=head1 SYNOPSIS

See L<Form::Processor>

=head1 DESCRIPTION

Enter an integer from 0 to 23 hours.

=head2 Widget

Fields can be given a widget type that is used as a hint for
the code that renders the field.

This field's widget type is: "text".

=head2 Subclass

Fields may inherit from other fields.  This field
inherits from: "Minute".

=head1 AUTHORS

Bill Moseley

=head1 COPYRIGHT

See L<Form::Processor> for copyright.

This library is free software, you can redistribute it and/or modify it under
the same terms as Perl itself.

=head1 SUPPORT / WARRANTY

L<Form::Processor> is free software and is provided WITHOUT WARRANTY OF ANY KIND.
Users are expected to review software for fitness and usability.

=cut



no Moose;
1;
