package Asterisk::LCR::Dialer::MinCost;
use base qw /Asterisk::LCR::Dialer/;
use warnings;
use strict;


sub _process
{
    my $self   = shift;
    my $prefix = shift || return;
    my @rates  = $self->rates ($prefix);
    @rates || return [];

    my $local_prefix = $self->locale() ? $self->locale()->global_to_local ($prefix) : $prefix;
    my $exten_remove = length ($local_prefix);
    
    $prefix = "$prefix\${EXTEN:$exten_remove}";
    my $res ||= [];
    foreach my $rate (@rates)
    {
        my $str = $self->dial_string ($prefix, $rate) || next;
        push @{$res}, $str;
    }
    
    return $res;
}


1;

__END__
         $after  = '' unless (defined $after);
         $before = '' unless (defined $after);

         $dial_string = "$before$stuff\${EXTEN:$exten_remove}$after";

unless ($before)
{
use Data::Dumper;
warn Dumper (\%fake_agi_args);
warn Dumper ($rate);
warn <<EOF;
$orig_dial;
rate_dial_template : $rate_dial_template
dial               : $dial_string
str_before         : $str_before
str_after          : $str_after
before             : $before
stuff              : $stuff
exten              : \${EXTEN:$exten_remove}
after              : $after
EOF
print "_$prefix" . "X. => s,$count,Dial($dial_string)\n";
exit;
}

         push @out, "_$prefix" . "X. => s,$count,Dial($dial_string)";
         $count++;


1;


__END__
