package TTXData;
#
# Application wide globals
#
# This module is a part of Trouble Ticket Express package
# http://www.troubleticketexpress.com
#
# COPYRIGHT: 2003-2007, United Web Coders
# http://www.unitedwebcoders.com
#
# $Revision: 435 $
# $Date: 2007-10-11 16:19:23 +0400 (Thu, 11 Oct 2007) $
#

$TTXData::VERSION='2.24';
BEGIN {
  $TTXData::REVISION = '$Revision: 435 $';
  if ($TTXData::REVISION =~ /(\d+)/) {
    $TTXData::REVISION = $1;
  }
};
use strict;

# ====================================================================== GLOBALS
my $globals = {};

# ========================================================================== get

sub get {
  return $globals->{$_[0]};
}
# ========================================================================== set

sub set {
  my $name = shift;
  my $value = shift;
  my $old = $globals->{$name};
  $globals->{$name} = $value;
  return $old
}


1;
#
