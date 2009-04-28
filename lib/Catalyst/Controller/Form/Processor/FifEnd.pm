package Catalyst::Controller::Form::Processor::FifEnd;

use Moose::Role;

=head1 NAME

Catalyst::Controller::Form::Processor::WithFifEnd

=head1 SYNOPSIS

In your controller:

   use Moose;
   use base 'Catalyst::Controller';
   with 'Catalyst::Controller::Form::Processor::Role';
   with 'Catalyst::Controller::Form::Processor::FifEnd';

=head1 DESCRIPTION

The "end" method will use FillInForm to render the form, unless
the "fif" config value has been set to false.

If you have a custom "end" routine in your subclassed controllers
and want to use FillInForm to fill in your forms, you can use
this as a sample of how to handle FillInForm in your custom 'end'.

=back

=cut

sub end : Private
{

   my ( $self, $ctx ) = (shift, shift);

   my $form = $ctx->stash->{form};
   # The following will call the "end" in Root.pm
   # $ctx->forward('/end');

   # ActionClass('RenderView') must happen before FillInForm
   $ctx->forward('render') unless $ctx->res->output;
   if( $form )
   {
      # Use FillInForm to fill in form fields 
      if( HTML::FillInForm->require )
      { 
         $ctx->response->body(
            HTML::FillInForm->new->fill(
               scalarref => \$ctx->response->{body},
               fdat      => $form->fif,
            )
         );
      }
   }
}

sub render : ActionClass('RenderView') { }
