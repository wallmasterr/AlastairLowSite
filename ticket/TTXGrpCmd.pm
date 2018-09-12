package TTXGrpCmd;
#
# This module is a part of Trouble Ticket Express package
# http://www.troubleticketexpress.com
#
# COPYRIGHT: 2006-2007, United Web Coders
# http://www.unitedwebcoders.com
#
# $Revision: 436 $
# $Date: 2007-10-11 16:21:10 +0400 (Thu, 11 Oct 2007) $
#

$TTXGrpCmd::VERSION='2.24';
BEGIN {
  $TTXGrpCmd::REVISION = '$Revision: 436 $';
  if ($TTXGrpCmd::REVISION =~ /(\d+)/) {
    $TTXGrpCmd::REVISION = $1;
  }
};

use strict;
use TTXCommon;
require TTXUser;
use TTXTickets;
require TTXMail;
require TTXMarkup;
require TTXTicket;

# ================================================================== checkgroups
my $groupsenabled;
sub checkgroups {
  if ($groupsenabled eq undef) {
    eval "use TTXGroups";
    if (!$@) {
      $groupsenabled = 1;
    } else {
      $groupsenabled = 0;
      if ($_[0]->get('usegrpsel')) {
        $_[0]->set('usegrpsel', 0);
        $_[0]->save();
      }
    }
  }
}
# ======================================================================= lockdb
my $lockcnt;
sub lockdb {
  return ++$lockcnt if $lockcnt;
  my $cfg = TTXData::get('CONFIG');
  return 1 if $cfg->get('dbmode') !~ /sql/;
  my $lockfile = $cfg->get('basedir')."/lockdb.ttx";
  if (! -f $lockfile) {
    if (!open(LOCK, ">$lockfile")) {
      return 0;
    }
  } elsif (!open(LOCK,"+<$lockfile")) {
    return 0;
  }
  flock(LOCK, 2);
  $lockcnt = 1;
  return 1;
}
# ===================================================================== unlockdb

sub unlockdb {
  return if !$lockcnt;
  my $cfg = TTXData::get('CONFIG');
  return if $cfg->get('dbmode') !~ /sql/;
  --$lockcnt;
  if (!$lockcnt) {
    flock(LOCK, 8);
    close LOCK;
  }
}
# =========================================================================== do

sub do {
  my ($cfg, $query, $data) = @_;
  checkgroups($cfg);
  lockdb();
  my $tickets = TTXCommon::dbtik();
  if ($tickets eq undef || $tickets->error() ne undef) {
    $data->{ERROR_MESSAGE} = $tickets->errortext();
    return undef;
  }
  my $update = 0;
  my @tidlist = $query->param('tid');
  my $user = $cfg->get('_USER');
  my $userid = $user->{login};
  my $readonly = $user->get('ro') ? 1:0;
  if (!$readonly) {
    foreach my $tid (@tidlist) {
      if ($query->param('del') ne undef) {
        if ($user->get('dt')) {
          $tickets->deltik($tid);
          $update = 1;
        }
      } elsif ($query->param('close') ne undef) {
        my $t = $tickets->ticket($tid);
        next if $t eq undef;
        if ($t->{status} ne 'CLS') {
          if ($t->{oper} eq undef) {
            $t->{oper} = $userid;
          }
          $t->{status} = 'CLS';
          $t->{updated} = time();
          $t->{closed} = $t->{updated};
          TTXCommon::logit("CLOSE|$userid|".$t->{id});
          $update = 1;
        }
      } elsif ($query->param('assign') ne undef) {
        my $t = $tickets->ticket($tid);
        next if $t eq undef;
        my $to = TTXCommon::cleanit($query, 'to');
        next if $to eq undef;
        if ($to !~ /^\+/ && $t->{oper} ne $to) {
          my $user = TTXUser->new($to);
          next if ($user eq undef || $user->get('login') eq undef);
          $t->{oper} = $to;
          $t->{status} = 'OPN' if $cfg->get('transferopens') || $t->{status} eq 'PND';
          $update = 1;
          $t->{updated} = time();
          TTXCommon::logit("TRANSFER|$userid|".$t->{id}."|$to");
          TTXTicket::transfernotice({cfg => $cfg, ticket => $t});
        } elsif($cfg->get('usegrpsel')) {
           next if $t->{grp} eq "+$to";
           $t->{grp} = $to;
           TTXGroups::grptransfer({cfg => $cfg, ticket => $t});
           $update = 1;
           $t->{updated} = time();
        }
      }
    }
  }
  $tickets->save() if $update;
  unlockdb();
  $query->param(-name => 'tid', -value => '');
  $query->param(-name => 'del', -value => '');
  $query->param(-name => 'close', -value => '');
  $query->param(-name => 'assign', -value => '');
  return 'helpdesk'
}

1;
#
