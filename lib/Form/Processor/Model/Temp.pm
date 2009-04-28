
   foreach $field ( $self->fields )
   {
      if ( $source->has_column($name) )
      {
         return $item->$name; 
      }
      elsif ( $source->has_relationship($name) )
      {
         if ( $field->can('multiple') && $field->multiple == 1 ) 
         {
            # has_many Multiple field
            my ( undef, undef, undef, $foreign_col ) = $self->many_to_many($column);
            my @rows = $item->search_related($name)->all;
            my @values = map { $_->$foreign_col } @rows;
            return @values;
         }
         elsif ($field->can('options'))
         {
            return $item->$name->id; 
         } 
         else # some other relationship
         {
            my $rel_info = $source->relationship_info($column);
            if ( $rel_info->{attrs}->{accessor} eq 'single' ||
                 $rel_info->{attrs}->{accessor} eq 'filter' )
            {
               return $item->$name->get_inflated_columns; 
            }
            else # multi relationship
            {
               
            }
         }
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
