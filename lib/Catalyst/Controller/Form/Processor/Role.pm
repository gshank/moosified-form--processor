package Catalyst::Controller::Form::Processor::Role;

use Moose::Role;
with 'Catalyst::Component::InstancePerContext';

use Carp;
use UNIVERSAL::require;

our $VERSION = '0.01_01';

=head1 NAME

Catalyst::Controller::Form::Processor::Role

=head1 SYNOPSIS

A Moose role for Catalyst controllers to use
Form::Processor forms.

=head1 DESCRIPTION

In a Catalyst controller:

   package MyApp::Controller::Book;

   use Moose;
   use base 'Catalyst::Controller';
   with 'Catalyst::Controller::Form::Processor::Role';

   __PACKAGE__->config( model_name => 'DB', form_name_space => 'MyApp::Form');

   sub edit : Local {
      my ( $self, $c ) = @_;
      $c->forward('do_form');
   }

   sub form : Private {
       my ( $self, $c, $id ) = @_;

      # Name template, or allow default 'book/add.tt'
      $self->ctx->stash->{template} = 'book/form.tt';

      # Name form, or use default 'Book::Add'
      my $validated = $self->update_from_form( $id, 'Book' ); 
      return if !$validated; # This (re)displays the form, because it's the
                             # 'end' of the method, and the 'default end' action
                             # takes over, which is to render the view
      # or simpler syntax: return unless $self->update_from_form( $id, 'Book');

      # get the new book that was just created by the form
      my $new_book = $c->stash->{form}->item;

      $c->res->redirect($c->uri_for('list'));
   }


=cut

has 'form_name_space' => ( isa => 'Str|Undef', is => 'rw', lazy => 1,
     builder => 'build_form_name_space');
sub build_form_name_space { 
   my $self = shift;
   return $self->config->{form_name_space} ||
          ref( $self->ctx ) . "::Form";
}
has 'model_name' => ( isa => 'Str', is => 'rw', 
     builder => 'build_model_name');
sub build_model_name { shift->config->{model_name} || '' } 
has 'model' => (  is => 'rw', lazy => 1, builder => '_build_model' );
sub _build_model {
   my $self = shift;
   return $self->ctx->model($self->model_name) if $self->model_name;
}
has 'ctx' => ( isa => 'Catalyst', is => 'rw' );


sub build_per_context_instance {
   my ( $self, $c ) = @_;
   $self->ctx( $c );
   return $self;
}

=head1 Config Options

=over 4

=item model_name

Set the Catalyst model name. Currently only used by
L<Form::Processor::Model::DBIC>.

=item form_name_space

Set the name space to look for forms. Otherwise, forms will
be found in a "Form" directory parallel to the controller directory.
Override with "+" and complete package name. 

=head1 METHODS

=over 4

=item get_form

Determine the form package name, and "require" the form.
Massage the parameters into the form expected by Form::Processor,
including getting the schema from the model name and passing it
into the DBIC model. Put the form object into the Catalyst stash.

=cut

sub get_form
{
   my ( $self, $args_ref, $form_name, $model_name ) = @_;

   # Determine the form package name
   my $package;
   if ( defined $form_name )
   {
      my $form_prefix = $self->form_name_space . "::";
      $package =
           $form_name =~ s/^\+//
         ? $form_name
         : $form_prefix . $form_name;
   }
   else
   {
      $package = $self->ctx->action->class;
      $package =~ s/::C(?:ontroller)?::/::Form::/;
      $package .= '::' . ucfirst( $self->ctx->action->name );
   }
   $package->require
      or die "Failed to load Form module $package";

   # Single argument to Form::Processor->new means it's an item id or object.
   # Hash references must be turned into lists.
   my %args;
   if ( defined $args_ref )
   {
      if ( ref $args_ref eq 'HASH' )
      {
         %args = %{$args_ref};
      }
      elsif ( Scalar::Util::blessed($args_ref) )
      {
         %args = (
            item    => $args_ref,
            item_id => $args_ref->id,
         );
      }
      else
      {
         %args = ( item_id => $args_ref );
      }
   }
   # Save the Catalyst context
   $args{user_data}{context} = $self->ctx;

   # Set model if passed in
   my $model = $self->ctx->model($model_name) if $model_name;
   $model ||= $self->model;

   if ( $package->isa('Form::Processor::Model::DBIC') )
   {
      # schema only exists for DBIC model
      die "No model to create schema for C::C::F::P" unless $model;
      $args{schema} = $model->schema;
   }

   return $self->ctx->stash->{form} = $package->new(%args);
      

} ## end sub get_form

=item validate_form

Validate the form

=cut

sub validate_form
{
   my $self = shift;
   my $form = $self->get_form(@_);
   return $self->form_posted
      && $form->validate( $self->ctx->req->parameters );
}

=item update_from_form

Use for forms that have a database interface

=cut

sub update_from_form
{
   my $self = shift;
   my $form = $self->get_form(@_);
   return $self->form_posted
      && $form->update_from_form( $self->ctx->req->parameters );
}

=item form_posted

convenience method checking for POST

=cut

sub form_posted
{
   my ($self) = @_;
   return $self->ctx->req->method eq 'POST';
}



=head1 AUTHOR

Gerda Shank, modeled on Catalyst::Plugin::Form::Processor by Bill Moseley

=head1 COPYRIGHT

This library is free software, you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut

no Moose;
1;
