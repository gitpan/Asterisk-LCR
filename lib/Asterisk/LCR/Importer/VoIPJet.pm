=head1 NAME

Asterisk::LCR::Importer::VoIPJet


=head1 SYNOPSIS

  use Asterisk::LCR::Importer::VoIPJet;
  my $import = Asterisk::LCR::Importer::VoIPJet->new();
  my $rates  = $import->rates();

=cut
package Asterisk::LCR::Importer::VoIPJet;
use base qw /Asterisk::LCR::Importer/;
use Asterisk::LCR::Rate;
use warnings;
use strict;
use LWP::Simple;


sub get_data
{
    my $data = LWP::Simple::get ("http://voipjet.com/ratescsv.php");
    $data || die "Could not retrieve VoIPJet price list";

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
    my $self = shift;
    my $data = get_data();

    my $res  = {};
    for (@{$data})
    {
        /incorrect dial/ and next;
        my ($label, $dialcode, $rate) = split /\s*,\s*/, $_;

        # Mexico: sixty (60) seconds minimum and six (6) seconds thereafter.
        $dialcode =~ /^01152/ and do {
            $dialcode =~ s/^011//;
            $res->{$dialcode} = Asterisk::LCR::Rate->new (
	        connection_fee  => 0,
	        first_increment => 60,
	        increment       => 6,
	        currency        => 'USD',
		rate            => $rate,
		provider	=> 'voipjet',
		label		=> $label,
		prefix          => $dialcode,
	    );
	    next;
	};

        # Continental USA: six (6) second increments.
	# Toll-Free termination, such as 1800/1888/1877/1866 numbers.
        $dialcode =~ /^1/ and do {
            $res->{$dialcode} = Asterisk::LCR::Rate->new (
	        connection_fee  => 0,
	        first_increment => 6,
	        increment       => 6,
	        currency        => 'USD',
		rate            => $rate,
		provider	=> 'voipjet',
		label		=> $label,
		prefix          => $dialcode,
	    );
	    next;
	};

        # International: thirty (30) seconds minimum and six (6) seconds thereafter.
        $dialcode =~ /^011/ and do {
            $dialcode =~ s/^011//;
            $res->{$dialcode} = Asterisk::LCR::Rate->new (
	        connection_fee  => 0,
	        first_increment => 30,
	        increment       => 6,
	        currency        => 'USD',
		rate            => $rate,
		provider	=> 'voipjet',
		label		=> $label,
		prefix          => $dialcode,
	    );
	    next;
	};

        warn "what about $dialcode? ($label, $rate)";
    }
    
    return $res;
}


1;


__END__
