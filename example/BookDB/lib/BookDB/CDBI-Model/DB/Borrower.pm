package BookDB::Model::DB::Borrower;

use strict;

__PACKAGE__->columns(list=>qw/name email/);
__PACKAGE__->columns(view=>qw/name email phone url/);
__PACKAGE__->columns(Stringify=> qw/name/);

=head1 NAME

BookDB::Model::DB::Borrower - CDBI Table Class

=head1 SYNOPSIS

See L<BookDB>

=head1 DESCRIPTION

CDBI Table Class.

=head1 AUTHOR

Gerda Shank

=head1 LICENSE

This library is free software . You can redistribute it and/or modify
it under the same terms as perl itself.

=cut

1;
