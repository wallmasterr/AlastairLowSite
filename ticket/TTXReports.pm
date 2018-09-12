package TTXReports;
#
# This module is a part of Trouble Ticket Express package
# http://www.troubleticketexpress.com
#
# COPYRIGHT: 2002-2007, United Web Coders
# http://www.unitedwebcoders.com
#
# $Revision: 442 $
# $Date: 2007-10-11 16:26:35 +0400 (Thu, 11 Oct 2007) $
#

$TTXReports::VERSION='2.24';
BEGIN {
  $TTXReports::REVISION = '$Revision: 442 $';
  if ($TTXReports::REVISION =~ /(\d+)/) {
    $TTXReports::REVISION = $1;
  }
};

use strict;
use TTXCommon;
use TTXConfig;
use TTXDesk;
use TTXUser;
require TTXBarChart;
require TTXDictionary;
my @months = ('Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec');
my %globalDR;

# =================================================================== checkpoint

sub checkpoint {
  my $cfg = $_[0];
  my $grantlist = $cfg->get('grant.reports');
  if ($grantlist ne undef) {
    my $uid = $cfg->get('_USER')->get('login');
    if (!grep(/^$uid$/, split(/,/,$grantlist))) {
      return 0;
    }
  }
  return 1;

}
# ======================================================================= filter

sub mkfilter {
  my ($cfg, $query) = @_;
  my $browsetxt = 0;
  my $cfldcnt = TTXCommon::cfldcnt();
  my @filter;
  if ($query->param('oper') ne undef) {
    my $f;
    $f->{col} = 'oper';
    if ($query->param('oper') ne '-') {
      $f->{expr} = "^".$query->param('oper')."\$";
    } else {
      $f->{expr} = "^\$";
    }
    push @filter, $f;
  }
  if ($query->param('grp') ne undef) {
    my $f;
    $f->{col} = 'grp';
    if ($query->param('grp') ne '-') {
      $f->{expr} = "^".$query->param('grp')."\$";
    } else {
      $f->{expr} = "^\$";
    }
    push @filter, $f;
  }
  if ($query->param('item') ne undef) {
    my $f;
    $f->{col} = 'item';
    if ($query->param('item') ne '-') {
      $f->{expr} = "^.*;".TTXCommon::decodeit($query->param('item')).";.*\$";
    } else {
      $f->{expr} = "^\$";
    }
    push @filter, $f;
  }
  if ($cfg->get('accessctrl') && $cfg->get('routex') ne undef) {
    my $n = $cfg->get('routex');
    if ($n =~ /^\d$/) {
      eval "use TTXCustomRoute";
      if ($@ eq undef) {
        my @list = TTXCustomRoute::grouplist($cfg);
        if (@list > 0) {
          my $f;
          $f->{col} = "c$n";
          $f->{expr} = '^('.join('|', @list).')$';
          push @filter, $f;
        }
      }
    }
  }
  if ($cfg->get('accessctrl') && $cfg->get('_USER') ne undef) {
    eval "use TTXGroups";
    if ($@ eq undef) {
      my @list = TTXGroups::grouplist($cfg, $cfg->get('_USER')->{login});
      my $f;
      $f->{col} = '-grp-';
      $f->{groups} = \@list;
      $f->{oper} = $cfg->get('_USER')->{login};
      push @filter, $f;
    }
  }
  if ($query->param('status') ne undef) {
    my $f;
    $f->{col} = 'status';
    $f->{expr} = "^".$query->param('status')."\$";
    push @filter, $f;
  }
  my $hideoldsolved;
  if ($query->param('text') ne undef) {
    my $f;
    $f->{col} = 'text';
    $f->{expr} = TTXCommon::decodeit($query->param('text'));
    $browsetxt = 2;
    push @filter, $f;
    $hideoldsolved = $cfg->set('hideoldsolved', '');
  }
  if ($query->param('cmd') eq 'mytickets') {
    my $f;
    $f->{col} = 'email';
    my $emailkey = $query->param('emailkey');
    $emailkey =~ s/\*//g;
    $f->{expr} = "^$emailkey\$";
    push @filter, $f;
  }
  if ($query->param('tid') ne undef) {
    my $f;
    $f->{col} = 'id';
    $f->{expr} = "^".$query->param('tid')."\$";
    $f->{expr} =~ s/\*/.*/g;
    push @filter, $f;
  }
  my @fields = ('name', 'lname', 'fltrsubj', 'email');
  for (my $i = 0; $i < $cfldcnt; ++$i) { push @fields, "c$i"; }
  foreach my $fld (@fields) {
    if ($query->param($fld) ne undef) {
      my $f;
      if ($fld eq 'fltrsubj') { $f->{col} = 'subject'; }
      else                    { $f->{col} = $fld; }
      my ($wc, $wc1);
      if ($fld =~ /^c\d+$/ && $cfg->get("$fld.type") eq 'list') {
        $wc = '*;';
        $wc1 = ';*';
      }
      $f->{expr} = "^$wc".TTXCommon::decodeit($query->param($fld))."$wc1\$";
      $f->{expr} =~ s/\*/.*/g;
      push @filter, $f;
    }
  }
  if ($query->param('qoffset') eq undef) {
    $query->param(-name => 'qoffset', -value => 0);
  }
  if ($query->param('qwindow') eq undef) {
    $query->param(-name => 'qwindow', -value => 20);
  }
  if ($query->param('qsort') eq undef) {
    $query->param(-name => 'qsort', -value => 'updated');
  }
  if ($query->param('qsortorder') eq undef) {
    $query->param(-name => 'qsortorder', -value => 'D');
  }
  if ($query->param('drfld') ne undef) {
    eval "use Time::Local";
    if ($@ eq undef) {
      $query->param('drfld') =~ /^(created|updated|solved)$/;
      if ($1 ne undef) {
        $globalDR{fld} = $1;
        $globalDR{stm} = Time::Local::timegm(0,0,0,$query->param('drsday'),$query->param('drsmon'),$query->param('drsyear')) - $cfg->get('timezone') * 60;
        $globalDR{etm} = Time::Local::timegm(59,59,23,$query->param('dreday'),$query->param('dremon'),$query->param('dreyear')) - $cfg->get('timezone') * 60;
      }
    }
  }
  return @filter;
}
# ===================================================================== fltrcode

sub fltrcode {
  my ($cfg, $query, $data, $nodr, $nostatus) = @_;
  $data->{GRPSELBOX} = "<select name=grp>\n";
  if ($query->param('grp') eq undef) {
    $data->{GRPSELBOX} .= "<option></option>\n";
  }
  my @grplist = sort {uc(TTXCommon::decodeit($cfg->get($a))) cmp uc(TTXCommon::decodeit($cfg->get($b)))}  grep(/^group\d+$/, $cfg->vars());
  foreach my $id (@grplist) {
    my $grpname = TTXCommon::decodeit($cfg->get($id));
    next if $grpname eq undef || $grpname eq '';
    $grpname =~ s/</&quot;/g;
    $data->{GRPSELBOX} .= "<option value=$id";
    $data->{GRPSELBOX} .= ' selected' if $query->param('grp') eq $id;
    $data->{GRPSELBOX} .= ">$grpname</option>\n";
  }
  if ($query->param('grp') ne undef) {
    $data->{GRPSELBOX} .= '<option value="">-- [%any%] --</option>'."\n";
  }
  $data->{GRPSELBOX} .= '<option value="-"';
  if ($query->param('grp') eq '-') {
    $data->{GRPSELBOX} .= " selected";
  }
  $data->{GRPSELBOX} .= '>-- [%none%] --</option>'."\n</select>\n";
  my @operlist = TTXUser::list();
  $data->{OPERSELBOX} = "<select name=oper>\n";
  if ($query->param('oper') eq undef) {
    $data->{OPERSELBOX} .= "<option></option>\n";
  }
  foreach my $oper (@operlist) {
    $data->{OPERSELBOX} .= "<option value=$oper";
    if ($query->param('oper') eq $oper) {
      $data->{OPERSELBOX} .= " selected";
    }
    $data->{OPERSELBOX} .= ">$oper</option>\n";
  }
  if ($query->param('oper') ne undef) {
    $data->{OPERSELBOX} .= '<option value="">-- [%any%] --</option>'."\n";
  }
  $data->{OPERSELBOX} .= "<option value=\"-\"";
  if ($query->param('oper') eq '-') {
    $data->{OPERSELBOX} .= " selected";
  }
  $data->{OPERSELBOX} .= '>-- [%none%] --</option>'."\n</select>\n";
  $data->{STATUSSELBOX} = "<select name=status>\n";
  if ($query->param('status') eq undef) {
    $data->{STATUSSELBOX} .= "<option></option>\n";
  }
  foreach my $status ('(OPN|PND)', 'PND', 'OPN', 'WFR', '(OPN|WFR)', 'CLS', '(PND|OPN|WFR)') {
    $data->{STATUSSELBOX} .= "<option value=$status";
    if ($query->param('status') eq $status) {
      $data->{STATUSSELBOX} .= " selected";
    }
    $data->{STATUSSELBOX} .= '>[%'.TTXCommon::status($status)."%]</option>\n";
  }
  if ($query->param('status') ne undef) {
    $data->{STATUSSELBOX} .= '<option value="">-- [%any%] --</option>'."\n";
  }
  $data->{STATUSSELBOX} .= "</select>\n";
  my $saveflds = $cfg->get('fltrcols');
  if ($nodr || $nostatus) {
    my @newflds;
    foreach my $fld (split(/\|/, $saveflds)) {
      next if $fld eq 'drange' && $nodr;
      next if $fld eq 'status' && $nostatus;
      push @newflds, $fld;
    }
    $cfg->set('fltrcols', join('|', @newflds));
  }
  if ($nodr) {
    $query->param(-name => 'drange', -value => '');
  }
  if ($nostatus) {
    $query->param(-name => 'status', -value => '');
  }
  TTXDesk::buildfilter($cfg,$query, $data);
  $cfg->set('fltrcols', $saveflds);
}
# ========================================================================= main

sub main {
  my ($cfg, $query, $data) = @_;
  return 'helpdesk' if !checkpoint($cfg);
  for (my $i = 0; $i < 12; ++$i) {
    $months[$i] = TTXDictionary::translate($months[$i]);
  }
  my $basewidth = $cfg->get('HTMLBASEWIDTH') || 700;
  my %rtitle = (
    overview => 'Overview',
    operperf => 'Operator Performance',
    aging360 => 'Ticket Aging',
    aging => 'Hot Tickets',
    slevel => 'Service Level'
  );
  $data->{PAGEHEADING} = '[%Reports%]';
  $data->{REPORTQUERY} =<<EOT;
<table cellpadding=5>
 <tr>
 <td align="right" class="lbl">[%Report%]
 </td>
  <td align=left>
    <select name=rtype size=1>
EOT
  if ($query->param('rtype') eq undef) {
    $data->{REPORTQUERY} .= '<option value="">-- [%Select Report%] --</option>';
  }
  foreach my $rtype ('overview', 'operperf', 'aging360', 'aging', 'slevel') {
    next if $rtype eq 'slevel' && !$cfg->get('opersla');
    $data->{REPORTQUERY} .= "<option value=$rtype";
    $data->{REPORTQUERY} .= ' selected' if $query->param('rtype') eq $rtype;
    $data->{REPORTQUERY} .= '>[%'.$rtitle{$rtype}.'%]</option>'."\n";
  }
  $data->{REPORTQUERY} .=<<EOT;
    </select>
  </td>
 </tr>
</table>

EOT
  if (!$query->param('do')) {
    fltrcode($cfg, $query, $data, 1, 0);
    return undef;
  }
  $query->param(-name => 'do', -value => '');
  my $rtype = TTXCommon::cleanit($query, 'rtype');
  if ($rtype eq undef) {
    fltrcode($cfg, $query, $data, 1, 0);
    $data->{REPORT} = "<center><b>[%No report selected%]</b><br><br></center>\n";
  } elsif ($rtype eq 'overview') {
    $cfg->set('_NOCOOKIE',1);
    overview($cfg, $query, $data);
  } elsif ($rtype eq 'operperf') {
    $cfg->set('_NOCOOKIE',1);
    operperf($cfg, $query, $data);
  } elsif ($rtype eq 'aging360') {
    $cfg->set('_NOCOOKIE',1);
    aging360($cfg, $query, $data);
  } elsif ($rtype eq 'aging') {
    $cfg->set('_NOCOOKIE',1);
    aging($cfg, $query, $data);
  } elsif ($rtype eq 'slevel') {
    $cfg->set('_NOCOOKIE',1);
    slevel($cfg, $query, $data);
  } else {
    $data->{REPORT} = '<center><b>[%Unknown report requested%]</b><br><br></center>'."\n";
  }
  $data->{REPORT} = "<tr><td align=left>\n".$data->{REPORT}."</td></tr>\n";
  return undef;
}
# ===================================================================== overview

sub overview {
  my ($cfg, $query, $data) = @_;
  my $tmcuts = cuttimes($cfg);
  my $img = $cfg->get('imgurl')."/dot.gif";
  fltrcode($cfg, $query, $data, 1, 0);
  my @fltr = mkfilter($cfg, $query);
  my %drange = (
    fld => 'created',
    stm => $tmcuts->{trail}->{months12}->{start},
    etm => $tmcuts->{today}->{stop}
  );
  $| = 1;
  my $tickets = TTXCommon::dbtik();
  my $tmp = $cfg->set('hideoldsolved', '');
  my $browser = $tickets->list(0, 999999, 'open', 'A', \@fltr, \%drange);
  $cfg->set('hideoldsolved', $tmp);
  $tmcuts->{total}->{cnt} = $browser->{total};
  my $m12stop = $tmcuts->{trail}->{months12}->{stop};
  my $m12idx = 0;
  my $m12idxstop = $tmcuts->{trail}->{months12}->{0}->{stop};
  my $m12m = $tmcuts->{trail}->{months12}->{0};
  my $w12stop = $tmcuts->{trail}->{weeks12}->{stop};
  my $w12start = $tmcuts->{trail}->{weeks12}->{start};
  my $w12idx = 0;
  my $w12idxstop = $tmcuts->{trail}->{weeks12}->{start} + 7*24*3600;
  my $w12bars = [];
  $w12bars->[0]->{stop} = $w12idxstop;
  my $d30stop = $tmcuts->{trail}->{days30}->{stop};
  my $d30start = $tmcuts->{trail}->{days30}->{start};
  my $d30idx = 0;
  my $d30idxstop = $tmcuts->{trail}->{days30}->{start} + 24*3600;
  my $d30bars = [];
  $d30bars->[0]->{stop} = $d30idxstop;
  foreach my $tid (@{$browser->{list}}) {
    my $t = $tickets->ticket($tid, 1);
    next if $t eq undef;
    my $tm = $t->{open};
    if ($tm < $m12stop) {
      while ($tm >= $m12idxstop) {
        ++$m12idx;
        $m12idxstop = $tmcuts->{trail}->{months12}->{$m12idx}->{stop};
        $m12m = $tmcuts->{trail}->{months12}->{$m12idx};
        print "\n"; #keep browser alive
      }
      ++$m12m->{cnt};
    } else {
      ++$tmcuts->{thismonth}->{cnt};
    }
    if ($tm >= $w12start) {
      while ($tm >= $w12idxstop && $w12idx < 12) {
        ++$w12idx;
        last if $w12idx > 11;
        $w12idxstop += 7*24*3600;
        $w12bars->[$w12idx]->{stop} = $w12idxstop;
      }
      if ($w12idx < 12) {
        ++$w12bars->[$w12idx]->{val};
      } else {
        ++$tmcuts->{thisweek}->{cnt};
      }
    }
    if ($tm >= $d30start) {
      while ($tm >= $d30idxstop && $d30idx < 30) {
        ++$d30idx;
        last if $d30idx > 29;
        $d30idxstop += 24*3600;
        $d30bars->[$d30idx]->{stop} = $d30idxstop;
      }
      if ($d30idx < 30) {
        ++$d30bars->[$d30idx]->{val};
      } else {
        ++$tmcuts->{today}->{cnt};
      }
    }
    #
    # Purge ticket out of memory
    # This is pretty safe if using SQL Edition (both MySQL and SQL Server).
    # If using Standard (palin text database) Edition the consequent
    # $tickets->save would destroy the database.
    #
    delete $tickets->{TICKETS}->{$tid};
  }
  while ($w12idx < 12) {
    ++$w12idx;
    last if $w12idx > 11;
    $w12idxstop += 7*24*3600;
    $w12bars->[$w12idx]->{stop} = $w12idxstop;
  }
  while ($d30idx < 30) {
    ++$d30idx;
    last if $d30idx > 29;
    $d30idxstop += 24*3600;
    $d30bars->[$d30idx]->{stop} = $d30idxstop;
  }
  my $bars = [];
  for (my $i=0; $i < 12; ++$i) {
    $bars->[$i]->{lbl} = $months[$tmcuts->{trail}->{months12}->{$i}->{idx}];
    $bars->[$i]->{val} = $tmcuts->{trail}->{months12}->{$i}->{cnt};
  }
  my $chart = TTXBarChart::vbar($bars, 25, 125, 'red');
  for (my $i=0; $i < 12; ++$i) {
    $w12bars->[$i]->{lbl} = $months[(gmtime($w12bars->[$i]->{stop} - 6*3600 + 60 * int($cfg->get('timezone'))))[4]];
  }
  for (my $i=11; $i > 0; --$i) {
    if ($w12bars->[$i]->{lbl} eq $w12bars->[$i-1]->{lbl}) {
      $w12bars->[$i]->{lbl} = '';
    }
  }
  my $chart1 = TTXBarChart::vbar($w12bars, 25, 125, 'blue');
  for (my $i=0; $i < 30; ++$i) {
    $d30bars->[$i]->{lbl} = (gmtime($d30bars->[$i]->{stop} - 3600+ 60 * int($cfg->get('timezone'))))[3];
  }
  my $chartd30 = TTXBarChart::vbar($d30bars, 22, 125, 'green', 0.5);
  my $newtoday = int $tmcuts->{today}->{cnt};
  my $newthisweek = int $tmcuts->{thisweek}->{cnt};
  my $newthismonth = int $tmcuts->{thismonth}->{cnt};
  $data->{REPORT} .=<<EOT;
<table cellpadding=0 cellspacing=0>
 <tr>
  <td align=left colspan=3>
  <b>[%New tickets%]</b>
  <table cellpadding=0 cellspacing=1>
   <tr>
    <td align=left><font color=gray><b>[%Today%]</b></font></td>
    <td align=right><font color=green><b>$newtoday</b></font></td>
   </tr>
   <tr>
    <td align=left><font color=gray><b>[%This Week%]</b></font></td>
    <td align=right><font color=blue><b>$newthisweek</b></font></td>
   </tr>
   <tr>
    <td align=left><font color=gray><b>[%This Month%]&nbsp;&nbsp;</b></font></td>
    <td align=right><font color=red><b>$newthismonth</b></font></td>
   </tr>
  </table>
<br />
  </td>
 </tr>
 <tr>
  <td align=center valign=top>
   <table cellpadding=10 style="border-style:solid;border-color:gray;border-width:1px;">
    <tr>
     <td align=center>
      <b>[%New tickets, last 12 months%]</b>
      <br><br>
      $chart
     </td>
    </tr>
   </table>
  </td>
  <td><img src="$img" width=17 height=1 /></td>
  <td align=center valign=top>
   <table cellpadding=10 style="border-style:solid;border-color:gray;border-width:1px;">
    <tr>
     <td align=center>
      <b>[%New tickets, last 12 weeks%]</b>
      <br><br>
      $chart1
     </td>
    </tr>
   </table>
  </td>
 </tr>
 <tr>
  <td colspan=3><img src="$img" width=1 height=10 /></td>
 </tr>
 <tr>
  <td align=center valign=top colspan=3>
   <table cellpadding=1 cellspacing=0 style="border-style:solid;border-color:gray;border-width:1px;">
    <tr>
     <td align=center>
      <br class=tiny>
      <b>[%New tickets, last 30 days%]</b>
      <br><br>
      $chartd30
      <br><br class=tiny>
     </td>
    </tr>
   </table>
  </td>
 </tr>
</table>
EOT
}
# ===================================================================== operperf

sub operperf {
  my ($cfg, $query, $data) = @_;
  my $tmcuts = cuttimes($cfg);
  my $img = $cfg->get('imgurl')."/dot.gif";
  fltrcode($cfg, $query, $data, 1, 1);
  my @fltr = mkfilter($cfg, $query);
  my %drange = (
    fld => 'updated',
    stm => $tmcuts->{trail}->{months12}->{start},
    etm => $tmcuts->{today}->{stop}
  );
  my $cond = {col => 'status', expr => '^(CLS|WFR)$'};
  push @fltr, $cond;
  $| = 1;
  my $tickets = TTXCommon::dbtik();
  my $tmp = $cfg->set('hideoldsolved', '');
  my $browser = $tickets->list(0, 999999, 'open', 'A', \@fltr, \%drange);
  $cfg->set('hideoldsolved', $tmp);
  $tmcuts->{total}->{cnt} = $browser->{total};
  my $opercnts = {};

  my $m12stop = $tmcuts->{trail}->{months12}->{stop};
  my $w12stop = $tmcuts->{trail}->{weeks12}->{stop};
  my $w12start = $tmcuts->{trail}->{weeks12}->{start};
  my $d30stop = $tmcuts->{trail}->{days30}->{stop};
  my $d30start = $tmcuts->{trail}->{days30}->{start};
  my $tcnt = 0;
  foreach my $tid (@{$browser->{list}}) {
    if (!$tcnt) {
      print "\n";
      $tcnt = 100;
    }
    --$tcnt;
    my $t = $tickets->ticket($tid, 1);
    next if $t eq undef;
    my $oper = $t->{oper};
    next if $oper eq undef;
    my $tm = $t->{updated};
    if ($tm < $m12stop) {
      ++$opercnts->{$oper}->{m12};
    } else {
      ++$opercnts->{$oper}->{thismonth};
    }
    if ($tm >= $w12start) {
      if ($tm < $w12stop) {
        ++$opercnts->{$oper}->{w12};
      } else {
        ++$opercnts->{$oper}->{thisweek};
      }
    }
    if ($tm >= $d30start) {
      if ($tm < $d30stop) {
        ++$opercnts->{$oper}->{d30};
      } else {
        ++$opercnts->{$oper}->{today};
      }
    }
    #
    # Purge ticket out of memory
    # This is pretty safe if using SQL Edition (both MySQL and SQL Server).
    # If using Standard (palin text database) Edition the consequent
    # $tickets->save would destroy the database.
    #
    delete $tickets->{TICKETS}->{$tid};
  }
  my $bars = [];
  my @operlist = TTXUser::list();
  @operlist = sort @operlist;
  my $i = 0;
  foreach my $oper (@operlist) {
    $bars->[$i]->{lbl} = $oper;
    $bars->[$i]->{val} = 0;
    if ($opercnts->{$oper} ne undef) {
      $bars->[$i]->{val} = $opercnts->{$oper}->{m12};
    }
    ++$i;
  }
  my $chart = TTXBarChart::hbar($bars, 18, 125, 'red', 0.8);
  $i = 0;
  foreach my $oper (@operlist) {
    $bars->[$i]->{lbl} = $oper;
    $bars->[$i]->{val} = 0;
    if ($opercnts->{$oper} ne undef) {
      $bars->[$i]->{val} = $opercnts->{$oper}->{w12};
    }
    ++$i;
  }
  my $chart1 = TTXBarChart::hbar($bars, 18, 125, 'blue', 0.8);
  $i = 0;
  foreach my $oper (@operlist) {
    $bars->[$i]->{lbl} = $oper;
    $bars->[$i]->{val} = 0;
    if ($opercnts->{$oper} ne undef) {
      $bars->[$i]->{val} = $opercnts->{$oper}->{d30};
    }
    ++$i;
  }
  my $chartd30 = TTXBarChart::hbar($bars, 18, 125, 'green', 0.8);
  $i = 0;
  foreach my $oper (@operlist) {
    $bars->[$i]->{lbl} = $oper;
    $bars->[$i]->{val} = 0;
    if ($opercnts->{$oper} ne undef) {
      $bars->[$i]->{val} = $opercnts->{$oper}->{today};
    }
    ++$i;
  }
  my $charttoday = TTXBarChart::hbar($bars, 18, 125, 'green', 0.8);
  $i = 0;
  foreach my $oper (@operlist) {
    $bars->[$i]->{lbl} = $oper;
    $bars->[$i]->{val} = 0;
    if ($opercnts->{$oper} ne undef) {
      $bars->[$i]->{val} = $opercnts->{$oper}->{thisweek};
    }
    ++$i;
  }
  my $chartthisweek = TTXBarChart::hbar($bars, 18, 125, 'blue', 0.8);
  $i = 0;
  foreach my $oper (@operlist) {
    $bars->[$i]->{lbl} = $oper;
    $bars->[$i]->{val} = 0;
    if ($opercnts->{$oper} ne undef) {
      $bars->[$i]->{val} = $opercnts->{$oper}->{thismonth};
    }
    ++$i;
  }
  my $chartthismonth = TTXBarChart::hbar($bars, 18, 125, 'red', 0.8);
  $data->{REPORT} .=<<EOT;
<br>
<table cellpadding=0 cellspacing=0>
 <tr>
  <td align=center valign=top>
   <table width="100%" cellpadding=10 style="border-style:solid;border-color:gray;border-width:1px;">
    <tr>
     <td align=left>
      <center><b>[%Answers, this month%]</b></center>
      <br>
      $chartthismonth
     </td>
    </tr>
   </table>
  </td>
  <td><img src="$img" width=17 height=1 /></td>
  <td align=center valign=top>
   <table width="100%" cellpadding=10 style="border-style:solid;border-color:gray;border-width:1px;">
    <tr>
     <td align=left>
      <center><b>[%Answers, this week%]</b></center>
      <br>
      $chartthisweek
     </td>
    </tr>
   </table>
  </td>
  <td><img src="$img" width=17 height=1 /></td>
  <td align=center valign=top>
   <table width="100%" cellpadding=10 style="border-style:solid;border-color:gray;border-width:1px;">
    <tr>
     <td align=left>
      <center><b>[%Answers, today%]</b></center>
      <br>
      $charttoday
     </td>
    </tr>
   </table>
  </td>
 </tr>
 <tr>
  <td colspan=5><img src="$img" width=1 height=10 /></td>
 </tr>
 <tr>
  <td align=center valign=top>
   <table width="100%" cellpadding=10 style="border-style:solid;border-color:gray;border-width:1px;">
    <tr>
     <td align=left>
      <center><b>[%Answers, last 12 months%]</b></center>
      <br>
      $chart
     </td>
    </tr>
   </table>
  </td>
  <td><img src="$img" width=17 height=1 /></td>
  <td align=center valign=top>
   <table width="100%" cellpadding=10 style="border-style:solid;border-color:gray;border-width:1px;">
    <tr>
     <td align=left>
      <center><b>[%Answers, last 12 weeks%]</b></center>
      <br>
      $chart1
     </td>
    </tr>
   </table>
  </td>
  <td><img src="$img" width=17 height=1 /></td>
  <td align=center valign=top>
   <table width="100%" cellpadding=10 style="border-style:solid;border-color:gray;border-width:1px;">
    <tr>
     <td align=left>
      <center><b>[%Answers, last 30 days%]</b></center>
      <br>
      $chartd30
     </td>
    </tr>
   </table>
  </td>
 </tr>
</table>
<br class=tiny />
EOT
}
# ======================================================================= slevel

sub slevel {
  my ($cfg, $query, $data) = @_;
  my $tmcuts = cuttimes($cfg);
  my $img = $cfg->get('imgurl')."/dot.gif";
  fltrcode($cfg, $query, $data, 1, 1);
  my @fltr = mkfilter($cfg, $query);
  my $cond = { 'col' => 'status', 'expr' => '^CLS$' };
  push @fltr, $cond;
  my %drange = (
    fld => 'solved',
    stm => $tmcuts->{trail}->{months12}->{11}->{start},
    etm => $tmcuts->{trail}->{months12}->{11}->{stop},
#    etm => $tmcuts->{lastweek}->{stop}
  );
  $| = 1;
  my $tickets = TTXCommon::dbtik();
  my $tmp = $cfg->set('hideoldsolved', '');
  my $browser = $tickets->list(0, 999999, 'open', 'A', \@fltr, \%drange);
  my $opercnts = {};
  my $tcnt = 0;
  foreach my $tid (@{$browser->{list}}) {
    if (!$tcnt) {
      print "\n";
      $tcnt = 100;
    }
    --$tcnt;
    my $t = $tickets->ticket($tid, 1);
    next if $t eq undef;
    my $oper = $t->{oper};
    next if $oper eq undef; # just to make sure
    if (!defined $opercnts->{$oper}) {
      my $u = TTXUser->new($oper);
      next if $u eq undef;
      $opercnts->{$oper}->{sla} = int($u->{sla}) * 3600;
    }
    ++$opercnts->{$oper}->{lm}->{total};
    ++$opercnts->{$oper}->{lm}->{jit} if $opercnts->{$oper}->{sla} > ($t->{closed} - $t->{open});
    #
    # Purge ticket out of memory
    # This is pretty safe if using SQL Edition (both MySQL and SQL Server).
    # If using Standard (palin text database) Edition the consequent
    # $tickets->save would destroy the database.
    #
    delete $tickets->{TICKETS}->{$tid};
  }
  %drange = (
    fld => 'solved',
    stm => $tmcuts->{lastweek}->{start},
    etm => $tmcuts->{lastweek}->{stop},
  );
  $browser = $tickets->list(0, 999999, 'open', 'A', \@fltr, \%drange);
  $cfg->set('hideoldsolved', $tmp);
  foreach my $tid (@{$browser->{list}}) {
    if (!$tcnt) {
      print "\n";
      $tcnt = 100;
    }
    --$tcnt;
    my $t = $tickets->ticket($tid, 1);
    next if $t eq undef;
    my $oper = $t->{oper};
    next if $oper eq undef; # just to make sure
    if (!defined $opercnts->{$oper}) {
      my $u = TTXUser->new($oper);
      next if $u eq undef;
      $opercnts->{$oper}->{sla} = int($u->{sla}) * 3600;
    }
    ++$opercnts->{$oper}->{lw}->{total};
    ++$opercnts->{$oper}->{lw}->{jit} if $opercnts->{$oper}->{sla} > ($t->{closed} - $t->{open});
    #
    # Purge ticket out of memory
    # This is pretty safe if using SQL Edition (both MySQL and SQL Server).
    # If using Standard (palin text database) Edition the consequent
    # $tickets->save would destroy the database.
    #
    delete $tickets->{TICKETS}->{$tid};
  }

  $data->{REPORT} .=<<EOT;
<center>
<b>[%Service Level Report%]</b><br>
<span class=sm>([%percentage of tickets solved within SLA time%])</span>
<br><br>
<table cellpadding=3 style="border-style:solid;border-color:gray;border-width:1px;">
  <tr>
    <td align=center>
      <b>[%Operator%]</b>
    </td>
    <td align=center>
      <b>[%Last Week%]</b>
    </td>
    <td align=center>
      <b>[%Last Month%]</b>
    </td>
  </tr>
EOT
  foreach my $oper (sort keys %{$opercnts}) {
    $data->{REPORT} .= "<tr>\n<td align=left>$oper</td><td align=right>".
      ($opercnts->{$oper}->{lw}->{total} ?
      int(100*$opercnts->{$oper}->{lw}->{jit}/$opercnts->{$oper}->{lw}->{total}).'%':'-' ).
      "</td>\n<td align=right>".
      ($opercnts->{$oper}->{lm}->{total} ?
      int(100*$opercnts->{$oper}->{lm}->{jit}/$opercnts->{$oper}->{lm}->{total}).'%':'-' ).
      "</td>\n</tr>\n";
  }
  $data->{REPORT} .=<<EOT;

</table>
</center>
<br class=tiny />
EOT
}
# ===================================================================== aging360

sub aging360 {
  my ($cfg, $query, $data) = @_;
  my @tmlst = (
    '0-24 [%hrs%]',
    '24-48 [%hrs%]',
    '2-7 [%days%]',
    '7-30 [%days%]',
    '30+ [%days%]'
  );
  my %tmcuts = (
    $tmlst[0] => 24*3600,
    $tmlst[1] => 48*3600,
    $tmlst[2] => 168*3600,
    $tmlst[3] => 720*3600,
    $tmlst[4] => 0
  );
  my $img = $cfg->get('imgurl')."/dot.gif";
  fltrcode($cfg, $query, $data, 1, 1);
  my @fltr = mkfilter($cfg, $query);
  my $cond = { 'col' => 'status', 'expr' => '^CLS$' };
  push @fltr, $cond;
  my $now = time();
  my %drange = (
    fld => 'created',
    stm => int ($now - 365*24*3600),
    etm => $now
  );
  $| = 1;
  my $tickets = TTXCommon::dbtik();
  my $tmp = $cfg->set('hideoldsolved', '');
  my $browser = $tickets->list(0, 999999, 'open', 'A', \@fltr, \%drange);
  $cfg->set('hideoldsolved', $tmp);
  my @bardata;
  my $heartbeat = 0;
  foreach my $tid (@{$browser->{list}}) {
    my $t = $tickets->ticket($tid, 1);
    next if $t eq undef;
    my $tm = $t->{closed} - $t->{open};
    my $i = 0;
    foreach my $cut (@tmlst) {
      last if $tm < $tmcuts{$cut} || !$tmcuts{$cut};
      ++$i;
    }
    ++$bardata[$i]->{val};
    ++$heartbeat;
    if ($heartbeat > 100) {
      print "\n"; #keep browser alive
      $heartbeat = 0;
    }
    #
    # Purge ticket out of memory
    # This is pretty safe if using SQL Edition (both MySQL and SQL Server).
    # If using Standard (palin text database) Edition the consequent
    # $tickets->save would destroy the database.
    #
    delete $tickets->{TICKETS}->{$tid};
  }
  my $i = 0;
  foreach my $cut (@tmlst) {
    $bardata[$i]->{lbl} = $cut;
    ++$i;
  }
  my $chart = TTXBarChart::hbar(\@bardata, 18, 125, 'red', 0.8, 1);
  $data->{REPORT} .=<<EOT;
<table cellpadding=0 cellspacing=0 width="100%">
 <tr>
  <td align=center>
  <b>[%Breakdown of time to close a ticket%]</b><br />
  <span class=sm>([%tickets submitted during last 365 days%])</span>
  <br /><br />
  $chart
  <br /><br />
  </td>
 </tr>
</table>
EOT
}
# ======================================================================== aging

sub aging {
  my ($cfg, $query, $data) = @_;
  my @tmlst = (
    '0-24 [%hrs%]',
    '24-48 [%hrs%]',
    '2-7 [%days%]',
    '7-30 [%days%]',
    '30+ [%days%]'
  );
  my %tmcuts = (
    $tmlst[0] => 24*3600,
    $tmlst[1] => 48*3600,
    $tmlst[2] => 168*3600,
    $tmlst[3] => 720*3600,
    $tmlst[4] => 0
  );
  my $img = $cfg->get('imgurl')."/dot.gif";
  fltrcode($cfg, $query, $data, 1, 1);
  my @fltr = mkfilter($cfg, $query);
  my $cond = { 'col' => 'status', 'expr' => '^(PND|OPN)$' };
  push @fltr, $cond;
  my $now = time();
  my %drange = (
    fld => 'created',
    stm => int ($now - 365*24*3600),
    etm => $now
  );
  $| = 1;
  my $tickets = TTXCommon::dbtik();
  my $tmp = $cfg->set('hideoldsolved', '');
  my $browser = $tickets->list(0, 999999, 'open', 'A', \@fltr, \%drange);
  $cfg->set('hideoldsolved', $tmp);
  my @bardata;
  my $heartbeat = 0;
  foreach my $tid (@{$browser->{list}}) {
    my $t = $tickets->ticket($tid, 1);
    next if $t eq undef;
    my $tm = $now - $t->{open};
    my $i = 0;
    foreach my $cut (@tmlst) {
      last if $tm < $tmcuts{$cut} || !$tmcuts{$cut};
      ++$i;
    }
    ++$bardata[$i]->{val};
    ++$heartbeat;
    if ($heartbeat > 100) {
      print "\n"; #keep browser alive
      $heartbeat = 0;
    }
    #
    # Purge ticket out of memory
    # This is pretty safe if using SQL Edition (both MySQL and SQL Server).
    # If using Standard (palin text database) Edition the consequent
    # $tickets->save would destroy the database.
    #
    delete $tickets->{TICKETS}->{$tid};
  }
  my $i = 0;
  foreach my $cut (@tmlst) {
    $bardata[$i]->{lbl} = $cut;
    ++$i;
  }
  my $chart = TTXBarChart::hbar(\@bardata, 18, 125, 'red', 0.8, 1);
  $data->{REPORT} .=<<EOT;
<table cellpadding=0 cellspacing=0 width="100%">
 <tr>
  <td align=center>
  <b>[%Hot Tickets%]</b><br />
  <span class=sm>([%tickets in open or pending state%])</span>
  <br /><br />
  $chart
  <br /><br />
  </td>
 </tr>
</table>
EOT
}
# ===================================================================== cuttimes

sub cuttimes {
  my $cfg = $_[0];
  my $cuts;
  my $now = time() + 60 * int($cfg->get('timezone'));
  $cuts->{total}->{start} = 0;
  $cuts->{total}->{stop} = $now;
  $cuts->{yesterday}->{stop} = $now - ($now % (3600 * 24));
  $cuts->{yesterday}->{start} = $cuts->{yesterday}->{stop} - (3600 * 24);
  my ($sec,$min,$hour,$mday,$mon,$year, $wday) = gmtime($now);
  --$wday;
  $wday = 6 if $wday < 0;  # Sunday is last week day
#  $wdaytoday = $wday;
  $cuts->{lastweek}->{stop} = $cuts->{yesterday}->{stop} - $wday * (3600 * 24);
  $cuts->{lastweek}->{start} = $cuts->{lastweek}->{stop} - (7 * 3600 * 24);
  $cuts->{thisweek}->{start} = $cuts->{lastweek}->{stop}; # current week
  $cuts->{thisweek}->{stop} = $now;
  $cuts->{lastmonth}->{stop} = $cuts->{yesterday}->{stop} - ($mday - 1) * (3600 * 24);
  $cuts->{thismonth}->{start} = $cuts->{lastmonth}->{stop};
  $cuts->{thismonth}->{stop} = $now;
  $cuts->{today}->{start} = $cuts->{yesterday}->{stop};
  $cuts->{today}->{stop} = $cuts->{today}->{start} + (3600 * 24);
  my ($sec1,$min1,$hour1,$mday1,$mon1,$year1, $wday1) = gmtime($cuts->{month}->{stop} - 3600);
  $cuts->{lastmonth}->{start} = $cuts->{lastmonth}->{stop} - $mday1 * (3600 * 24);
  foreach my $col ('today', 'yesterday', 'lastweek', 'lastmonth', 'thismonth', 'thisweek') {
    $cuts->{$col}->{start} -= 60 * int($cfg->get('timezone'));
    $cuts->{$col}->{stop} -= 60 * int($cfg->get('timezone'));
  }
  $cuts->{Mon}->{start} = $cuts->{lastweek}->{stop};
  $cuts->{Mon}->{stop} = $cuts->{Mon}->{start}  + (3600 * 24);
  my $priorday = 'Mon';
  foreach my $day ('Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun') {
    $cuts->{$day}->{stop} = $cuts->{$priorday}->{stop} + (3600 * 24);
    $cuts->{$day}->{start} = $cuts->{$day}->{stop} - (3600 * 24);
    $priorday = $day;
  }
  #
  # Trailings
  #
  # 30 Days
  #
  $cuts->{trail}->{days30}->{stop} = $cuts->{yesterday}->{stop};
  $cuts->{trail}->{days30}->{start} = $cuts->{trail}->{days30}->{stop} - 30 * 24 * 3600;
  #
  # 12 weeks
  #
  $cuts->{trail}->{weeks12}->{stop} = $cuts->{lastweek}->{stop};
  $cuts->{trail}->{weeks12}->{start} = $cuts->{trail}->{weeks12}->{stop} - 12 * 7 * 24 * 3600;
  #
  # 12 months
  #
  $cuts->{trail}->{months12}->{stop} = $cuts->{lastmonth}->{stop};
  for (my $i=11; $i >= 0; --$i) {
    if ($i == 11) {
      $cuts->{trail}->{months12}->{11}->{stop} = $cuts->{trail}->{months12}->{stop};
    } else {
      $cuts->{trail}->{months12}->{$i}->{stop} = $cuts->{trail}->{months12}->{($i+1)}->{start};
    }
    my ($md,$mn) = (gmtime($cuts->{trail}->{months12}->{$i}->{stop} - 3600 + 60 * int($cfg->get('timezone'))))[3,4];
    $cuts->{trail}->{months12}->{$i}->{start} = $cuts->{trail}->{months12}->{$i}->{stop} - $md * 3600 * 24;
    $cuts->{trail}->{months12}->{$i}->{idx} = $mn;
  }
  $cuts->{trail}->{months12}->{start} = $cuts->{trail}->{months12}->{0}->{start};
  return $cuts;
}

1;
#
