=head1 NAME

Asterisk::LCR::Importer::NuFone


=head1 SYNOPSIS

  use Asterisk::LCR::Importer::NuFone;
  my $import = Asterisk::LCR::Importer::NuFone->new();
  my $rates  = $import->rates();

=cut
package Asterisk::LCR::Importer::NuFone;
use base qw /Asterisk::LCR::Importer/;
use warnings;
use strict;
use LWP::Simple;
use Asterisk::LCR::Rate;


sub get_data
{
    my $data = `wget --no-check-certificate -O - https://www.nufone.net/rates.csv`;
    $data || die "Could not retrieve NuFone price list";

    my @data = split /\n/, $data;
    return \@data;
}


##
# $self->rates();
# ---------------
# Returns a { <international_code> => <rate> } hash reference
##
sub rates
{
    my $self = shift;
    my $data = get_data();

    my $res  = {};
    for (@{$data})
    {
        my ($label, $dialcode1, $dialcode2, $rate) = split /\s*,\s*/, $_;
        my $dialcode = $dialcode1 . $dialcode2;
        
        # To my knowledge, NuFone is using 15/15 billing
        $res->{$dialcode} = Asterisk::LCR::Rate->new (
	    connection_fee  => 0,
	    first_increment => 15,
	    increment       => 15,
	    currency        => 'USD',
	    rate            => $rate,
	    provider	    => 'nufone',
	    label	    => $label,
            prefix          => $dialcode,
	);
    }
    
    return $res;
}


1;


__END__
