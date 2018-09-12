package TTXDictionary;
#
# This module is a part of Trouble Ticket Express package
# http://www.troubleticketexpress.com
#
# COPYRIGHT: 2002-2007, United Web Coders
# http://www.unitedwebcoders.com
#
# $Revision: 435 $
# $Date: 2007-10-11 16:19:23 +0400 (Thu, 11 Oct 2007) $
#

$TTXDictionary::VERSION='2.24';
BEGIN {
  $TTXDictionary::REVISION = '$Revision: 435 $';
  if ($TTXDictionary::REVISION =~ /(\d+)/) {
    $TTXDictionary::REVISION = $1;
  }
};

use strict;
use CSV;
require TTXCommon;
my %dictionary;
my $isLoaded;
my $uselang;

# ========================================================================= lang

sub lang {
  my $uselang = $_[0];
}
# ========================================================================= load

sub load {
  return 1 if $isLoaded;
  my $cfg = TTXData::get('CONFIG');
  my $dictname = 'dict'.(($uselang ne undef) ? "-$uselang":'').'.csv';
  my $fn = $cfg->get('basedir')."/$dictname";
  if (open(CSV, $fn)) {
    foreach (my $line = <CSV>; $line ne undef; $line = <CSV>) {
      chomp($line);
      $line =~ s/(\r|\n)+$//;
      my ($en, $trans) = CSVsplit($line);
      $dictionary{$en} = TTXCommon::decodeit($trans);
    }
    close CSV;
  }
  if ($cfg->get('charset') ne undef) {
    $dictionary{CHARSET} = TTXCommon::decodeit($cfg->get('charset'));
  }
  if ($dictionary{CHARSET} eq undef) {
    $dictionary{CHARSET} = 'ISO-8859-1';
  }
  $isLoaded = 1;
  return 1;
}
# ==================================================================== translate

sub translate {
  my $txt = $_[0];
  load();
  if (defined $dictionary{$txt}) {
    $txt = $dictionary{$txt};
  }
  return $txt;
}

1;
#
