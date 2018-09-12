package TTXOpers;
#
# This module is a part of Trouble Ticket Express package
# http://www.troubleticketexpress.com
#
# COPYRIGHT: 2002-2007, United Web Coders
# http://www.unitedwebcoders.com
#
# $Revision: 439 $
# $Date: 2007-10-11 16:24:36 +0400 (Thu, 11 Oct 2007) $
#

$TTXOpers::VERSION='2.24';
BEGIN {
  $TTXOpers::REVISION = '$Revision: 439 $';
  if ($TTXOpers::REVISION =~ /(\d+)/) {
    $TTXOpers::REVISION = $1;
  }
};

use strict;
use TTXUser;

# ===================================================================== selector

sub selector {
  my ($cfg, $query, $data) = @_;
  $data->{OPERSELSTD} = '<tr><td align=right class=lbl>[%Assign to%]<font color=red><sup>*</sup></font></td>'."\n<td align=left>";
  $data->{OPERSEL} = "<select name=oper>\n".'<option value="">-- [%please select%] --</option>'."\n".
                     "<option value=\"-\"";
  $data->{OPERSEL} .= ' selected' if $query->param('oper') eq '-';
  $data->{OPERSEL} .= '>-- [%any operator%] --</option>'."\n";
  my @operlist = TTXUser::list();
  my %operinfo;
  foreach my $id (@operlist) {
    my $u = TTXUser->new($id);
    next if $u eq undef;
    $operinfo{$id} = $u;
  }
  foreach my $id (sort {uc($operinfo{$a}->{lname}) cmp uc($operinfo{$b}->{lname})} keys %operinfo) {
    my $oper = $operinfo{$id}->{fname}.' '.$operinfo{$id}->{lname};
    next if $oper eq undef || $oper eq '';
    $oper =~ s/</&quot;/g;
    $data->{OPERSEL} .= "<option value=\"$id\"";
    $data->{OPERSEL} .= ' selected' if $query->param('oper') eq $id;
    $data->{OPERSEL} .= ">$oper</option>\n";
  }
  $data->{OPERSEL} .= '</select>';
  $data->{OPERSELSTD} .= $data->{OPERSEL} . "</td></tr>\n";
}

1;
#
