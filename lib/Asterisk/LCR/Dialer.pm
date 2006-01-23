=head1 NAME

Asterisk::LCR::Dialer - Generic dialer object


=head1 SYNOPSIS

  use Asterisk::LCR::Dialer;
  my $dialer = Asterisk::LCR::Dialer::<CONCRETE_CLASS>->new ();


=head1 SUMMARY

Represents a generic dialing strategy. The strategy is defined
in the $self->process() method, which in this package is undefined.


=head1 ATTRIBUTES

=head2 lcr (scalar)

Location (directory) of the lcr object tree.

=head2 agi (Asterisk::AGI object)

An AGI object which can be used to grab some parameters from.

=head2 limit (numerical scalar)

Limit dialing strategies to 'limit' cheapest routes.
Optional.

=head2 opts (scalar)

Options to be appended to the dialstring. Example:

  '120|HS(7200)'

=head1 METHODS

=cut
package Asterisk::LCR::Dialer;
use base qw /Asterisk::LCR::Object/;
use Asterisk::LCR::Locale;
use Config::Mini;
use warnings;
use strict;


our $STORE = undef;


=head2 $self->validate();

Returns TRUE if this object validates, FALSE otherwise.

=cut
sub validate
{
    my $self = shift;
    return $self->validate_lcr() &
           $self->validate_agi();
}


=head2 $self->validate_lcr();

Returns TRUE if there is a 'lcr' attribute and it's an existing
directory, FALSE otherwise.

=cut
sub validate_lcr
{
    my $self = shift;
    my $lcr  = $self->lcr() || do {
        die 'asterisk/lcr/lcr/dialer/lcr/undefined';
        return 0;
    };

    return 1;
}


=head2 $self->lcr();

Returns the 'lcr' attribute.

=cut
sub lcr
{
    my $self = shift;
    return $self->{lcr};
}


=head2 $self->set_lcr ($lcr);

Sets the 'lcr' attribute to $lcr.

=cut
sub set_lcr
{
    my $self = shift;
    $self->{lcr} = shift;
}


=head2 $self->locale();

Returns the 'locale' attribute.

=cut
sub locale
{
    my $self = shift;
    my $loc  = $self->{locale};
    return $loc ? Asterisk::LCR::Locale->new ($loc) : undef;
}


=head2 $self->set_locale ($locale);

Sets the 'locale' attribute to $locale.

=cut
sub set_locale
{
    my $self = shift;
    $self->{locale} = shift;
}



=head2 $self->validate_agi();

Returns TRUE if the 'agi' attribute exists,
FALSE otherwise.

=cut
sub validate_agi
{
    my $self = shift;
    
    my $agi  = $self->agi() || do {
        die 'asterisk/lcr/agi/dialer/agi/undefined';
        return 0;
    };
    
    return 1;
}


=head2 $self->agi();

Returns the 'agi' attribute.

=cut
sub agi
{
    my $self = shift;
    return $self->{agi};
}


=head2 $self->set_agi ($lcr);

Sets the 'agi' attribute to $agi.

=cut
sub set_agi
{
    my $self = shift;
    $self->{agi} = shift;
}


=head2 $self->limit();

Returns the optional 'limit' attribute.

Returns 100000 if it's not defined (quasi-infinity)

=cut
sub limit
{
    my $self = shift;
    return $self->{limit} || 100000;
}


=head2 $self->set_limit ($limit);

Sets the optional 'limit' attribute to $limit.

=cut
sub set_limit
{
    my $self = shift;
    $self->{limit} = shift;
}


=head2 $self->opts();

Returns the optional 'opts' attribute.

If the 'opts' attribute is not TRUE, returns an empty string.

If the 'opts' attribute doesn't start with a pipe symbol, returns
it prefixed with |.

=cut
sub opts
{
    my $self = shift;
    my $opts = $self->{opts};
    return '' unless ($opts);
    
    return ($opts =~ /^\|/) ? $opts : "|$opts";
}


=head2 $self->set_opts ($opts);

Sets the optional 'opts' attribute to $opts.

=cut
sub set_opts
{
    my $self = shift;
    $self->{opts} = shift;
}


=head2 $self->process ($number);

Turns $number into a canonical, global number if $number
if $self->locale() returns an Asterisk::LCR::Locale object.

Then calls $self->_process ($number). This method must
be defined in subclasses.

=cut
sub process
{
    my $self = shift;
    my $num  = shift;
    my $loc  = $self->locale();
    
    $loc and do { $num = $loc->local_to_global ($num) };
    $self->_process ($num);
}


sub _process
{
    die "Asterisk::LCR::Dialer::process() is a virtual method";
}


=head2 $self->dial ($str);

Dials string $str, eventually with options $self->opts();

=cut
sub dial
{
    my $self = shift;
    my $str  = shift || return;
    $str .= $self->opts();

    my $agi  = $self->agi();
    return $agi->exec ("DIAL $str");
}


=head2 $self->dial_string ($number, $rate)

Returns a string from a variable template suitable for use
within Dial()

Extract a string dial template from the asterisk config file.

For example, say $rate->{provider} = 'voipjet'. This method will look for
an asterisk variable called 'ASTERISK_LCR_TMPL_VOIPJET'. The grammar to be used
for this syntax is:

  VARIABLE: [LOCALE] DIAL_STRING

  LOCALE: (scalar string, i.e. 'us' or 'fr' or even /var/mylocale.txt)

  DIAL_STRING: <whateverwhatever>REPLACEME<whateverwhatever>

Where REPLACEME will be replaced by the phone number to dial.

If LOCALE is defined and an Asterisk::LCR::Locale object can be created,
then $num is assumed to be given as a canonical, international
number.

For example, if LOCALE is 'fr' and the number is 33575874745, then
05175874745 will be dialled instead.

Otherwise the number is dialed "as is".

=cut
sub dial_string
{
    my $self = shift;
    my $num  = shift || return;
    my $rate = shift || return;
    my $agi  = $self->agi();
    
    my $provider = $rate->{provider};
    my $astvar   = 'ASTERISK_LCR_TMPL_' . uc ($provider);
    my $value    = $agi->get_variable ($astvar) || return;
    
    my ($locale, $dialtmpl) = ($value =~ /\s/) ? ( split /\s+/, $value, 2 ) : (undef, $value);
    for ($locale)
    {
    	$locale || next;
    	$locale = Asterisk::LCR::Locale->new ($locale) || next;
    	$num = $locale->global_to_local ($num);
    }
    
    $dialtmpl || return;
    $dialtmpl =~ s/REPLACEME/$num/;
    return ($dialtmpl);
}


=head2 $self->rates ($number);

Returns an array of rates for $number, sorted cheapest first.

=cut
sub rates
{
    my $self  = shift;
    $STORE  ||= Config::Mini::instantiate ('storage') || die 'no storage backend configured...';
    return $STORE->list (@_);
}


1;


__END__
