package Asterisk::LCR;
use warnings;
use strict;

our $VERSION = '0.04';

1;

__END__

=head1 NAME

Asterisk::LCR - Least Cost Routing for Asterisk


=head1 SYNOPSIS

Asterisk::LCR is an open-source, Perl-based collection of tools to help you
manage efficiently multiple VoIP providers with your Asterisk installation.

It attempts to be sort of clean, simple and well documented.


=head1 CONFIGURATION

Once Asterisk::LCR is installed, you need to write a configuration file.

  $] cat /etc/asterisk-lcr.cfg
  
  [comparer]
  package  = Asterisk::LCR::Comparer::XERAND
  currency = eur
  
  [dialer]
  package  = Asterisk::LCR::Dialer::MinCost
  locale   = eu
  
  [import:voipjet]
  package  = Asterisk::LCR::Importer::VoIPJet
  uri      = http://www.voipjet.com/rates.csv
  target   = voipjet.txt
  dial     = us IAX2/login@voipjet/REPLACEME
  
  [import:nufone]
  package  = Asterisk::LCR::Importer::NuFone
  uri      = http://www.nufone.net/rates.csv
  target   = nufone.txt
  dial     = us IAX2/login@NuFone/REPLACEME

Let's examine the few sections of this configuration file:


=head2 comparer section

There needs to be a configuration section named [comparer], which defines what
comparing strategy to use.

  [comparer]
  package  = Asterisk::LCR::Comparer::XERAND
  currency = eur

You can switch comparing strategies using the 'package' attribute. At the
moment of this writing there are only two packages:

You can write you own comparer modules by subclassing the
L<Asterisk::LCR::Comparer> package.


=head3 comparer - Asterisk::LCR::Comparer::Dummy

Compares rates without paying attentions to details like currency, connection charge or per minute billing.

Pretty dumb, but useful to see how things work and for debugging.


=head3 comparer - Asterisk::LCR::Comparer::XERAND

Compares rates by converting currency using XE's website.

Then, compares, say, a 30/6 with a 1/1 rate by running a simulation of how much
it would actually cost with calls of random value between 0 and 200 seconds.


=head2 dialer section

You can choose between two strategies:


=head3 dialer - Asterisk::LCR::Dialer::MinCost

This strategy minimizes cost by trying from cheapest to most expensive provider
for any given route, in the limit of 3 providers.

  [dialer]
  package  = Asterisk::LCR::Dialer::MinCost
  locale   = fr
  limit    = 3

=head3 dialer - Asterisk::LCR::Dialer::MinTime

This strategy minimizes PDD (Post-Dialing-Delay) by trying dialing out the 3
cheapest providers at the same time.

  [dialer]
  package  = Asterisk::LCR::Dialer::MinCost
  locale   = fr
  limit    = 3


=head2 import modules

ATTENTION: ALL import sections must be named [import:<something>] and ALL of
them must have a unique name.

These modules are used to import / download rates from various providers. The
following modules are available.


=head3 import - Asterisk::LCR::Import::VoIPJet

Import module for VoIPJet.

  [import:voipjet]
  package  = Asterisk::LCR::Importer::VoIPJet
  target   = voipjet.txt
  dial     = us IAX2/login@voipjet/REPLACEME

Note the 'dial' parameter which is a dial template. In this example, 'us'
indicate that VoIPJet uses US style dialing and IAX2/login@voipjet/REPLACEME is
a dial template which needs to be replaced with your own login. REPLACEME is
automagically replaced with the right "stuff" when the dialplan is generated.

This dial template assumes that voipjet's peer definition is placed under
[voipjet] in iax.conf.


=head3 import - Asterisk::LCR::Import::NuFone

Import module for NuFone. (Unfortunately, NuFone no longer has international
destinations on its price list).

  [import:nufone]
  package  = Asterisk::LCR::Importer::NuFone
  target   = nufone.txt
  dial     = us IAX2/login@NuFone/REPLACEME

This dial template assumes that nufone's peer definition is placed under
[NuFone] in iax.conf.


=head3 import - Asterisk::LCR::Import::PlainVoip

Import module for PlainVoip.

  [import:plainvoip]
  package  = Asterisk::LCR::Importer::PlainVoip
  target   = plainvoip.txt
  dial     = us IAX2/login@PlainVoip/REPLACEME

This dial template assumes that plainvoip's peer definition is placed under
[PlainVoip] in iax.conf.


=head3 import - Asterisk::LCR::Import::CanonicalCSV

Any CSV file which uses a specific .CSV format can be used by Asterisk::LCR. In
fact, VoIPJet and NuFone's importers simply convert their CSV format into a
standardized, canonical format. The format is as follows:

  $] cat some_other_provider.txt
  prefix,label,provider,currency,rate,connection_fee,first_increment,increment
  262,Reunion Island,Ykoz,EUR,0.035,0,1,1
  262692,Reunion Island Mobile,Ykoz,EUR,0.15,0,1,1

Any provider providing this CSV format can instantly be used with
Asterisk::LCR. Encourage yours to provide rates in this format today!


=head1 USAGE

First you need to create a working directory in which you will use the LCR tools.

mkdir /tmp/lcrstuff

Once you have written your configuration file, you can do three things:

=head2 STEP 1 : Import your provider's rates

  cd /tmp/lcr
  asterisk-lcr-import

This will import all the providers you have defined in the [provider:something]
sections and write them onto disk in a canonical format.


=head2 STEP 2 : Generate the LCR database tree

  cd /tmp/lcr
  asterisk-lcr-build

This will generate a <prefix> => [ list of sorted rates ] tree from the rates
which you have imported.


=head2 STEP 3 : Generate your optimized dialplan

  cd /tmp/lcr
  asterisk-lcr-dialplan >/etc/asterisk/lcr-dialplan.conf

This will generate an optimized dialplan which you can cut and paste (or more
likely include) in your Asterisk's dialplan.


=head1 Locales

Asterisk::LCR is capable of generating dialplans which implement your local
dialing conventions.

Locales are located in text files which can be found in this distribution under
./lib/Asterisk/LCR/Locale/

At the time of this writing there are two implemented translation tables:
us.txt (for US-style dialing) and fr.txt (for France + overseas departments
dialing).

Feel free to submit your own translations tables to me! I will add them in the
distribution.

US Locale translation tables:

  "011"   ""         # International prefixes are removed
  "1"     "1"        # If it start with a '1', then it's all good


FR Locale translation tables:

The remains of what used to be the 'French Empire' make things a little more complicated...

  # local prefix  <tab>   global number replacement
  
  "00"    ""         # international prefix is replaced by nothing, i.e 0044X. => 44X.
  
  "0262"  "262262"   # These prefixes are for overseas department, which within France are
  "0692"  "262692"   # dialed as a national number but have separate country codes at the
  "0590"  "590590"   # international telephony level
  "0690"  "590690"
  "0594"  "594594"
  "0694"  "594694"
  "0596"  "596596"
  "0696"  "596696"
  
  "0"     "33"       # 0X. => 0033X.


=head1 LICENSE

  Copyright 2006 - Jean-Michel Hiver - All Rights Reserved

  Asterisk::LCR is under the GPL license. See the LICENSE file for details.

  Mailing list: not yet. Someone fancy setting one up for me?
  Contact: jhiver@ykoz.net
