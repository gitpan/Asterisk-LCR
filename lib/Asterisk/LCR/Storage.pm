package Asterisk::LCR::Storage;
use qw /Asterisk::LCR::Object/;
use warnings;
use strict;

=head2 $storage->set ($prefix, $rate)

Sets a rate object for $prefix. If for this prefix, a rate was present for the
same provider, it should override it.

=cut
sub set
{
    my $self   = shift;
    my $prefix = shift;
    $self->_set ($prefix, $_) for (@_);
}
