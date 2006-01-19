=head1 NAME

Asterisk::LCR::Importer::PlainVoip


=head1 SYNOPSIS

  use Asterisk::LCR::Importer::PlainVoIP;
  my $import = Asterisk::LCR::Importer::VoIPJet->new();
  my $rates  = $import->rates();

=cut
package Asterisk::LCR::Importer::PlainVoip;
use base qw /Asterisk::LCR::Importer/;
use Asterisk::LCR::Locale;
use Asterisk::LCR::Rate;
use warnings;
use strict;
use LWP::Simple;


sub get_data
{
    my $data = LWP::Simple::get ("http://www.plainvoip.com/ratedump.php");
    $data || die "Could not retrieve PlainVoip price list";

    my @data = split /\n/, $data;
    shift (@data); # column names, don't need

    return \@data;
}


##
# $self->rates();
# ---------------
# Returns a { <international_code> => <rate> } hash reference
##
sub rates
{
    my $self   = shift;
    my $data   = get_data();
    my $locale = Asterisk::LCR::Locale->new ("us");
    my $res  = {};
    for (@{$data})
    {
        my ($dialcode, $label, $first_inc, $next_inc,$rate) = $_ =~ /^(.*?),(.*?),(\d+?)\/(\d+?),(.*?)\n?$/;
        defined $dialcode and defined $label and defined $first_inc and defined $next_inc and defined $rate or next;

        $dialcode = $locale->local_to_global ($dialcode);
        $res->{$dialcode} = Asterisk::LCR::Rate->new (
	    connection_fee  => 0,
	    first_increment => $first_inc,
	    increment       => $next_inc,
	    currency        => 'USD',
	    rate            => $rate,
	    provider	    => 'plainvoip',
 	    label           => $label,
	    prefix          => $dialcode,
	);
    }
    
    return $res;
}


1;


__END__
