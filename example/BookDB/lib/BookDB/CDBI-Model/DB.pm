package BookDB::Model::DB;

use strict;
use base 'Catalyst::Model::CDBI';


__PACKAGE__->config(
    dsn           => 'dbi:SQLite:db/book.db',
    user          => '',
    password      => '',
    additional_base_classes => [qw/Class::DBI::AsForm Class::DBI::FromForm/],
    left_base_classes  => qw/Class::DBI::Sweet/,
    options       => {},
    relationships => 1
);

=head1 NAME

BookDB::Model::DB - CDBI Model Component

=head1 SYNOPSIS

See L<BookDB>

=head1 DESCRIPTION

CDBI Model Component.

=head1 AUTHOR

Gerda Shank

=head1 LICENSE

This library is free software . You can redistribute it and/or modify
it under the same terms as perl itself.

=cut

1;
