package Form::Processor::Field;

use Moose;
use MooseX::AttributeHelpers;
use Form::Processor::I18N;    # only needed if running without a form object.
use Scalar::Util;

our $VERSION = '0.03_1';

=head1 NAME

Form::Processor::Field - Base class for Fields used with Form::Processor

=head1 SYNOPSIS

    # Used from another class
    use base 'Form::Processor::Field::Text';
    my $field = Form::Processor::Field::Text->new( name => $name );


=head1 DESCRIPTION

This is a base class that allows basic functionality for form fields.
Form fields inherit from this class and thus may have additional methods.
See the documentation or source for the individual fields.

Look at the L<validate_field> method for how individual fields are validated.

You are encouraged to create specific fields for your application instead of
simply using the fields included with Form::Processor.


=head1 METHODS/ATTRIBUTES

=over 4

=item name

Field name. This name must be the same as the database column/accessor
name or relation.

=cut

has 'name' => ( isa => 'Str', is => 'rw', required => 1 );

=item type

Field type (e.g. 'Text', 'Select' ... ) from a Form::Processor::Field
subclass, either one provided in the distribution or one that you
create yourself, proceded by a "+":  type => '+MetaText'

=cut

has 'type' => ( isa => 'Str', is => 'rw' );

=item init_value

Initial value populated by init_from_object - used to look for changes.
Not to be confused with the form method init_value().

=cut

has 'init_value' => ( is => 'rw' );

=item value

Internal value -- same as init_value at start.  
Sets or returns the internal value of the field.

The "validate" field method must set this value if the field validates.

=cut

has 'value' => ( is => 'rw',
                 trigger => sub {
                    my ($self, $value) = @_;
                    $self->fif( $value );
                    return $value;
                 }
);

=item input

input value from parameter

=cut

has 'input' => ( is => 'rw', trigger => sub {
                  my ($self, $input) = @_;
                  $self->fif( $input );
                  return $input;
               }
);


=item fif

For filling in forms. Input or value.

=cut

has 'fif' => ( is => 'rw', reader => '_fif' );
sub fif {
   my $self = shift;
   return $self->_fif unless $self->password;
}

=item temp

Temporary storage for fields to save validated data - DEPRECATED -- not really needed.

=cut

has 'temp' => ( is => 'rw' );

=item label

Text label for this field. Not currently used by F::P, but useful in templates.

=cut

has 'label' => (
    isa     => 'Str',
    is      => 'rw',
    lazy    => 1,
    builder => 'init_label'
);
sub init_label { return shift->self->name }

=item title

Place to put title for field, for mouseovers. Not used by F::P.

=cut

has 'title' => ( isa => 'Str', is => 'rw' );

=item style

Field's generic style to use for css formatting in templates.
Not actually used by F::P. 

=cut

has 'style' => ( isa => 'Str', is => 'rw' );

=item sub_form

The field is made up of a sub-form.

A single field can be represented by more than one sub-fields
contained in a form.  This is a reference to that form.

=cut

has 'sub_form' => ( isa => 'Str', is => 'rw' );

=item form

A reference to the containing form.

=cut

has 'form' => ( is => 'rw', weak_ref => 1 );

=item prename

Field name prefixed by the form name and a dot.
A field named "street" in a form named "address" would
have a prename of "address.street". Use with the
form attribute "html_prefix". Allows multiple forms with
the same field names.

=cut

has 'prename' => (
    isa     => 'Str',
    is      => 'rw',
    lazy    => 1,
    builder => 'init_prename'
);

sub init_prename {
    my $self = shift;
    my $prefix = $self->form ? $self->form->name . "." : '';
    return $prefix . $self->name;
}

=item widget, init_widget

"widget" is the attribute, "init_widget" is used to override in
your field classes

This is the generic type of widget that could be used
to generate, say, the HTML markup for the field.
It's similar to the field's type(), but less specific since fields
of different types often use the same widget type.

For example, a Text field would have both the type and widget values
of "Text", where an Integer field would have "Integer" for the type
value and "Text" as the widget value.

Normally you do not need to set this in a field class as it should pick
it up from the base field class used for the specific field.

The basic widget types are:

    Type        : Example fields
    ------------:-----------------------------------
    text        : Text, Integer, Single field dates
    checkbox    : Checkbox
    radio       : Boolean (yes,no), OneToTen
    select      : Select, Multiple
    textarea    : HtmlArea
    compound    : A field made up of other fields

Note that a Select could be a drop down list or a radio group,
and that might be determined in the template code based on how
many select options there are.

Multiple select fields, likewise, might be an option list or
a group of checkboxes.

The default type is 'text'.

=cut

has 'widget' => ( isa => 'Str', is => 'rw', builder => 'init_widget' );
sub init_widget { 'text' }

=item order, init_order

This is the field's order used for sorting errors and field lists.
See the "set_order" method and F::P method "sorted_fields".
The order field is set for the fields when the form is built, but
if the fields are defined with a hashref the order will not be defined.
The "auto" and "fields" profile attributes will take an arrayref which
will preserve the order. If you explicitly set "order" on the fields
in a profile, you should set it on all the fields, otherwise results
will be unpredictable.

=cut

has 'order' => ( isa => 'Int', is => 'rw', builder => 'init_order' );
sub init_order { 1 }

=item required, init_required

Sets or returns the required flag on the field

=cut

has 'required' => ( isa => 'Bool', is => 'rw', builder => 'init_required' );
sub init_required { 0 }

=item required_message, init_required_message

Error message text added to errors if required field is not present

The default is "This field is required".

=cut

has 'required_message' =>
    ( isa => 'Str', is => 'rw', builder => 'init_required_message' );
sub init_required_message { 'This field is required' }

=item unique

Sets or returns the unique flag on the field

=cut

has 'unique' => ( isa => 'Bool', is => 'rw' );

=item unique_message

Error message text added to errors if field is not unique

=cut

has 'unique_message' => ( isa => 'Str', is => 'rw' );

=item range_start, init_range_start
=item range_end, init_range_end

Fields can have a start range and an end range.
The IntRange field, for example will use this range
to create a select list with a range of integers.

If one or both of range_start and range_end are set
and the field does not have an options list, the field's
input value will be tested to be within the range (or
equal to or above/below if only one is set) by numerical
comparison.

For example, in a profile:

    age => {
        type            => 'Integer',
        range_start     => 18,
        range_end       => 120,
    }

Will test that any age entered will be in the range of
of 18 to 120, inclusive.  Open ended can be done by simply:


    age => {
        type            => 'Integer',
        range_start     => 18,
    }

Range checks are done after validation so
must only be used on appropriate fields

=cut

has 'range_start' =>
    ( isa => 'Int|Undef', is => 'rw', builder => 'init_range_start' );
sub init_range_start { return }
has 'range_end' =>
    ( isa => 'Int|Undef', is => 'rw', builder => 'init_range_end' );
sub init_range_end { return }

=item value_format, init_value_format

This is a sprintf format string that is used when moving the field's
input data to the field's value attribute.  By defult this is undefined,
but can be set in fields to alter the way the input_to_value() method
formates input data.

For example in a field that represents money the field could define:

    sub init_value_format { '%.2f' }

And then numberic data will be formatted with two decimal places.

=cut

has 'value_format' =>
    ( isa => 'Str|Undef', is => 'rw', builder => 'init_value_format' );
sub init_value_format { return }

=item id, init_id

Often the fields need a unique id for js. This is a
handy way to get this.

Returns an id for the field, which is by default:

    $field->form->name . $field->id

A field may override with "init_id".

=cut

has 'id' => ( isa => 'Str', is => 'rw', lazy => 1, builder => 'init_id' );

sub init_id {
    my $field = shift;
    my $form_name = $field->form ? $field->form->name : 'fld-';
    return $form_name . $field->name;
}

=item password, init_password

This is a boolean flag and if set the $form->params method will remove that
field when calling $form->fif.

This is different than the C<writeonly> method above in that the value is
removed from the hash every time its fetched.

=cut

has 'password' => ( isa => 'Bool', is => 'rw', builder => 'init_password' );
sub init_password { 0 }

=item writeonly, init_writeonly

Fields flagged as writeonly are not fetched from the model when $form->params
is called.  This means the field's formatted value will not be included
in the hash returned by $form->fif when first populating a form with
existing values.

An example might be a situation where a trigger is used to create a copy of a
row before an update.  In this case you might have a required "update_reason"
column that should only be written to the database on updates.

Unlike the C<password> flag, this only prevents populating a field from the
field's initial value, but not from the parameter hash passed to the form.
Redrawn forms (after validation failures) will display the value submitted
in the form.

=cut

# don't call format_value on this field
has 'writeonly' => ( isa => 'Bool', is => 'rw', builder => 'init_writeonly' );
sub init_writeonly { 0 }

=item clear, init_clear

This is a flag that says you want to clear the database column for this
field.  Validation is also not run on this field.

=cut

has 'clear' => ( isa => 'Bool', is => 'rw', builder => 'init_clear' );
sub init_clear { 0 }

=item disabled, init_disabled
=item readonly, init_readonly

These allow you to give hints to how the html element is generated.  
"Disabled" and "readonly" have specific
meanings in the HTML specification, but may not be consistently implemented.

Disabled controls should not be successful and thus not submitted in forms, where
readonly fields can be.  Instead of depending on these field attributes, a
Form::Processor::Model class should instead use the L<noupdate> flag
as an indicator if the field should be ignored or not.

Readonly fields are like hidden fields that the UI should not be
able to modify, but are still submitted.

=cut

has 'disabled' => ( isa => 'Bool', is => 'rw', builder => 'init_disabled' );
sub init_disabled { 0 }
has 'readonly' => ( isa => 'Bool', is => 'rw', builder => 'init_readonly' );
sub init_readonly { 0 }

=item noupdate, init_noupdate

This boolean flag indicates a field that should not be updated.  Fields
flagged as noupdate are skipped when processing by the model.

This is useful when a form contains extra fields that are not directly
written to the data store.

=cut

has 'noupdate' => ( isa => 'Bool', is => 'rw', builder => 'init_noupdate' );
sub init_noupdate { 0 }

=item errors

returns the error (or list of errors if more than one was set)

=cut

has 'errors' => (
    metaclass  => 'Collection::Array',
    isa        => 'ArrayRef[Str]',
    is         => 'rw',
    auto_deref => 1,
    provides   => { push => 'push_error', }
);

# tell Moose to make this class immutable
__PACKAGE__->meta->make_immutable;

=item new [parameters]

Create a new instance of a field.  Any initial values may be passed in
as a list of parameters.

=cut

sub BUILDARGS {
    my ( $self, @args ) = @_;
    return {@args};
}

=item full_name

This returns the name of the field, but if the field
is a child field will prepend the field with the parent's field
name.  For example, if a field is "month" and the parent's field name
is "birthday" then this will return "birthday.month".

=cut

sub full_name {
    my $field = shift;

    my $name   = $field->name;
    my $form   = $field->form || return $name;
    my $parent = $form->parent_field || return $name;
    return $parent->name . '.' . $name;
}

=item set_order

This sets the field's order to the form's field_counter
and increments the counter.

The purpose of this is when displaying fields, say in a template,
this can be called with displaying the field to set its order.
Then a summary of error messages can be displayed in the order
the fields are on the form.

=cut

sub set_order {
    my $field = shift;
    my $form  = $field->form;
    my $order = $form->field_counter || 1;
    $field->order($order);
    $form->field_counter( $order + 1 );
}

=item add_error

Add an error to the list of errors.  If $field->form
is defined then process error message as Maketext input.
See $form->language_handle for details.

Returns undef.  This allows:

    return $field->add_error( 'bad data' ) if $bad;

=cut

sub add_error {
    my $self = shift;

    my $form = $self->form;

    my $lh;

    # By default errors get attached to the field where they happen.
    my $error_field = $self;

    # Running without a form object?
    if ($form) {
        $lh = $form->language_handle;

        # If we are a sub-form then redirect errors to the parent field
        $error_field = $form->parent_field if $form->parent_field;
    }
    else {
        $lh = $ENV{LANGUAGE_HANDLE}
            || Form::Processor::I18N->get_handle
            || die "Failed call to Locale::Maketext->get_handle";
    }

    $self->add_error_str( $lh->maketext(@_) );

    return;

}

=item validate_field

This method does standard validation, which currently tests:

    required        -- if field is required and value exists

Then if a value exists:

    test_multiple   -- looks for multiple params passed in when not allowed
    test_options    -- tests if the params passed in are valid options

If all of those pass then the field's validate method is called

    $field->validate;

If C<< $field->validate >> returns true then the input value
is copied from the input attribute to the field's value attribute
by calling:

    $field->input_to_value;

The default method simply copies the value.  This method is only called
if the field does not have any errors.

The field's error list and internal value are reset upon entry.

Typically, a field may wish to override the following methods:

=cut

sub validate_field {
    my $field = shift;

    $field->reset_errors;
    $field->value(undef);

    # See if anything was submitted
    unless ( $field->any_input ) {
        $field->add_error( $field->required_message )
            if $field->required;

        return !$field->required;
    }

    return unless $field->test_multiple;
    return unless $field->test_options;
    return unless $field->validate;
    return unless $field->test_ranges;

    # Now move data from input -> value
    $field->input_to_value;

    return $field->validate_value unless $field->has_error;

    return;
}

=item validate

This method validates the input data for the field and returns true if
the data validates, false if otherwise.  It's expected that an error
message is added to the field if the field's input value does not validate.

The default method is to return true.

The method is passed the field's input value.

When overriding this method it is best to first call the parent class
validate method.  This way general to more specific error validation can occur.
For example in a field class:

    sub validate {
        my $field = shift;
        
        return unless $field->SUPER::validate;
        
        my $input = $field->input;
        #validate $input
        
        return $valid_input ? 1 : 0;
    }

If the validation method produces a final value in the process of validation
(e.g. creates a DateTime object from a string) then that value can either
be placed in C<< $field->value >> at that time and will not be copied by
C<< $field->input_to_value >>, or can place the value in a temporary location
and then the field can also override the C<input_to_value> method.

=cut

sub validate { 1 }

=item validate_value

This field method is called after the raw input data field has been validated 
(with the validate method) and placed in the field's value (after 
calling input_to_value() method).

This method can be overridden in field classes to validate a field after it's been
converted into its internal form (e.g. a DateTime object).

The default method is to simply return true;

=cut

sub validate_value { 1 }

=item input_to_value

This method is called if C<< $field->validate >> returns true.
The default method simply copies the input attribute value to the
value attribute if C<< $field->value >> is undefined.

    $field->value( $field->input )
        unless defined $field->value;

A field's validation method can populate a field's value during
validation, or can override this method to populate the value after
validation has run.  Overriding this method is recommended.

A common use in a field would be to convert the input into
an internal format.  For example, converting a time or date in string
form to a L<DateTime> object.

=cut

sub input_to_value {
    my $field = shift;

    return if defined $field->value;    # already set by validate method.

    my $format = $field->value_format;

    if ($format) {
        $field->value( sprintf( $format, $field->input ) );
    }

    else {
        $field->value( $field->input );
    }
}

=item test_ranges

If range_start and/or range_end is set AND the field
does not have options will test that the value is within
range.  This is called after all other validation.

=cut

sub test_ranges {
    my $field = shift;
    return 1 if $field->can('options') || $field->has_error;

    my $input = $field->input;

    return 1 unless defined $input;

    my $low  = $field->range_start;
    my $high = $field->range_end;

    if ( defined $low && defined $high ) {
        return $input >= $low && $input <= $high
            ? 1
            : $field->add_error( 'value must be between [_1] and [_2]',
            $low, $high );
    }

    if ( defined $low ) {
        return $input >= $low
            ? 1
            : $field->add_error( 'value must be greater than or equal to [_1]',
            $low );
    }

    if ( defined $high ) {
        return $input <= $high
            ? 1
            : $field->add_error( 'value must be less than or equal to [_1]',
            $high );
    }

    return 1;
}

=item trim_value

Trims leading and trailing white space for single parameters.
If the parameter is an array ref then each value is trimmed.

Pass in the value to trim and returns value back

=cut

sub trim_value {
    my ( $self, $value ) = @_;

    return unless defined $value;

    my @values = ref $value eq 'ARRAY' ? @$value : ($value);

    for (@values) {
        next if ref $_;
        s/^\s+//;
        s/\s+$//;
    }

    return @values > 1 ? \@values : $values[0];
}

=item test_multiple

Returns false if the field is a multiple field
and the input for the field is a list.


=cut

sub test_multiple {
    my ($self) = @_;

    my $value = $self->input;
    if ( ref $value eq 'ARRAY'
        && !( $self->can('multiple') && $self->multiple ) )
    {
        $self->add_error('This field does not take multiple values');
        return;
    }
    return 1;
}

=item any_input

Returns true if $self->input contains any non-blank input.


=cut

sub any_input {
    my ($self) = @_;

    my $found;

    my $value = $self->input;

    # check for one value as defined
    return grep { /\S/ } @$value
        if ref $value eq 'ARRAY';

    return defined $value && $value =~ /\S/;
}

=item test_options

If the field has an "options" method then the input value (or values
if an array ref) is tested to make sure they all are valid options.

Returns true or false

=cut

sub test_options {
    my ($self) = @_;

    return 1 unless $self->can('options');

    # create a lookup hash
    my %options = map { $_->{value} => 1 } $self->options;

    my $input = $self->input;

    return 1 unless defined $input;    # nothing to check

    for my $value ( ref $input eq 'ARRAY' ? @$input : ($input) ) {
        unless ( $options{$value} ) {
            $self->add_error("'$value' is not a valid value");
            return;
        }
    }

    return 1;
}

=item format_value

This method takes $field->value and formats it into a hash
that is merged in to the final params hash.  It's purpose is to take the
internal value and create the key/value pairs.

By default it returns:

    ( $field->name, $field->value )

A Date field subclass might expand the value into:

    my $name = $field->name;
    return (
        $name . 'd'  => $day,
        $name . 'm' => $month,
        $name . 'y' => $year,
    );

It's up to you to not use duplicate hash values.

You might want to override test_required() if you don't use a matching field name
(e.g. $name . 'd' instead of just $name).

=cut

sub format_value {
    my $self  = shift;
    my $value = $self->value;
    return defined $value ? ( $self->name, $value ) : ();
}

=item value_changed

Returns true if the value in the item has changed from what is currently in the
field's value.

This only does a string compare (arrays are sorted and joined).

=cut

sub value_changed {
    my ($self) = @_;

    my @cmp;

    for ( 'init_value', 'value' ) {
        my $val = $self->$_;
        $val = '' unless defined $val;

        push @cmp, join '|', sort
            map { ref($_) && $_->isa('DateTime') ? $_->iso8601 : "$_" }
            ref($val) eq 'ARRAY' ? @$val : $val;

    }

    return $cmp[0] ne $cmp[1];
}

=item required_text

Returns "required" or "optional" based on the field's setting.

=cut

sub required_text { shift->required ? 'required' : 'optional' }

=item dump_field

A little debugging.

=cut

sub dump {
    my $f = shift;
    require Data::Dumper;
    warn "\n---------- [ ", $f->name, " ] ---------------\n";
    warn "Field Type: ", ref($f), "\n";
    warn "Required: ", ( $f->required || '0' ), "\n";
    warn "Password: ", ( $f->password || '0' ), "\n";
    my $v = $f->value;
    warn "Value: ", Data::Dumper::Dumper $v;
    my $iv = $f->init_value;
    warn "InitValue: ", Data::Dumper::Dumper $iv;
    my $i = $f->input;
    warn "Input: ", Data::Dumper::Dumper $i;

    if ( $f->can('options') ) {
        my $o = $f->options;
        warn "Options: " . Data::Dumper::Dumper $o;
    }
}

=item has_error

Returns the count of errors on the field.

=cut

sub has_error {
    my $self   = shift;
    my $errors = $self->errors;
    return unless $errors;
    return scalar @$errors;
}

=item reset_errors

Resets the list of errors.  The validate method
clears the errors by default.

=cut

sub reset_errors {
    my $self = shift;
    delete $self->{errors} if $self->errors;
}

sub add_error_str {
    my ( $self, $string ) = @_;
    $self->errors( [] ) unless $self->errors;
    $self->push_error($string);
}

=back

=head1 AUTHORS

Bill Moseley - with *much* help from John Siracusa.  Most of this
is based on Rose-HTML-Form.  It's basically a very trimmed down version without
all the HTML generation and the ability to do compound fields.

Updated and converted to Moose by Gerda Shank

=cut

no Moose;
1;
