package TTXMarkup;
#
# Markup language pack/upack routines
#
# This module is a part of Trouble Ticket Express package
# http://www.troubleticketexpress.com
#
# COPYRIGHT: 2004-2007, United Web Coders
# http://www.unitedwebcoders.com
#
# $Revision: 437 $
# $Date: 2007-10-11 16:22:32 +0400 (Thu, 11 Oct 2007) $
#
#
$TTXMarkup::VERSION='2.24';
BEGIN {
  $TTXMarkup::REVISION = '$Revision: 437 $';
  if ($TTXMarkup::REVISION =~ /(\d+)/) {
    $TTXMarkup::REVISION = $1;
  }
};
use strict;

# ========================================================================= html

sub html {
  my $buff = shift;
  $buff =~ s/\[(\/?)(u|b|i|code|small)]/<$1$2>/gi; # [b] [i] [u] [code] [small]
  $buff =~ s/\[\(]/[/g; # [[]
  $buff =~ s/\[url\s+([^]\s]+)\s*]/<a href="$1" target=_blank>/gi;
  $buff =~ s/\[\/url\s*]/<\/a>/gi;
  $buff =~ s/\[(image|img)\s+([^]\s]+)\s*]/<img src="$2">/gi;
  $buff =~ s/\[\/(image|img)\s*]/<\/img>/gi;
  $buff =~ s/  /&nbsp; /g;
  return $buff;
}
# ========================================================================= help

sub help {
  return undef;
}
# ======================================================================== strip

sub strip {
  my $buff = shift;
  $buff =~ s/\[(\/?)(u|b|i|code|small)]//gi; # [b] [i] [u] [code] [small]
  $buff =~ s/\[\(]/[/g; # [[]
  $buff =~ s/\[url\s+([^]\s]+)\s*]/$1 /gi;
  $buff =~ s/\[\/url\s*]/ /gi;
  $buff =~ s/\[(image|img)\s+([^]\s]+)\s*]/$2 /gi;
  $buff =~ s/\[\/(image|img)\s*]//gi;
  return $buff;
}
1;
#
