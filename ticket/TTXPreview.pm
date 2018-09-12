package TTXPreview;
#
# This module is a part of Trouble Ticket Express package
# http://www.troubleticketexpress.com
#
# COPYRIGHT: 2006-2007, United Web Coders
# http://www.unitedwebcoders.com
#
# $Revision: 441 $
# $Date: 2007-10-11 16:25:43 +0400 (Thu, 11 Oct 2007) $
#

$TTXPreview::VERSION='2.24';
BEGIN {
  $TTXPreview::REVISION = '$Revision: 441 $';
  if ($TTXPreview::REVISION =~ /(\d+)/) {
    $TTXPreview::REVISION = $1;
  }
};
use strict;
use TTXCommon;
require TTXMarkup;

# ======================================================================== print
sub preview {
  my ($cfg, $query, $data) = @_;
  $data->{PAGEHEADING} = '[%Message Preview%]';
  my $body = TTXCommon::cleanit($query, 'msg',1);
  $body =~ s/</&lt;/g;
  $body = TTXMarkup::html($body);
  $body =~ s/\n/<br>\n/g;
  $data->{MESSAGE} = $body;
  return undef;
}
1;
#
