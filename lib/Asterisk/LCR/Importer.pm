=head1 NAME

Asterisk::LCR::Importer

=cut
package Asterisk::LCR::Importer;
use base qw /Asterisk::LCR::Object/;
use Asterisk::LCR::Locale;
use Asterisk::LCR::Rate;
use LWP::Simple;
use warnings;
use strict;


sub uri { shift->{uri} || 'http://example.com/YOU_FORGOT_TO_SPECIFY_THE_RATES_URI' }


sub target
{
    my $self = shift;
    return $self->{target} || do { $self->provider() . '.csv' }
}


sub get_data
{
    my $self = shift;
    my $data = LWP::Simple::get ($self->uri());
    $data || die "Could not retrieve " . $self->uri();
    
    my @data = split /\r\n|\n|\r/, $data;
    return \@data;
}


sub separator { my $self = shift; $self->{separator} || '\,' }


sub prefix
{
    my $self = shift;
    my $rec  = shift;
    my $pos  = $self->prefix_pos();
    my $loc  = $self->prefix_locale();
    
    my $res  = $rec->[$pos];
    if ($loc)
    {
        $res = $loc->local_to_global ($res);
    }
    
    return $res;
}


sub prefix_pos { my $self = shift; return defined $self->{prefix_position} ? $self->{prefix_position} : 0 }


sub prefix_locale
{
    my $self = shift;
    $self->{prefix_locale} || return;
    $self->{prefix_locale_obj} ||= Asterisk::LCR::Locale->new ( $self->{prefix_locale} );
    return $self->{prefix_locale_obj};
}


sub label
{
    my $self = shift;
    my $rec  = shift;
    my $pos  = $self->label_pos();
    return $rec->[$pos];
}


sub label_pos  { my $self = shift; return defined $self->{label_position} ? $self->{label_position} : 1 }


sub provider
{
    my $self = shift;
    return $self->{provider} || do {
        my $uri = $self->uri();
        $uri =~ s/^.*\:\/\/(www\.)?//;
        $uri =~ s/\..*//;
        $uri;
    };
}


sub currency
{
    my $self = shift;
    return $self->{currency} || 'EUR';
}


sub rate
{
    my $self = shift;
    my $rec  = shift;
    my $pos  = $self->rate_pos();
    return $rec->[$pos];
}


sub rate_pos  { my $self = shift; return defined $self->{rate_position} ? $self->{rate_position} : 2 }


sub connection_fee
{
    my $self = shift;
    defined $self->{connection_fee} and return $self->{connection_fee};
    
    my $rec  = shift;
    my $pos  = $self->connection_fee_pos();
    return $rec->[$pos];
}


sub connection_fee_pos  { my $self = shift; return defined $self->{connection_fee_position} ? $self->{connection_fee_position} : 3 }


sub first_increment
{
    my $self = shift;
    defined $self->{first_increment} and return $self->{first_increment};
    my $rec  = shift;
    my $pos  = $self->first_increment_pos();
    return $rec->[$pos];
}


sub first_increment_pos  { my $self = shift; return defined $self->{first_increment_position} ? $self->{first_increment_position} : 4 }


sub increment
{
    my $self = shift;
    defined $self->{increment} and return $self->{increment};
    
    my $rec  = shift;
    my $pos  = $self->increment_pos();
    return $rec->[$pos];
}


sub increment_pos  { my $self = shift; return defined $self->{increment_position} ? $self->{increment_position} : 5 }


sub filter { return shift->{filter} || '^\d+,' }


sub rates
{
    my $self   = shift;
    $self->{rates} and return $self->{rates};
    
    my $data   = $self->get_data();
    my $filter = $self->filter();
    my $comma  = $self->separator();
     
    my $res  = {};
    for (@{$data})
    {
        /$filter/ or do {
            print "IGNORED: $_ (doesn't match /$filter/)\n";
            next;
        };
        my $rec = [ split /\s*$comma\s*/, $_ ];
        my $pfx = $self->prefix ($rec); 
        $res->{$pfx} = Asterisk::LCR::Rate->new (
            prefix          => $pfx,
            label           => $self->label ($rec),
            provider        => $self->provider ($rec),
            currency        => $self->currency ($rec),
            rate            => $self->rate ($rec),
            connection_fee  => $self->connection_fee ($rec),
            first_increment => $self->first_increment ($rec),
            increment       => $self->increment ($rec),
	);
    }
    
    $self->{rates} = $res;
    return $res;
}


1;


__END__
