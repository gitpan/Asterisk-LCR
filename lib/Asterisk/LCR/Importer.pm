=head1 NAME

Asterisk::LCR::Importer


=head1 SYNOPSIS

  See concrete classes.

=cut
package Asterisk::LCR::Importer;
use base qw /Asterisk::LCR::Object/;
use warnings;
use strict;
use LWP::Simple;
use Asterisk::LCR::Rate;



sub provider
{
    my $self = shift;
    return $self->{provider} || do {
        my $class = ref $self;
        $class =~ s/.*:://;
        return lc ($class);
    };
}


##
# $self->rates();
# ---------------
# Returns a { <international_code> => <rate> } hash reference
##
sub rates
{
    die "Asterisk::LCR::Importer::rate() is a virtual method.";
}


sub target
{
    my $self = shift;
    return $self->{target} || do {
        my $string = ref $self || $self;
        $string =~ s/.*:://;
        $string = lc ($string);
        "$string.txt";
    };
}

1;


__END__
