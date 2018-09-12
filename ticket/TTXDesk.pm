package TTXDesk;
#
# This module is a part of Trouble Ticket Express package
# http://www.troubleticketexpress.com
#
# COPYRIGHT: 2002-2007, United Web Coders
# http://www.unitedwebcoders.com
#
# $Revision: 451 $
# $Date: 2007-11-05 07:12:39 +0300 (Mon, 05 Nov 2007) $
#

$TTXDesk::VERSION='2.24';
BEGIN {
  $TTXDesk::REVISION = '$Revision: 451 $';
  if ($TTXDesk::REVISION =~ /(\d+)/) {
    $TTXDesk::REVISION = $1;
  }
};
use strict;
use TTXCommon;
use TTXUser;
use TTXTickets;
require TTXMarkup;

my @brcols = ('id', 'name', 'email', 'subject', 'oper', 'status', 'open', 'updated');
my %c2t = (
  id => 'id',
  name => 'name',
  email => 'email',
  subject => 'subject',
  oper => 'operator',
  status => 'status',
  updated => 'updated',
  open => 'created',
  grp => 'group'
);
my %c2T = (
  id => 'Ticket #',
  tid => 'Ticket #',
  name => 'Name',
  email => 'Email',
  fltrsubj => 'Subject',
  oper => 'Operator',
  status => 'Status',
  lname => 'Name',
  grp => 'Group'

);

my @rclr = ('#F0F0E1', '#E8E8CF');
my @rcls = ('orow', 'erow');
# =================================================================== invenabled

my $_invenabled = undef;

sub invenabled {
  if ($_invenabled eq undef) {
    eval 'use TTXInvMod';
    if ($@ eq undef) {
      $_invenabled = 1;
    } else {
      $_invenabled = 0;
    }
  }
  return $_invenabled;
}
# ===================================================================== subjlist

sub subjlist {
  my ($cfg, $query) = @_;
  my @options;
  my $val = $query->param('fltrsubj');
  if (open(SLIST, $cfg->get('basedir').'/subjectlist.txt')) {
    @options = <SLIST>;
    close SLIST;
    chomp @options;
  }
  if ((int @options) < 1) {
    $val =~ s/&/&amp;/g;
    $val =~ s/</&lt/g;
    $val =~ s/"/&quot;/g;
    return "<input type=text name=fltrsubj size=20 value=\"$val\"";
  }
  my $buff .= "<select name=fltrsubj>\n";
  if ($val eq undef) {
    $buff .= "<option value=\"\"></option>\n";
  }
  foreach my $option (@options) {
    next if $option eq undef;
    my $selected = " selected" if $option eq $val;
    my $v = $option;
    $v =~ s/"/&quot;/g;
    my $h = $option;
    $h =~ s/</&lt/g;
    my $dots = '...';
    $h =~ /^(.{1,30})(.*)/;
    $h = $1;
    $h .= '...' if $2 ne undef;
    $buff .= "<option value=\"$v\"$selected>$h</option>\n";
  }
  if ($val ne undef) {
    $buff .= '<option value="">-- [%any%] --</option>'."\n";
  }
  $buff .= "</select>\n";
  return $buff;
}
# ================================================================== buildfilter

sub buildfilter {
  my ($cfg, $query, $data) = @_;
  my $width = $cfg->get('HTMLBASEWIDTH') || 700;
  my $buff = "<table cellspacing=0 cellpadding=0 width=$width>\n";
  if ($cfg->get('fltrcols') eq undef) {
    $cfg->set('fltrcols', 'text|subject|oper|status|id');
    $cfg->save();
  }
  my $cfldcnt = TTXCommon::cfldcnt();
  foreach my $var ($cfg->vars()) {
    next if $var !~ /^x/;
    my $pos = $cfg->get($var);
    next if $pos < 0 || $pos >= $cfldcnt;
    $var =~ s/^x//;
    $var =~ /^(.{1,15})(.*)/;
    $var = $1;
    $c2T{"c$pos"} = $var;
  }
  my $colcnt = 0;
  my @fltrcols = split(/\|/, $cfg->get('fltrcols'));
  if (grep(/^subject$/, @fltrcols)) {
    @fltrcols = grep(!/^subject$/, @fltrcols);
    @fltrcols = ('subject', @fltrcols);
  }
  if (grep(/^text$/, @fltrcols)) {
    @fltrcols = grep(!/^text$/, @fltrcols);
    @fltrcols = ('text', @fltrcols);
  }
  if (grep(/^drange$/, @fltrcols)) {
    @fltrcols = grep(!/^drange$/, @fltrcols);
    @fltrcols = (@fltrcols, 'drange');
  }
  foreach my $fld (@fltrcols) {
    $fld = 'fltrsubj' if $fld eq 'subject';
    $fld = 'tid' if $fld eq 'id';
    if ($colcnt > 2) { $buff .= "</tr>\n"; $colcnt = 0; }
    if (!$colcnt) { $buff .= "<tr>\n"; }
    ++$colcnt;
    if ($fld eq 'text') {
      $buff .= '<td align=right class=lbl>[%Text%]</td>'."\n<td colspan=3 align=left>&nbsp;";
      ++$colcnt; # text is always first element
    } elsif ($fld eq 'drange') {
      if ($colcnt > 1) {
        while ($colcnt <= 2) {
          $buff .= "<td>&nbsp;</td><td>&nbsp;</td>\n";
          ++$colcnt;
        }
        $buff .= "</tr>\n<tr>\n";
      }
      $buff .= '<td align=right class=lbl>[%Date Range%]</td>'."\n".
               "<td colspan=5 align=left>\n&nbsp;<select name=drfld>\n<option></option>\n";
      foreach my $drfld ('created', 'updated', 'solved') {
        $buff .= '<option';
        $buff .= ' selected' if $query->param('drfld') eq $drfld;
        $buff .= ">$drfld</option>\n";
      }
      if ($query->param('drfld') eq undef) {
        $query->param(-name => 'drsyear', -value => '');
        $query->param(-name => 'dreyear', -value => '');
      } else {
        if ($query->param('drsyear') eq undef) {
          my $tz = $cfg->get('timezone') * 60;
          my ($mday,$mon,$year) = (gmtime(time() + $tz - 24*3600*30))[3,4,5];
          $query->param(-name => 'drsyear', -value => $year);
          $query->param(-name => 'drsmon', -value => $mon);
          $query->param(-name => 'drsday', -value => $mday);
        }
        if ($query->param('dreyear') eq undef) {
          my $tz = $cfg->get('timezone') * 60;
          my ($mday,$mon,$year) = (gmtime(time() + $tz))[3,4,5];
          $query->param(-name => 'dreyear', -value => $year);
          $query->param(-name => 'dremon', -value => $mon);
          $query->param(-name => 'dreday', -value => $mday);
        }
      }
      TTXCommon::checkdrange($query, 'drs', 'dre');
      $buff .= "</select>\n&nbsp;&nbsp;".TTXCommon::pickdate($query, 'drs', 1).
               "&nbsp;-&nbsp;".TTXCommon::pickdate($query, 'dre', 0)."</td>\n";
    } elsif ($fld eq 'grp') {
      my $grplbl = TTXCommon::decodeit($cfg->get('grpsellbl')) || '[%Group%]';
      $buff .= "<td align=right class=lbl>$grplbl</td>\n<td align=left>&nbsp;";
    } else {
      $buff .= '<td align=right class=lbl>[%'.$c2T{$fld}.'%]</td>'."\n".'<td align=left>&nbsp;';
    }
    if ($fld eq 'oper') {
      $buff .= $data->{OPERSELBOX};
    } elsif ($fld eq 'item') {
      if (invenabled()) {
        $buff .= TTXInvMod::selbox($cfg, $query, 0);
      } else {
        $buff .= '&nbsp;';
      }
    } elsif ($fld eq 'status') {
      $buff .= $data->{STATUSSELBOX};
    } elsif ($fld eq 'grp') {
      $buff .= $data->{GRPSELBOX};
    } elsif ($fld ne 'drange'){
      my $val = TTXCommon::decodeit($query->param($fld));
      $fld =~ /^c(\d+)$/;
      if ($1 ne undef && $cfg->get("dropdown$1") ne undef) {
        my @options = split(/;/, TTXCommon::decodeit($cfg->get("dropdown$1")));
        $buff .= "<select name=$fld>\n";
        if ($val eq undef) {
          $buff .= "<option value=\"\"></option>\n";
        }
        foreach my $option (@options) {
          my $selected = " selected" if $option eq $val;
          my $v = $option;
          $v =~ s/"/&quot;/g;
          my $h = $option;
          $h =~ s/</&lt/g;
          my $dots = '...';
          $h =~ /^(.{1,15})(.*)/;
          $h = $1;
          $h .= '...' if $2 ne undef;

          $buff .= "<option value=\"$v\"$selected>$h</option>\n";
        }
        if ($val ne undef) {
          $buff .= '<option value="">-- [%any%] --</option>'."\n";
        }
        $buff .= "</select>\n";
      } elsif ($fld eq 'fltrsubj' && $cfg->get('usesubjectlist') ne undef) {
        $buff .= subjlist($cfg, $query);
      } else {
        $val =~ s/&/&amp;/g;
        $val =~ s/</&lt/g;
        $val =~ s/"/&quot;/g;
        $buff .= "<input type=text name=$fld size=".($fld eq 'text' ? 48:20)." value=\"$val\">";
      }
    }
    $buff .= "</td>\n";
  }
  if ($colcnt) {
    while ($colcnt < 3) { $buff .= "<td>&nbsp;</td>\n"; ++$colcnt; }
    $buff .= "</tr>\n";
  }
  $buff .= "</table>";
  $data->{TICKETFILTER} = $buff;
}
# ===================================================================== helpdesk

sub helpdesk {
  my ($cfg, $query, $data) = @_;
  my $browsetxt = 0;
  $data->{PAGEHEADING} = '[%Help Desk%]';
  TTXCommon::tickedvars($cfg, $data);
  $c2T{item} = $cfg->get('inventory.label') || 'Item';
  $c2t{item} = lc $cfg->get('inventory.label') || 'item';
  my $cfldcnt = TTXCommon::cfldcnt();
  if ($query->param('tk') ne undef) {
    $query->param(-name => 'key', -value => $query->param('tk'));
    return 'ticket';
  }
  my $user = $cfg->get('_USER');
  my $session;
  my $readonly;
  if ($user ne undef) {
    $session = $user->get('session');
    $readonly = $user->get('ro') ? 1:0;
  }
  if (!$query->param('do')) {
    $session->qexpand($query, 'helpdesk') if $session ne undef;
    if ($query->param('status') eq undef) {
      $query->param(-name => 'status', -value => $cfg->get('defaultstatus'));
    }
  } elsif ($session ne undef) {
    my @fldlist = ('text', 'oper', 'tid', 'status', 'lname', 'name', 'email', 'fltrsubj', 'grp',
                    'qwindow', 'qsort', 'qsortorder',
                    'drfld', 'drsday', 'drsmon', 'drsyear', 'dreday', 'dremon', 'dreyear', 'item');
    for (my $i = 0; $i < $cfldcnt; ++$i) {
      push @fldlist, "c$i";
    }
    foreach my $id (@fldlist) {
      if ($query->param($id) ne $session->get("helpdesk.$id")) {
        $query->param(-name => 'qoffset', -value => '');
        last;
      }
    }
  }
  if ($query->param('reset') ne undef) {
    foreach my $fld ('text', 'oper', 'tid', 'status', 'lname', 'name', 'email', 'fltrsubj', 'grp', 'qoffset', 'drfld', 'item') {
      $query->param(-name => $fld, -value => '');
    }
    for (my $i = 0; $i < $cfldcnt; ++$i) {
      $query->param(-name => "c$i", -value => '');
    }
    foreach my $pref ('drs', 'dre') {
      foreach my $fld ('day', 'mon', 'year') {
        $query->param(-name => $pref.$fld, -value => '');
      }
    }
  }
  if ($cfg->get('brcols') eq undef) {
    $cfg->set('brcols', 'id|name|email|subject|oper|status|open|updated');
    $cfg->save();
  }
  if ($cfg->get('brcols') ne undef) {
    @brcols = split(/\|/, $cfg->get('brcols'));
    my @cfgvars = $cfg->vars();
    foreach my $var (@cfgvars) {
      next if $var !~ /^x/;
      my $cidx = int ($cfg->get($var));
      next if ($cidx < 0 || $cidx >= $cfldcnt);
      $var =~ s/^x//;
      $c2t{"c$cidx"} = $var;
    }
  }
  if ($query->param('abstract')) {
    $browsetxt = 1;
    $data->{CHECKABSTRACT} = ' checked';
  }
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
  my @fltlist = sort grep(/^filter\.group/, $cfg->vars());
  foreach my $id (@fltlist) {
    my ($fltname, $grplist) = split(/\|/, $cfg->get($id));
    next if $fltname eq undef || $fltname eq '';
    $fltname =~ s/</&quot;/g;
    $grplist =~ s/\s//g;
    $grplist =~ s/,/|/g;
    $data->{GRPSELBOX} .= "<option value=$grplist";
    $data->{GRPSELBOX} .= ' selected' if $query->param('grp') eq $grplist;
    $data->{GRPSELBOX} .= ">$fltname</option>\n";
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
  foreach my $oper (sort @operlist) {
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
  buildfilter($cfg, $query, $data);
  my $tickets = TTXCommon::dbtik();
  if ($tickets eq undef || $tickets->error() ne undef) {
    $data->{ERROR_MESSAGE} = $tickets->errortext();
    return undef;
  }
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
      $f->{expr} = "^".TTXCommon::decodeit($query->param('grp'))."\$";
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
    if (!$@) {
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
    my $val = TTXCommon::decodeit($query->param($fld));
    if ($val ne undef) {
      my $f;
      if ($fld eq 'fltrsubj') { $f->{col} = 'subject'; }
      else                    { $f->{col} = $fld; }
      my ($wc, $wc1);
      if ($fld =~ /^c\d+$/ && $cfg->get("$fld.type") eq 'list') {
        $wc = '*;';
        $wc1 = ';*';
      }
      $f->{expr} = "^$wc".$val."$wc1\$";
      $f->{expr} =~ s/\*/.*/g;
      push @filter, $f;
    }
  }
  if ($query->param('qoffset') eq undef) {
    $query->param(-name => 'qoffset', -value => 0);
  }
  if ($query->param('qwindow') eq undef) {
    my $w = 20;
    my $n = int($cfg->get('qwindow.default'));
    if ($n > 0 && $w != $n) {
      $w = $n;
    }
    if ($user ne undef && $cfg->get('usegrpsel')) {
      eval "use TTXGroups";
      if ($@ eq undef) {
        my $override = 1;
        my @glist = TTXGroups::grouplist($cfg, $user->get('login'));
        foreach my $g (@glist) {
          $n = int($cfg->get("qwindow.$g"));
          if ($override && $n > 0) {
            $w = 0;
            $override = 0;
          }
          $w = $n if $n > $w;
        }
      }
    }
    $query->param(-name => 'qwindow', -value => $w);
  }
  if ($query->param('qsort') eq undef) {
    $query->param(-name => 'qsort', -value => 'updated');
  }
  if ($query->param('qsortorder') eq undef) {
    $query->param(-name => 'qsortorder', -value => 'D');
  }
  my %drange;
  if ($query->param('drfld') ne undef) {
    eval "use Time::Local";
    if ($@ eq undef) {
      $query->param('drfld') =~ /^(created|updated|solved)$/;
      if ($1 ne undef) {
        $drange{fld} = $1;
        $drange{stm} = Time::Local::timegm(0,0,0,$query->param('drsday'),$query->param('drsmon'),$query->param('drsyear')) - $cfg->get('timezone') * 60;
        $drange{etm} = Time::Local::timegm(59,59,23,$query->param('dreday'),$query->param('dremon'),$query->param('dreyear')) - $cfg->get('timezone') * 60;
      }
    }
  }
  my $browser = $tickets->list($query->param('qoffset'), $query->param('qwindow'),
                               $query->param('qsort'), $query->param('qsortorder'), \@filter, \%drange);
  if ($query->param('text') ne undef) {
    $cfg->set('hideoldsolved', $hideoldsolved);
  }
  my $list = $browser->{list};
  if (@{$list} < 1) {
    $data->{TICKETLIST} = '<tr><td align=center><b>[%There are no tickets matching your query%]</b></td></tr>';
  } else {
    my $ccnt = scalar @brcols;
    ++$ccnt if $query->param('cmd') ne 'mytickets' && !$readonly;
    my $lspan = int($ccnt / 2);
    my $rspan = $ccnt - $lspan;
    if ($query->param('cmd') ne 'mytickets') {
      $data->{TICKETLIST} .=  "<form method=post name=\"ticketlist\" action=\"$ENV{SCRIPT_NAME}\">\n".
                              "<input type=hidden name=cmd value=groupcommand>\n".
                              "<input type=hidden name=style value=".$query->param('style').">\n".
                              "<input type=hidden name=sid value=".$query->param('sid').">\n";
    }
    $data->{TICKETLIST} .=  "<tr><td colspan=$lspan align=left><b><span class=sm>".'[%Tickets%] '.
                            ($browser->{first} + 1)." - ".$browser->{last}.' [%out of%] '.
                            $browser->{total}."</span></b></td>".
                            "<td align=right colspan=$rspan><span class=sm><b>";
    if ($browser->{first} > 0) {
      $data->{TICKETLIST} .= "<a href=# onClick=\"return scroll('0','".$query->param('qwindow')."')".'">[%first%]</a> ';
    } else {
      $data->{TICKETLIST} .= '<font color="#BBBBBB">[%first%]</font> ';
    }
    if ($browser->{first} > 0) {
      my $back = $browser->{first} - $query->param('qwindow');
      $back = 0 if $back < 0;
      $data->{TICKETLIST} .= "<a href=# onClick=\"return scroll('$back','".$query->param('qwindow')."')\">".'[%prev%]</a> ';
    } else {
      $data->{TICKETLIST} .= '<font color="#BBBBBB">[%prev%]</font> ';
    }
    if ($browser->{last} < $browser->{total}) {
      my $frw = $browser->{first} + $query->param('qwindow');
      $data->{TICKETLIST} .= "<a href=# onClick=\"return scroll('$frw','".$query->param('qwindow')."')\">".'[%next%]</a> ';
    } else {
      $data->{TICKETLIST} .= '<font color="#BBBBBB">[%next%]</font> ';
    }
    if ($browser->{last} < $browser->{total}) {
      my $frw = $browser->{total} - $query->param('qwindow');
      $data->{TICKETLIST} .= "<a href=# onClick=\"return scroll('$frw','".$query->param('qwindow')."')\">".'[%last%]</a> ';
    } else {
      $data->{TICKETLIST} .= '<font color="#BBBBBB">[%last%]</font> ';
    }
    $data->{TICKETLIST} .=  "</b></span></td></tr>\n";
    $data->{TICKETLIST} .= "<tr><td colspan=$ccnt><img src=\"".TTXData::get('CONFIG')->get('imgurl')."/dot.gif\" height=2></td></tr>";
    $data->{TICKETLIST} .= "<tr>\n";
    if ($query->param('cmd') ne 'mytickets' && !$readonly) {
      $data->{TICKETLIST} .= '<td class=trow align=center><input type="checkbox" name="cb" onclick="SelectDeselectAll(this.checked);"></td>'."\n";
    }
    if ($cfg->get('grpsellbl') ne undef) {
      $c2t{grp} = lc TTXCommon::decodeit($cfg->get('grpsellbl'));
    }
    foreach my $col (@brcols) {
      my $order = 'A';
      if ($query->param('qsort') eq $col) {
        if ($query->param('qsortorder') eq 'A') {
          $order = 'D';
        }
      } else {
        $order = $query->param('qsortorder');
      }
      $data->{TICKETLIST} .= "<td class=trow align=center><a href=# onClick=\"return setsort('$col', '$order')\">".'[%'.$c2t{$col}.'%]'."</a></td>\n";
    }
    $data->{TICKETLIST} .= "</tr>\n";
    my $i = 0;
    my $j = 0;
    my %colormatrix = (PND => 'green', WFR => 'blue', OPN => 'orange', CLS => 'red', LATE => 'red');
    my $now = time();
    foreach my $id (@{$list}) {
      my ($fcopen, $fcclose);
      my $clr = $rclr[$i];
      my $cl = $rcls[$i];
      ++$i;
      ++$j;
      $i = 0 if $i > 1;
      my $t = $tickets->ticket($id);
      if ($cfg->get('colortickets')) {
        $fcopen = "<font color=".$colormatrix{$t->{status}}.">";
        $fcclose = "</font>";
      }
      if ($cfg->get('claimtime') &&
           (($t->{status} eq 'PND' && ($now - $t->{open} > 24*60*60) && !$cfg->get('ignorepending') ) ||
             $t->{status} ne 'PND' && $t->{'c'.$cfg->get('claimtime')} > 23)) {
        $fcopen = "<font color=".$colormatrix{LATE}.">";
        $fcclose = "</font>";
      }
      $data->{TICKETLIST} .= "<tr bgcolor=\"$clr\" onmouseover=\"rowhl($j, 1);\" onmouseout=\"rowhl($j, 0);\" id=\"tr$j\">\n";
      if ($query->param('cmd') ne 'mytickets' && !$readonly) {
        $data->{TICKETLIST} .= "<td align=center valign=middle class=$cl><input type=checkbox name=tid value=".$t->{id}."></td>\n";
      }
      foreach my $col (@brcols) {
        my $val = $t->{$col};
        my $align = 'right';
        if (grep(/^$col$/, ('open', 'updated', 'closed'))) {
          $val = "<nobr>$fcopen".TTXCommon::tmtxt($val)."$fcclose</nobr>";
        } elsif ($col eq 'status') {
          $val = $fcopen.'[%'.TTXCommon::status($val).'%]'.$fcclose;
        } elsif ($col eq 'id') {
          if (!$readonly) {
            $val = "<a href=# onClick=\"return ticked('$val')\">$fcopen$val$fcclose</a>";
          }
        } elsif ($col eq 'grp') {
          $val = $fcopen.(TTXCommon::decodeit($cfg->get($val)) || '-').$fcclose;
        } elsif ($col eq 'subject') {
          $align = 'left';
          my $dots = '...';
          $val =~ s/\b([^\s]{15,15})([^\s])*/$1.$dots/ge;
          $val =~ /^(.{1,30})(.*)/;
          $val = $1;
          $val .= '...' if $2 ne undef;
          $val =~ s/</&lt;/g;
          my ($emailkey, $tkey);
          if ($query->param('cmd') eq 'mytickets') {
            $emailkey = "&emailkey=".$query->param('emailkey');
            $tkey = $t->{key};
          } else {
            $tkey = $t->{id};
          }
          $val = "<a href=\"$ENV{SCRIPT_NAME}?cmd=ticket&sid=".$query->param('sid')."&key=$tkey".$emailkey.
                 "&style=".$query->param('style').
                 "\">$fcopen$val$fcclose</a>";
        } elsif ($col eq 'name') {
          $align = 'left';
          $val =~ s/</&lt;/g;
          $val = $fcopen.$val.$fcclose;
        } elsif ($col eq 'item') {
          if (invenabled()) {
            my $items = TTXInvMod::getitems($val);
            $val = undef;
            foreach my $item (@{$items}) {
              my $lbl = $item->{title};
              my $dots = '...';
              $lbl =~ s/\b([^\s]{15,15})([^\s])*/$1.$dots/ge;
              $lbl =~ s/</&lt;/g;
              $val .= ', ' if $val ne undef;
              $val .= "<a href=# onClick=\"return showitem('".$item->{id}."')\">$lbl</a>";
            }
            if ($val eq undef) {
              $val = '-';
            }
            $val = $fcopen.$val.$fcclose;
          } else {
            $val = $fcopen."???".$fcclose;
          }
        } elsif ($col eq 'email') {
          my $dots = '...';
          my $adr = $val;
          $val =~ s/\b([^\s]{15,15})([^\s])*/$1.$dots/ge;
          $val = "<a href=\"mailto:$adr\">$fcopen$val$fcclose</a>";
        } else {
          if ($val ne undef) {
           if ($col =~ /^c\d+/ && $cfg->get("$col.type") eq 'list') {
              $val =~ s/^;//; $val =~ s/;$//;
            }
          } else {
            $val = "-";
          }
          $val =~ s/</&lt;/g;
          $val =~ s/>/&gt;/g;
          $val =~ s/(\d\d\d\d-\d\d-\d\d)/'<nobr>'.$1.'<\/nobr>'/eg;
          $val = $fcopen.$val.$fcclose;
        }
        if ($query->param('qsort') eq $col) { $val = "<b>$val</b>"; }
        $data->{TICKETLIST} .= "<td align=$align valign=top class=$cl>$val</td>\n";
      }
      $data->{TICKETLIST} .= "</tr>\n";
      if ($browsetxt) {
        my $body;
        if ($browsetxt < 2) {
          my $msg = shift (@{$t->{messages}});
          my @msgparts = split(/\n\n/, $msg);
          shift @msgparts;
          $body = join("\n\n", @msgparts);
          $body =~ s/</&lt;/g;
          $body = TTXMarkup::html($body);
        } else {
          $body = TTXMarkup::strip($browser->{abstract}->{$t->{id}});
        }
        $body =~ s/^\s+//s;
        if ($body =~ /^(.{1,340})/s) {
          $body = $1;
        }
        $data->{TICKETLIST} .= "<tr>\n<td class=txt>&nbsp;</td>\n";
        $data->{TICKETLIST} .= "<td colspan=".(int(@brcols - 1))." class=txt>$body</td>\n";
        $data->{TICKETLIST} .= "</tr>\n";
      }
    }
    $data->{TICKETLIST} .= "<tr><td colspan=$ccnt><img src=\"".TTXData::get('CONFIG')->get('imgurl')."/dot.gif\" height=2></td></tr>".
                           "<tr><td align=left colspan=$ccnt>\n".
                           "<table cellpadding=0 cellspacing=0 width=\"100%\"><tr>\n";
    if ($query->param('cmd') ne 'mytickets' && !$readonly) {
      my $operselbox;
      my $userid = $cfg->get('_USER')->{login};
      if ($cfg->get('_USER')->get('tr')) {
        $operselbox = "<select name=to class=sm>\n".
                      "<option></option>\n";
        foreach my $oper (@operlist) {
          my $user = TTXUser->new($oper);
          if ($user ne undef && !$user->{ro}) {
            $operselbox .= "<option value=$oper>$oper</option>\n";
          }
        }
        if ($cfg->get('usegrpsel')) {
          eval "use TTXGroups";
          if ($@ eq undef) {
            my $tmp = $data->{NEWSTATUS};
            TTXGroups::trselector($cfg, $data);
            $operselbox .= $data->{NEWSTATUS};
            $data->{NEWSTATUS} = $tmp;
          }
        }
        $operselbox .= "</select>\n";
        $operselbox = "<input type=submit name=assign value=\"".'[%Assign to%]'."\" class=sm>\n$operselbox";
      }
      $data->{TICKETLIST} .= "<td align=left><input type=submit name=close value=\"".'[%Close selected%]'."\" ".
                             "onclick=\"return confirm('".'[%This will close selected tickets. Please confirm.%]'."')\" class=sm>\n";
      if ($cfg->get('_USER')->get('dt')) {
        $data->{TICKETLIST} .= '<input type=submit name=del value="[%Delete selected%]" '.
                               "onclick=\"return confirm('".'[%This will delete selected tickets. Please confirm.%]'."')\" class=sm>\n";
      }
      $data->{TICKETLIST} .= "$operselbox</form></td>\n";
    }
    $data->{TICKETLIST} .= "<td align=right><span class=sm><b>";
    if ($browser->{first} > 0) {
      $data->{TICKETLIST} .= "<a href=# onClick=\"return scroll('0','".$query->param('qwindow')."')\">".'[%first%]'."</a> ";
    } else {
      $data->{TICKETLIST} .= '<font color="#BBBBBB">[%first%]</font> ';
    }
    if ($browser->{first} > 0) {
      my $back = $browser->{first} - $query->param('qwindow');
      $back = 0 if $back < 0;
      $data->{TICKETLIST} .= "<a href=# onClick=\"return scroll('$back','".$query->param('qwindow')."')\">".'[%prev%]'."</a> ";
    } else {
      $data->{TICKETLIST} .= '<font color="#BBBBBB">[%prev%]</font> ';
    }
    if ($browser->{last} < $browser->{total}) {
      my $frw = $browser->{first} + $query->param('qwindow');
      $data->{TICKETLIST} .= "<a href=# onClick=\"return scroll('$frw','".$query->param('qwindow')."')\">".'[%next%]'."</a> ";
    } else {
      $data->{TICKETLIST} .= '<font color="#BBBBBB">[%next%]</font> ';
    }
    if ($browser->{last} < $browser->{total}) {
      my $frw = $browser->{total} - $query->param('qwindow');
      $data->{TICKETLIST} .= "<a href=# onClick=\"return scroll('$frw','".$query->param('qwindow')."')\">".'[%last%]'."</a> ";
    } else {
      $data->{TICKETLIST} .= '<font color="#BBBBBB">[%last%]</font> ';
    }
    $data->{TICKETLIST} .=  "</b></span></td></tr></table>\n</td></tr>\n";
  }
  if ($session ne undef) {
    my @savelist = ('text', 'oper', 'tid', 'status', 'lname', 'name', 'email', 'fltrsubj', 'grp',
                    'qwindow', 'qoffset', 'qsort', 'qsortorder', 'abstract',
                    'drfld', 'drsday', 'drsmon', 'drsyear', 'dreday', 'dremon', 'dreyear', 'autorefresh');
    for (my $i = 0; $i < $cfldcnt; ++$i) {
      $query->param(-name => "c$i", -value => '');
    }
    $session->qsave($query, 'helpdesk', \@savelist);
  }
  return undef;
}
1;
#
