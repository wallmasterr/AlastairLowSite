package TTXTickEd;
#
# This module is a part of Trouble Ticket Express package
# http://www.troubleticketexpress.com
#
# COPYRIGHT: 2005-2007, United Web Coders
# http://www.unitedwebcoders.com
#
# $Revision: 443 $
# $Date: 2007-10-11 16:27:57 +0400 (Thu, 11 Oct 2007) $
#

$TTXTickEd::VERSION='2.24';
BEGIN {
  $TTXTickEd::REVISION = '$Revision: 443 $';
  if ($TTXTickEd::REVISION =~ /(\d+)/) {
    $TTXTickEd::REVISION = $1;
  }
};
use strict;
use TTXCommon;
use TTXUser;

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
# ==================================================================== searchbox

my $_lookupenabled = undef;

sub searchbox {
  if ($_lookupenabled eq undef) {
    eval 'use TTXLookup';
    if ($@ eq undef) {
      $_lookupenabled = 1;
    } else {
      $_lookupenabled = 0;
    }
  }
  return 0 if !$_lookupenabled;
  return TTXLookup::checkit($_[0]);
}
# ===================================================================== ticketed
sub ticketed {
  my ($cfg, $query, $data) = @_;
  my $user = $cfg->get('_USER');
  if ($query->param('isticket')) {
    $query->param(-name => 'isticket', value => '1');
  } else {
    $query->param(-name => 'isticket', value => '0');
  }
  if ($user ne undef && $user->get('ro')) {
    $data->{ERROR_MESSAGE} = '[%Access denied%]';
    return undef;
  }
  my $tickets = TTXCommon::dbtik();
  if ($tickets eq undef || $tickets->error() ne undef) {
    $data->{ERROR_MESSAGE} = $tickets->errortext();
    return undef;
  }
  my $t = $tickets->ticket(TTXCommon::cleanit($query, 'tid'));
  if ($t eq undef) {
    $data->{ERROR_MESSAGE} = '[%Ticket does not exist%]';
    return undef;
  }
  if (!$query->param('do')) {
    if (invenabled()) {
      my $iline = $t->{item};
      $iline =~ s/^;//; $iline =~ s/;$//;
      my @ilist = split(/;/, $iline);
      $query->param(-name => 'item', -values => \@ilist);
    }
  }
  if ($query->param('do')) {
    my $val = TTXCommon::cleanit($query, 'email');
    if ($val !~ /^[0-9A-Za-z.'_+-]+@[0-9A-Za-z_-]+\.[0-9A-Za-z._-]+$/) {
      $data->{ERROR_MESSAGE} .= '[%Invalid email address%]';
    } else {
      $t->{email} = $val;
    }
    if ($cfg->get('editopendate')) {
      eval "use Time::Local";
      if ($@ eq undef) {
        my $tz = $cfg->get('timezone') * 60;
        $t->{open} = Time::Local::timegm($query->param('sec'),$query->param('min'),$query->param('hour'),
                                         $query->param('day'),$query->param('mon'),
                                         $query->param('year')) - $tz;
      }
    }
    if ($cfg->get('editclosedate') && $t->{status} eq 'CLS') {
      eval "use Time::Local";
      if ($@ eq undef) {
        my $tz = $cfg->get('timezone') * 60;
        $t->{closed} = Time::Local::timegm($query->param('clssec'),$query->param('clsmin'),$query->param('clshour'),
                                         $query->param('clsday'),$query->param('clsmon'),
                                         $query->param('clsyear')) - $tz;
        if ($t->{closed} < $t->{open}) {
          $t->{closed} = $t->{open};
        }
        $t->{updated} = $t->{closed};
      }
    }
    if ($cfg->get('firstname') =~ /^\s*\d+/ && $cfg->get('lastname') =~ /^\s*\d+/) {
      my $name = join(' ', (TTXCommon::cleanit($query, 'c'.int($cfg->get('firstname'))),
                            TTXCommon::cleanit($query, 'c'.int($cfg->get('lastname')))));
      $query->param('name', $name);
    }
    $val = TTXCommon::cleanit($query, 'name', 1);
    $t->{name} = $val if $val ne undef;
    $val = TTXCommon::cleanit($query, 'subject', 1);
    $t->{subject} = $val if $val ne undef;
    my @items = $query->param('item');
    if (grep(/^-$/, @items)) {
      @items = ('-');
      $t->{item} = '';
    } else {
      $t->{item} = ';'.join(';', @items).';';
    }
    foreach my $cfld (sort grep(/^c\d\d?$/, $query->param())) {
      if ($cfg->get("grant.$cfld") ne undef) {
        my $login = $user->get('login');
        next if !grep(/^$login$/, split(/,/, $cfg->get("grant.$cfld")));
      }
      if ($cfg->get("$cfld.type") eq 'list') {
        my $n = $cfld;
        $n =~ s/^c//;
        my @allow = split(/;/, TTXCommon::decodeit($cfg->get("dropdown$n")));
        my @qlist = $query->param($cfld);
        my @vlist;
        foreach my $v (@qlist) {
          $v = TTXCommon::decodeit($v);
          $v =~ s/\n//g; $v =~ s/\r//g;
          $v =~ s/^\s+//; $v =~ s/\s+$//g;
          push @vlist, $v if grep(/^$v$/, @allow);
        }
        $t->{$cfld} = ';'.join(';', @vlist).';';
      } else{
        $t->{$cfld} = TTXCommon::cleanit($query, $cfld, 1);
      }
    }
    if ($data->{ERROR_MESSAGE} eq undef) {
      $tickets->save();
      $data->{MESSAGE} = '[%Ticket updated%]';
    }
  }
  $data->{TICKET_subject} = $t->{subject};
  $data->{TICKET_email} = $t->{email};
  $data->{TICKET_name} = $t->{name};
  $data->{TICKET_key} = $t->{key};
  my @list = grep(/^x/, $cfg->vars());
  my @editable = split(/;/, $cfg->get('editablefields'));
  my %cflds;
  foreach my $id (@list) {
    my $cid = $cfg->get($id);
    next if $cid !~ /^\d\d?$/;
    $cid = "c$cid";
    if ($cfg->get("grant.$cid") ne undef) {
      my $login = $user->get('login');
      next if !grep(/^$login$/, split(/,/, $cfg->get("grant.$cid")));
    }
    if (grep(/^$cid$/, @editable)) {
      $cflds{$cid} = $id;
      $cflds{$cid} =~ s/^x//;
    }
  }
  if (invenabled()) {
    my $lbl = $cfg->get('inventory.label') || '[%Item%]';
    $lbl =~ s/</&lt;/g;
    $data->{CUSTOMFIELDS} .= "<tr><td align=right><b>$lbl</b></td><td align=left>".
                             TTXInvMod::selbox($cfg, $query, 1)."</td></tr>\n";
  }
  if ($cfg->get('editopendate')) {
    $data->{CUSTOMFIELDS} .= '<tr><td align=right><b>[%Submitted%]</b></td>'."\n".
                            "<td align=left>";
    my $tz = $cfg->get('timezone') * 60;
    my ($sec, $min, $hour, $mday,$mon,$year) = (gmtime($t->{open} + $tz))[0,1,2,3,4,5];
    $query->param(-name => 'sec', -value => $sec);
    $query->param(-name => 'min', -value => $min);
    $query->param(-name => 'hour', -value => $hour);
    $query->param(-name => 'year', -value => $year);
    $query->param(-name => 'mon', -value => $mon);
    $query->param(-name => 'day', -value => $mday);
    $data->{CUSTOMFIELDS} .= TTXCommon::pickdate($query, '');
    eval "use TTXPickTime";
    if (!$@) {
      $data->{CUSTOMFIELDS} .= TTXPickTime::picktime($query, '');
    }
    $data->{CUSTOMFIELDS} .= "</td></tr>\n";
  }
  if ($cfg->get('editclosedate') && $t->{status} eq 'CLS') {
    $data->{CUSTOMFIELDS} .= '<tr><td align=right><b>[%Solved%]</b></td>'."\n".
                            "<td align=left>";
    my $tz = $cfg->get('timezone') * 60;
    my ($sec, $min, $hour, $mday,$mon,$year) = (gmtime($t->{closed} + $tz))[0,1,2,3,4,5];
    $query->param(-name => 'clssec', -value => $sec);
    $query->param(-name => 'clsmin', -value => $min);
    $query->param(-name => 'clshour', -value => $hour);
    $query->param(-name => 'clsyear', -value => $year);
    $query->param(-name => 'clsmon', -value => $mon);
    $query->param(-name => 'clsday', -value => $mday);
    $data->{CUSTOMFIELDS} .= TTXCommon::pickdate($query, 'cls');
    eval "use TTXPickTime";
    if (!$@) {
      $data->{CUSTOMFIELDS} .= TTXPickTime::picktime($query, 'cls');
    }
    $data->{CUSTOMFIELDS} .= "</td></tr>\n";
  }
  foreach my $id (sort keys %cflds) {
    $data->{CUSTOMFIELDS} .= "<tr><td align=right><b>$cflds{$id}</b></td>\n".
                            "<td align=left>";
    my $n = $id;
    $n =~ s/^c//;
    my @options = split(/;/, TTXCommon::decodeit($cfg->get("dropdown$n")));
    if (@options > 0) {
      my @qlist;
      my $multi;
      if ($cfg->get("$id.type") eq 'list') {
        my $cnt = int @options;
        $cnt = 3 if $cnt > 3;
        $multi = " multiple size=3";
        if ($query->param('do')) {
          @qlist = $query->param($id);
          for (my $i = 0; $i < @qlist; ++$i) {
            $qlist[$i] = TTXCommon::decodeit($qlist[$i]);
          }
        } else {
          @qlist = split(/;/, $t->{$id});
        }
      } else {
        if ($query->param('do')) {
          $qlist[0] = TTXCommon::decodeit($query->param($id));
        } else {
          $qlist[0] = $t->{$id};
        }
      }
      $data->{CUSTOMFIELDS} .= "<select$multi name=$id>\n";
      foreach my $opt (@options) {
        my $val = $opt; $val =~ s/"/&quot;/g;
        $data->{CUSTOMFIELDS} .= "<option value=\"$val\"";
        if (grep(/^$opt$/, @qlist)) {
          $data->{CUSTOMFIELDS} .= ' selected';
        }
        $opt =~ s/</&lt;/g;
        $data->{CUSTOMFIELDS} .= ">$opt</option>\n";
      }
      $data->{CUSTOMFIELDS} .= "</select>\n";
    } else {
      my $val = $query->param('do') ? TTXCommon::decodeit($query->param($id)) : $t->{$id};
      $val =~ s/"/&quot;/g;
      $data->{CUSTOMFIELDS} .= "<input type=text size=30 name=$id value=\"$val\">";
    }
    if (searchbox($n)) {
      $data->{CUSTOMFIELDS} .= "<small>&nbsp;<a href=# onclick=\"cflookup($n)\">".'[%search%]</a></small>';
      $data->{CFLOOKUP} = TTXLookup::javascript($query) if $data->{CFLOOKUP} eq undef;
    }
    $data->{CUSTOMFIELDS} .= "</td></tr>\n";
  }
  return undef;
}

1;
#
