package Form::Processor::Model::DBIC;

use Moose;
extends 'Form::Processor';
use Carp;

our $VERSION = '0.07_1';

=head1 NAME

Form::Processor::Model::DBIC - Model class for Form Processor using DBIx::Class

=head1 SYNOPSIS

Subclass your form from Form::Processor::Model::DBIC:

    package MyApp:Form::User;
    use strict;
    use base 'Form::Processor::Model::DBIC';

If you are using L<Catalyst::Controller::Form::Processor> (and not 
L<Catalyst::Plugin::Form::Processor>) specify the
model name either as a config option:

    __PACKAGE__->config( model_name => 'DB' );

or as an additional option on the "update_from_form" call:

   $self->update_from_form( $item_id, 'User', 'DB'); 

where 'DB' is the name of the Catalyst model.

In the "object_class" subroutine of your form, specify the source name
of your DBIx::Class resultsource, unless you are using the Catalyst plugin.
If you are using the Catalyst plugin, specify the modelname and source name
that would be used in the Catalyst model ( $c->model('DB::User') );

    # Associate this form with a DBIx::Class result class
    sub init_object_class { 'User' } # Where 'User' is the DBIC source_name 

or, for the plugin:

   sub init_object_class { 'DB::User' } # Where 'DB' is the model and 'User' the source name

The field names in the profile of your form must match column, relationship,
or accessor names in your DBIx::Class result source.

=head1 DESCRIPTION

This DBIC model for Form::Processor will save form fields automatically to 
the database, will retrieve selection lists from the database 
(with type => 'Select' and a fieldname containing a single relationship, 
or type => 'Multiple' and a many_to_many or has_many relationship), 
and will save the selected values (one value for 'Select', multiple 
values in a mapping table for a 'Multiple' field). 

This model supports using DBIx::Class result_source accessors just as
if they were standard columns. This allows you to provide alternative
getters and setters for use in your form.

Since the forms that use this model are subclasses of it, you can subclass
any of the subroutines to provide custom functionality.

More information is available from:

L<Form::Processor>

L<Form::Processor::Manual>

L<Form::Processor::Field>

L<Catalyst::Controller::Form::Processor>

L<Catalyst::Plugin::Form::Processor>

=head1 METHODS

=head2 schema

Stores the schema that is either passed in, created from
the model name in the controller, or created from the
Catalyst context and the object_class in the plugin.

=cut

has 'schema' => (
   isa     => 'DBIx::Class::Schema',
   is      => 'rw',
   lazy    => 1,
   builder => 'init_schema'
);
has 'source_name' => (
   isa     => 'Str',
   is      => 'rw',
   lazy    => 1,
   builder => 'init_source_name'
);

# tell Moose to make this class immutable
Form::Processor::Model::DBIC->meta->make_immutable;

sub BUILDARGS
{
   my ( $self, @args ) = @_;
   return {@args};
}

=head2 update_from_form

    my $validated = $form->update_from_form( $parameter_hash );

This is not the same as the routine called with $c->update_from_form--the
Catalyst plugin routine that calls this one--or $self->update_form_form--the
Catalyst controller routine. This routine updates or
creates the object from values in the form.

All fields that refer to columns and have been changed will be updated. Field names
that are a single relationship will be updated. Any field names that are related 
to the class by "has_many" are assumed to have a mapping table and will be 
updated.  Validation is run unless validation has already been run.  
($form->clear might need to be called if the $form object stays in memory
between requests.)

The actual update is done in the C<update_model> method.  Your form class can
override that method if you wish to do additional
database inserts or updates.  This is useful when a single form updates 
multiple tables, or there are secondary tables to update.

=cut

sub update_from_form
{
   my ( $self, $params ) = @_;
   return unless $self->validate($params);
   $self->update_model;
   return 1;
}

=head2 model_validate

The place to put validation that requires database-specific lookups.
Subclass this method in your form. Validation of unique fields is 
called from this method.

=cut

sub model_validate
{
   my ($self) = @_;
   return unless $self->validate_unique;
   return 1;
}

=head2 update_model

Updates the database. If you want to do some extra
database processing (such as updating a related table) this is the
method to subclass in your form.

This routine allows the use of non-database (non-column, non-relationship) 
accessors in your result source class. It identifies form fields as column,
relationship, select, multiple, or other. Column and other fields are 
processed and update is called on the row. Then relationships are processed.

If the row doesn't exist (no primary key or row object was passed in), then
a row is created using "create" and the fields identified as columns passed
in a hashref, followed by "other" fields and relationships.

=cut

sub update_model
{
   my ($self) = @_;
   my $item   = $self->item;
   my $source = $self->source;

   # get a hash of all fields, skipping fields marked 'noupdate'
   my $prefix = $self->name_prefix;
   my %columns;
   my %multiple_has_many;
   my %multiple_m2m;
   my %select;
   my %other_rel;
   my %other;
   my $field;
   my $value;
   # Save different flavors of fields into hashes for processing
   foreach $field ( $self->fields )
   {
      next if $field->noupdate;
      my $name = $field->name;
      $name =~ s/^$prefix\.//g if $prefix;
      # If the field is flagged "clear" then set to NULL.
      $value = $field->clear ? undef : $field->value;
      if ( $source->has_relationship($name) )
      {
         if ( $field->can('multiple') && $field->multiple == 1 ) 
         {
            $multiple_has_many{$name} = $value;
         }
         # If the table has a column name the same name as the
         # the "select" relationship, the 'has_columns' will catch it.
         # This is for Selects with different column name and rel name
         elsif ($field->can('options'))
         {
            $select{$name} = $value;
         } 
         else
         {
            # for now just remove other relationships because
            # they aren't handled here, and could be handled in a subclass
            $other_rel{$name} = $value;
         }
      }
      elsif ( $source->has_column($name) )
      {
         $columns{$name} = $value;
      }
      elsif ( $field->can('multiple' ) && $field->multiple == 1 )
      {
         # didn't have a relationship and is multiple, so must be m2m
         $multiple_m2m{$name} = $value;
      }
      else    # neither a column nor a rel
      {
         $other{$name} = $value;
      }
   }

   my $changed = 0;
   # Handle database columns
   if ($item)
   {
      for my $field_name ( keys %columns )
      {
         $value = $columns{$field_name};
         my $cur = $item->$field_name;
         next unless $value || $cur;
         next if ( ( $value && $cur ) && ( $value eq $cur ) );
         $item->$field_name($value);
         $changed++;
      }
      $self->updated_or_created('updated');
   }
   else    # create new item
   {
      $item = $self->resultset->create( \%columns );
      $self->item($item);
      $self->updated_or_created('created');
   }

   # Set single select lists with rel different from column
   for my $field_name ( keys %select )
   {
      my $rel_info = $item->relationship_info($field_name);
      my ($cond)     = values %{ $rel_info->{cond} };
      my ($self_col) = $cond =~ m/^self\.(\w+)$/;
      $item->$self_col( $select{$field_name} );
      $changed++;
   }

   # set non-column, non-rel attributes
   for my $field_name ( keys %other )
   {
      next unless $item->can($field_name);
      $item->$field_name( $other{$field_name} );
      $changed++;
   }
   # update db
   $item->update if $changed > 0;

   # process Multiple field 'has_many' relationships
   for my $field_name ( keys %multiple_has_many )
   {
      # This is a has_many/many_to_many relationship
      my ( $self_rel, $self_col, $foreign_rel, $foreign_col, $m2m_rel ) =
         $self->many_to_many($field_name);
      $value = $multiple_has_many{$field_name};
      my %keep;
      %keep = map { $_ => 1 } ref $value ? @$value : ($value)
         if defined $value;
      if ( $self->updated_or_created eq 'updated' )
      {
         for ( $item->$field_name->all )
         {
            # delete old selections
            $_->delete unless delete $keep{ $_->$foreign_col };
          }
      }

      # Add new related
      $item->create_related( $field_name, { $foreign_col => $_ } ) for keys %keep;
   } 
   # process Multiple field 'many_to_many' relationships
   for my $field_name ( keys %multiple_m2m )
   {
      $value = $multiple_m2m{$field_name};
      my %keep;
      %keep = map { $_ => 1 } ref $value ? @$value : ($value)
         if defined $value;
      my $meth;
      my $row;
      if ( $self->updated_or_created eq 'updated' )
      {
         foreach $row ( $item->$field_name->all )
         {
            $meth = 'remove_from_' . $field_name;
            $item->$meth( $row ) 
               unless delete $keep{ $row->id };
         }
      }
      my $source_name = $item->$field_name->result_source->source_name;
      foreach my $id ( keys %keep )
      {
         $row = $self->schema->resultset($source_name)->find($id);
         $meth = 'add_to_' . $field_name;
         $item->$meth( $row );
      }
   }

   # Save item in form object
   $self->item($item);
   $self->reset_params;    # force reload of parameters from values
   return $item;
}


=head2 guess_field_type

This subroutine is only called for "auto" fields, defined like:
    return {
       auto_required => ['name', 'age', 'sex', 'birthdate'],
       auto_optional => ['hobbies', 'address', 'city', 'state'],
    };

Pass in a column and it will guess the field type and return it.

Currently returns:
    DateTimeDMYHM   - for a has_a relationship that isa DateTime
    Select          - for a has_a relationship
    Multiple        - for a has_many

otherwise:
    DateTimeDMYHM   - if the field ends in _time
    Text            - otherwise

Subclass this method to do your own field type assignment based
on column types. This routine returns either an array or type string. 

=cut

sub guess_field_type
{
   my ( $self, $column ) = @_;
   my $source = $self->source;
   my @return;

   #  TODO: Should be able to use $source->column_info

   # Is it a direct has_a relationship?
   if (
      $source->has_relationship($column)
      && (  $source->relationship_info($column)->{attrs}->{accessor} eq 'single'
         || $source->relationship_info($column)->{attrs}->{accessor} eq 'filter' )
      )
   {
      my $f_class = $source->related_class($column);
      @return =
         $f_class->isa('DateTime')
         ? ('DateTimeDMYHM')
         : ('Select');
   }
   # Else is it has_many?
   elsif ( $source->has_relationship($column)
      && $source->relationship_info($column)->{attrs}->{accessor} eq 'multi' )
   {
      @return = ('Multiple');
   }
   elsif ( $column =~ /_time$/ )    # ends in time, must be time value
   {
      @return = ('DateTimeDMYHM');
   }
   else                             # default: Text
   {
      @return = ('Text');
   }

   return wantarray ? @return : $return[0];
}

=head2 lookup_options

This method is used with "Single" and "Multiple" field select lists 
("single", "filter", and "multi" relationships).
It returns an array reference of key/value pairs for the column passed in.
The column name defined in $field->label_column will be used as the label.
The default label_column is "name".  The labels are sorted by Perl's cmp sort.

If there is an "active" column then only active values are included, except 
if the form (item) has currently selected the inactive item.  This allows
existing records that reference inactive items to still have those as valid select
options.  The inactive labels are formatted with brackets to indicate in the select
list that they are inactive.

The active column name is determined by calling:
    $active_col = $form->can( 'active_column' )
        ? $form->active_column
        : $field->active_column;

This allows setting the name of the active column globally if
your tables are consistantly named (all lookup tables have the same
column name to indicate they are active), or on a per-field basis.

The column to use for sorting the list is specified with "sort_order". 
The currently selected values in a Multiple list are grouped at the top
(by the Multiple field class).

=cut

sub lookup_options
{
   my ( $self, $field ) = @_;

   my $field_name = $field->name;
   my $prefix     = $self->name_prefix;
   $field_name =~ s/^$prefix\.//g if $prefix;

   # if this field doesn't refer to a foreign key, return
   my $f_class;
   my $source;
   if ($self->source->has_relationship($field_name) )
   {
      $f_class = $self->source->related_class($field_name);
      $source = $self->schema->source($f_class);

      my $rel_info = $self->source->relationship_info($field_name);
      if ( $field->type eq 'Multiple'
         || ( $field->type eq 'Auto' && $rel_info->{attrs}{accessor} eq 'multi' ) )
      {
         # This is a 'has_many' relationship with a mapping table
         my ( $self_rel, $self_col, $foreign_rel, $foreign_col ) =
            $self->many_to_many($field_name);
         $source  = $source->related_source($foreign_rel);
      }
   }
   elsif ($self->resultset->new_result({})->can("add_to_$field_name") )
   {
      # Multiple field with many_to_many relationship
      $source = $self->resultset->new_result({})->$field_name->result_source;
   }
   return unless $source; 

   my $label_column = $field->label_column;
   return unless $source->has_column($label_column);

   my $active_col =
        $self->can('active_column')
      ? $self->active_column
      : $field->active_column;

   $active_col = '' unless $source->has_column($active_col);
   my $sort_col = $field->sort_order;
   $sort_col = defined $sort_col && $source->has_column($sort_col) ? $sort_col : $label_column;

   my ($primary_key) = $source->primary_columns;

   # If there's an active column, only select active OR items already selected
   my $criteria = {};
   if ($active_col)
   {
      my @or = ( $active_col => 1 );

      # But also include any existing non-active
      push @or, ( "$primary_key" => $field->init_value )
         if $self->item && defined $field->init_value;
      $criteria->{'-or'} = \@or;
   }

   # get an array of row objects
   my @rows =
      $self->schema->resultset( $source->source_name )
      ->search( $criteria, { order_by => $sort_col } )->all;

   return [
      map {
         my $label = $_->$label_column;
         $_->id, $active_col && !$_->$active_col ? "[ $label ]" : "$label"
         } @rows
   ];
}

=head2 init_value

This method returns a field's value (for $field->value) with
either a scalar or an array ref from the object stored in $form->item.

This method is not called if a method "init_value_$field_name" is found 
in the form class - that method is called instead.
This allows overriding specific fields in your form class.

=cut

sub init_value
{
   my ( $self, $field, $item ) = @_;

   my $name = $field->name;
   my $prefix = $self->name_prefix;
   $name =~ s/$prefix\.//g if $prefix;
   $item ||= $self->item;
   return unless $item;
   return $item->{$name} if ref($item) eq 'HASH';
   return unless $item->isa('DBIx::Class') && $item->can($name);
   return unless defined $item->$name;

   my $source = $self->source;
   if ( $source->has_relationship($name) )
   {
      if ( $field->can('multiple') && $field->multiple == 1 ) 
      {
         # has_many Multiple field
         my ( undef, undef, undef, $foreign_col ) = $self->many_to_many($name);
         my @rows = $item->search_related($name)->all;
         my @values = map { $_->$foreign_col } @rows;
         return @values;
      }
      elsif ($field->can('options'))
      {
         return $item->$name->id; 
      } 
      else # some other relationship (unsupported)
      {
         my $rel_info = $source->relationship_info($name);
         if ( $rel_info->{attrs}->{accessor} eq 'single' ||
              $rel_info->{attrs}->{accessor} eq 'filter' )
         {
            return $item->$name->get_inflated_columns; 
         }
         else # multi relationship (unsupported)
         {
            my $rs = $item->$name;
            $rs->result_class('DBIx::Class::ResultClass::HashRefInflator'); 
            return $rs->all;
         }
      }
   }
   elsif ( $source->has_column($name) )
   {
      return $item->$name; 
   }
   elsif ( $field->can('multiple' ) && $field->multiple == 1 )
   {
      my @rows = $item->$name->all;
      my @values = map { $_->id } @rows;
      return @values;
   }
   else    # neither a column nor a rel
   {
      return $item->$name;
   }
}

=head2 validate_unique

For fields that are marked "unique", checks the database for uniqueness.

   arraryref:
        unique => ['user_id', 'username']

   or hashref:
        unique => {
            username => 'That username is already taken',
        }

=cut

sub validate_unique
{
   my ($self) = @_;

   my $unique      = $self->profile->{unique};
   my $item        = $self->item;
   my $rs          = $self->resultset;
   my $found_error = 0;
   my @unique_fields;
   my $error_message;
   if ( ref($unique) eq 'ARRAY' )
   {
      @unique_fields = @$unique;
      $error_message = 'Value must be unique in the database';
   }
   if ( ref($unique) eq 'HASH' )
   {
      @unique_fields = keys %$unique;
   }
   my @unique_from_fields = map { $_->name } grep { $_->unique } $self->fields; 
   my @all_unique = (@unique_fields, @unique_from_fields);

   return 1 unless @all_unique;

   for my $field ( map { $self->field($_) } @all_unique )
   {

      next if $field->errors;
      my $value = $field->value;
      next unless defined $value;
      my $name   = $field->name;
      my $prefix = $self->name_prefix;
      $name =~ s/^$prefix\.//g if $prefix;

      # unique means there can only be one in the database like it.
      my $count = $rs->search( { $name => $value } )->count;

      # not found, this one is unique
      next if $count < 1;
      # found this value, but it's the same row we're updating
      next
         if $count == 1
            && $self->item_id
            && $self->item_id == $rs->search( { $name => $value } )->first->id;
      my $field_error = $field->unique_message || $error_message || 
            $self->profile->{'unique'}->{$name};
      $field->add_error( $field_error );
      $found_error++;
   }

   return $found_error;
}

=head2 init_item

This is called first time $form->item is called.
If using the Catalyst plugin, it sets the DBIx::Class schema from
the Catalyst context, and the model specified as the first part
of the object_class in the form. If not using Catalyst, it uses
the "schema" passed in on "new".

It then does:  

    return $self->resultset->find( $self->item_id );

It also validates that the item id matches /^\d+$/.  Override this method
in your form class (or form base class) if your ids do not match that pattern.

If a database row for the item_id is not found, item_id will be set to undef.

=cut

sub init_item
{
   my $self = shift;

   my $item_id = $self->item_id or return;
   return unless $item_id =~ /^\d+$/;
   my $item = $self->resultset->find($item_id);
   $self->item_id(undef) unless $item;
   return $item;
}

sub set_item_id
{
   my ( $self, $item ) = @_;
   $self->item_id( $item->id );
}

=head2 init_schema

Initializes the DBIx::Class schema. User may override. Non-Catalyst
users should pass schema in on new:  
$my_form_class->new(item_id => $id, schema => $schema)

=cut

sub init_schema
{
   my $self = shift;
   return if exists $self->{schema};
   # better not to mix the catalyst context in here, but
   # leaving here for compatibility
   if ( my $c = $self->user_data->{context} ) 
   {
       # starts out <model>::<source_name>
       my $schema = $c->model( $self->object_class )->result_source->schema;
       # change object_class to source_name
       $self->source_name( $c->model( $self->object_class )->result_source->source_name );
       return $schema;
   }
   die "Schema must be defined for Form::Processor::Model::DBIC";
}

sub init_source_name
{
   my $self = shift;
   return $self->object_class;
}

=head2 source

Returns a DBIx::Class::ResultSource object for this Result Class.

=cut

sub source
{
   my ( $self, $f_class ) = @_;
   return $self->schema->source( $self->source_name || $self->object_class );
}

=head2 resultset

This method returns a resultset from the "object_class" specified
in the form, or from the foreign class that is retrieved from
a relationship.

=cut

sub resultset
{
   my ( $self, $f_class ) = @_;
   return $self->schema->resultset( $self->source_name || $self->object_class );
}

=head2 many_to_many

When passed the name of the has_many relationship for a many_to_many
pseudo-relationship, this subroutine returns the relationship and column
name from the mapping table to the current table, and the relationship and
column name from the mapping table to the foreign table.

This code assumes that the mapping table has only two columns 
and two relationships, and you must have correct DBIx::Class relationships
defined.

For different table arrangements you could subclass 
this method to return the correct relationship and column names. 

=cut

sub many_to_many
{
   my ( $self, $has_many_rel ) = @_;

   # get rel and col pointing to self from reverse
   my $source     = $self->source;
   my $rev_rel    = $source->reverse_relationship_info($has_many_rel);
   my ($self_rel) = keys %{$rev_rel};
   my ($cond)     = values %{ $rev_rel->{$self_rel}{cond} };
   my ($self_col) = $cond =~ m/^self\.(\w+)$/;

   # assume that the other rel and col are for foreign table
   my @rels = $source->related_source($has_many_rel)->relationships;
   my $foreign_rel;
   foreach (@rels) { $foreign_rel = $_ if $_ ne $self_rel; }
   my $foreign_col;
   my @cols = $source->related_source($has_many_rel)->columns;
   foreach (@cols) { $foreign_col = $_ if $_ ne $self_col; }

   return ( $self_rel, $self_col, $foreign_rel, $foreign_col );
}

=head1 SUPPORT

The author can be contacted through the L<Catalyst> or L<DBIx::Class> mailing 
lists or IRC channels (gshank).

=head1 SEE ALSO

L<Form::Processor>
L<Form::Processor::Field>
L<Form::Processor::Model::CDBI>
L<Catalyst::Controller:Form::Processor>
L<Rose::Object>

=head1 AUTHOR

Gerda Shank

=head1 CONTRIBUTORS

Based on L<Form::Processor::Model::CDBI> written by Bill Moseley.

=head1 LICENSE

This library is free software, you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut

no Moose;
1;
