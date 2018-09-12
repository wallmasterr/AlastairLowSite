package TTXCommon;
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

$TTXCommon::VERSION='2.24';
BEGIN {
  $TTXCommon::REVISION = '$Revision: 435 $';
  if ($TTXCommon::REVISION =~ /(\d+)/) {
    $TTXCommon::REVISION = $1;
  }
};

use strict;
require TTXData;
require TTXDictionary;

my %id2name = (
  PND => 'Pending',
  OPN => 'Open',
  WFR => 'Responded',
  '(OPN|WFR)' => 'Active',
  '(PND|OPN|WFR)' => 'Not solved',
  '(OPN|PND)' => 'Hot',
  CLS => 'Solved'
);

my @week = ('Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat');
my $_dodecode = undef;
my $_docheckutf = undef;

# ====================================================================== cfldcnt

sub cfldcnt {
  my $cnt = 10;
  my $cfg = TTXData::get('CONFIG');
  if ($cfg ne undef) {
    my $n = int ($cfg->get('cfldcnt'));
    if ($n > 10 && $n <= 100) {
      $cnt = $n;
    }
  }
  return $cnt;
}
# =================================================================== logit2file

sub logit2file {
  my $cfg = TTXData::get('CONFIG');
  my $fn = $cfg->get('basedir')."/$_[1]";
  if (open(TTXLOG, ">>$fn")) {
    flock(TTXLOG,2);
    seek(TTXLOG, 0, 2);
    print TTXLOG time().TTXCommon::encodeit("|$_[0]\n");
    close TTXLOG;
  }
}
# ======================================================================== logit

sub logit {
  logit2file($_[0], 'ttxlog.txt');
}
# ====================================================================== debugit

sub debugit {
  logit2file("PID=$$, $_[0]", 'ttxdebug.txt');
}
# ======================================================================== tmtxt

sub tmtxt {
  return "-" if !$_[0];
  my $cfg = TTXData::get('CONFIG');
  my $longtime = 1 if $cfg->get('time.long') || $_[1];
  my $tz = $cfg->get('timezone') * 60;
  my $tm = $_[0] + $tz;
  my ($sec,$min,$hour,$mday,$mon,$year, $wday) = gmtime($tm);
  my ($sec1,$min1,$hour1,$mday1,$mon1,$year1) = gmtime(time() + $tz);
  my $date;
  my $wkday;
  if ($cfg->get('time.weekday')) {
    $wkday = TTXDictionary::translate($week[$wday]).' ';
  }
  if ($year != $year1 || $longtime) {
    $year += 1900; $year =~ s/^\d\d//;
    $mon++; $mon = "0$mon" if $mon < 10;
    $mday = "0$mday" if $mday < 10;
    $date = $wkday . ($cfg->get('etime') ? "$mday/$mon/$year" : "$mon/$mday/$year");
  } elsif ($mon != $mon1 || $mday != $mday1) {
    $mon++; $mon = "0$mon" if $mon < 10;
    $mday = "0$mday" if $mday < 10;
    $date = $wkday . ($cfg->get('etime') ? "$mday/$mon" : "$mon/$mday");
  }
  $date .= " " if $date ne undef;
  $hour = "0$hour" if $hour < 10;
  $min = "0$min" if $min < 10;
  $date .= "$hour:$min";
  return $date;
}
# ======================================================================== dbtik

sub dbtik {
  my $cfg = TTXData::get('CONFIG');
  return undef if $cfg eq undef;
  if ($cfg->get('dbmode') eq undef || $cfg->get('dbmode') eq 'plaintext') {
    eval "use TTXFileTickets";
    return TTXFileTickets->new();
  } elsif ($cfg->get('dbmode') eq 'mysql') {
    eval "use TTXMySQLTickets";
    return TTXMySQLTickets->new();
  } elsif ($cfg->get('dbmode') eq 'mssql') {
    eval "use TTXMSSQLTickets";
    return TTXMSSQLTickets->new() if !$@;
  }
  return TTXTickets->new();
}
# ======================================================================= status

sub status {
  return $id2name{$_[0]};
}
# ======================================================================== dodec

sub dodec {
  if ($_dodecode eq undef) {
    $_dodecode = 0;
    if (TTXData::get('CONFIG')->get('charset') =~ /^utf/i) {
      eval "use Encode";
      if ($@ eq undef) {
        $_dodecode = 1;
      }
      my $flag = undef;
      my $val = decode('UTF-8', "value");
      eval '$flag = utf8::is_utf8($val)';
      if ($@ eq undef && $flag) {
        $_docheckutf = 1;
      }
    }
  }
  return $_dodecode;
}
# ===================================================================== decodeit

sub decodeit {
  my $val = $_[0];
  if (dodec()) {
    if ($_docheckutf) {
      $val = decode('UTF-8', $val) if !utf8::is_utf8($val);
    } else {
      eval '$val = decode("UTF-8", $val)';
    }
  }
  return $val;
}
# ===================================================================== encodeit

sub encodeit {
  my $val = $_[0];
  if (dodec()) {
    if ($_docheckutf) {
      $val = encode('UTF-8', $val) if utf8::is_utf8($val);
    } else {
      eval '$val = encode("UTF-8", $val)';
    }
  }
  return $val;
}
# ====================================================================== cleanit

sub cleanit {
  my ($query, $input, $anddecode) = @_;
  my $val = $query->param($input);
  $val =~ s/^\s+//;
  $val =~ s/\s+$//;
  $query->param(-name => $input, -value => $val);
  $val = decodeit($val) if $anddecode;
  return $val;
}
# ======================================================================== blank

sub blank {
  my ($cfg, $query, $data) = @_;
  return undef;
}
# ===================================================================== cfldscnt

sub cfldscnt {
  my @list = grep(/^x/, $_[0]->vars());
  my @editable = split(/;/, $_[0]->get('editablefields'));
  my $cnt = 0;
  foreach my $id (@list) {
    my $cid = $_[0]->get($id);
    next if $cid !~ /^\d\d?$/;
    $cid = "c$cid";
    ++$cnt if grep(/^$cid$/, @editable);
  }
  return $cnt;
}
# =================================================================== tickedvars

sub tickedvars {
  my ($cfg, $data) = @_;
  $data->{TICKEDHEIGHT} = 250 + cfldscnt($cfg) * 30;
  if ($cfg->get('editclosedate')) {
    $data->{TICKEDHEIGHT} += 50;
  }
  if ($data->{TICKEDHEIGHT} > 600) {
    $data->{TICKEDHEIGHT} = 600;
  }
}

my @months = ('Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec');

# ===================================================================== pickdate

sub pickdate {
  my ($query, $pref, $start) = @_;
  my $buff;
  my $year = $query->param($pref.'year');
  my $mon = $query->param($pref.'mon');
  my $day = $query->param($pref.'day');
  if ($year =~ /\D/ || $year > 137) {
    $year = '';
  }
  if ($mon =~ /\D/ || $mon > 11) {
    $mon = '';
  }
  if ($day =~ /\D/ || $day > 31) {
    $day = '';
  }
  if ($year eq '') {
    $mon = '';
    $day = '';
  } else {
    if ($mon eq '') {
      $mon = $start ? 0:11;
      $day = $start ? 1:31;
    } elsif ($day eq '') {
      if ($start) {
        $day = 1;
      } else {
        my @daysmo = (31, ($year % 4) ? 28:29, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31);
        $day = $daysmo[$mon];
      }
    }
  }
  $query->param(-name => $pref.'year', -value => $year);
  $query->param(-name => $pref.'mon', -value => $mon);
  $query->param(-name => $pref.'day', -value => $day);
  $buff .= "<select name=$pref"."day>\n<option></option>\n";
  for (my $i = 1; $i < 32; ++$i) {
    $buff .= '<option';
    $buff .= ' selected' if $day == $i;
    $buff .= ">$i</option>\n";
  }
  $buff .= "</select>\n<select name=$pref"."mon>\n<option></option>\n";
  for (my $i = 0; $i < 12; ++$i) {
    $buff .= "<option value=$i";
    $buff .= ' selected' if $mon ne '' && $mon == $i;
    $buff .= '>[%'.$months[$i]."%]</option>\n";
  }
  $buff .= "</select>\n<select name=$pref"."year>\n<option></option>\n";
  my $baseyr = $year;
  my $thisyr = (gmtime())[5];
  if ($baseyr eq '') {
    $baseyr = $thisyr;
  }
  my $cfg = TTXData::get('CONFIG');
  my $yrsback;
  if ($cfg->get('startyear') ne undef) {
    $yrsback = $baseyr - $cfg->get('startyear');
  }
  $yrsback = 5 if $yrsback eq undef;
  for (my $i = $baseyr-$yrsback; $i <= $thisyr; ++$i) {
    my $yr = $i;
    next if $yr < 0;
    $buff .= "<option value=$yr";
    $buff .= ' selected' if $year ne '' && $year == $yr;
    $buff .= '>'.($yr+1900)."</option>\n";
  }
  $buff .= "</select>\n";
  return $buff;
}
# ================================================================== checkdrange

sub checkdrange {
  my ($query, $start, $end) = @_;
  my $year = $query->param($start.'year');
  return if $year eq undef;
  my $mon = $query->param($start.'mon');
  my $day = $query->param($start.'day');
  my $year1 = $query->param($end.'year');
  my $mon1 = $query->param($end.'mon');
  my $day1 = $query->param($end.'day');
  if ($mon eq undef || $mon =~ /\D/ || $mon > 11) {
    $mon = 0;
    $day = 1;
  } elsif ($day =~ /\D/ || !$day) {
    $day = 1;
  } else {
    my @daysmo = (31, ($year % 4) ? 28:29, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31);
    $day = $daysmo[$mon] if $day > $daysmo[$mon];
  }
  if ($year1 eq undef || $year1 =~ /\D/) {
    $year1 = $year;
  }
  if ($mon1 eq undef || $mon1 =~ /\D/ || $mon1 > 11) {
    $mon1 = 11;
    $day1 = 31;
  } else {
    if ($day1 =~ /\D/ || !$day1) {
      $day1 = 31;
    }
    my @daysmo = (31, ($year1 % 4) ? 28:29, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31);
    $day1 = $daysmo[$mon1] if $day1 > $daysmo[$mon1];
  }
  eval "use Time::Local";
  if ($@ eq undef) {
    my $stm = Time::Local::timegm(0,0,0,$day,$mon,$year);
    my $etm = Time::Local::timegm(59,59,23,$day1,$mon1,$year1);
    if ($etm < $stm) {
      $etm = $stm + 24*3600;
    }
    ($day, $mon, $year) = (gmtime($stm))[3,4,5];
    ($day1, $mon1, $year1) = (gmtime($etm))[3,4,5];
  }
  $query->param(-name => $start.'year', -value => $year);
  $query->param(-name => $start.'mon', -value => $mon);
  $query->param(-name => $start.'day', -value => $day);
  $query->param(-name => $end.'year', -value => $year1);
  $query->param(-name => $end.'mon', -value => $mon1);
  $query->param(-name => $end.'day', -value => $day1);
}

1;
#
