package Form::Processor::Field::MonthName;

use Moose;
extends 'Form::Processor::Field::Select';
our $VERSION = '0.03';


__PACKAGE__->meta->make_immutable;

sub init_options {
    my $i = 1;
    my @months = qw/
        January
        February
        March
        April
        May
        June
        July
        August
        September
        October
        November
        December
    /;
    return [
        map {
            {   value => $i++, label => $_ }
        } @months
    ];
}


=head1 NAME

Form::Processor::Field::MonthName - Select list for month names

=head1 SYNOPSIS

See L<Form::Processor>

=head1 DESCRIPTION

Generates a list of English month names.

=head2 Widget

Fields can be given a widget type that is used as a hint for
the code that renders the field.

This field's widget type is: "select".

=head2 Subclass

Fields may inherit from other fields.  This field
inherits from: "Select".

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
