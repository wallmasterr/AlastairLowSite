package TTXFileTickets;
#
# This module is a part of Trouble Ticket Express package
# http://www.troubleticketexpress.com
#
# COPYRIGHT: 2002-2007, United Web Coders
# http://www.unitedwebcoders.com
#
# $Revision: 436 $
# $Date: 2007-10-11 16:21:10 +0400 (Thu, 11 Oct 2007) $
#

$TTXFileTickets::VERSION='2.24';
BEGIN {
  $TTXFileTickets::REVISION = '$Revision: 436 $';
  if ($TTXFileTickets::REVISION =~ /(\d+)/) {
    $TTXFileTickets::REVISION = $1;
  }
};
use strict;
use vars qw(@ISA);
require TTXTickets;
@ISA = qw(TTXTickets);
use TTXData;
require TTXSearch;
require TTXMarkup;
require TTXCommon;

my %errmsgs = (
  NOUSER => 'User does not exist',
  OPENERR => 'Error reading tickets database',
  WRERR => 'Error writing file',
  LOCKWRERR => 'Error acquiring lock (failed to create lock file)',
  LOCKOPNERR => 'Error acquiring lock (failed to open lock file)',
  LOCKERR => 'Error acquiring lock (flock() failed on lock file)',
);

my $boundary = '-----------asdjhfKJS12869nmboiu7826318---';

# ========================================================================== new

sub new {
  my $class = shift;
  my $self  = $class->SUPER::new(@_);
  $self->{_LOCK_CNT} = 0;
  $self->load();
  return $self;
}
# ====================================================================== DESTROY

sub DESTROY {
  my $self  = shift;
  if ($self->{_LOCK_CNT}) {
    $self->{_LOCK_CNT} = 1;
    $self->unlockdb();
  }
}
# ========================================================================= load

sub load {
  my $self  = shift;
  return 0 if !$self->lockdb();
  my $cfg = TTXData::get('CONFIG');
  my $fn = $cfg->get('ticketdb');
  return 1 if ! -f $fn;
  if (!open(DB, $fn)) {
    $self->{_ERROR_CODE} = 'OPENERR';
    $self->unlockdb();
    return 0;
  }
  my @buff = <DB>;
  close DB;
  chomp @buff;
  foreach my $line (@buff) {
    $line = TTXCommon::decodeit($line);
    my @fields = split(/\|/, $line);
    my $tik;
    foreach my $fld ($self->_fields()) {
      $tik->{$fld} = shift @fields;
    }
    $self->{TICKETS}->{$tik->{id}} = $tik;
  }
  return 1;
}
# ======================================================================= lockdb

sub lockdb {
  my $self = shift;
  if ($self->{_LOCK_CNT}) {
    ++$self->{_LOCK_CNT};
    return 1;
  }
  my $lockfile = TTXData::get('CONFIG')->get('basedir')."/lockdb.ttx";
  if (! -f $lockfile) {
    if (!open(LOCK, ">$lockfile")) {
      $self->{_ERROR_CODE} = 'LOCKWRERR';
      return 0;
    }
  } elsif (!open(LOCK,"+<$lockfile")) {
    $self->{_ERROR_CODE} = 'LOCKOPNERR';
    return 0;
  }
  flock(LOCK, 2);
  $self->{_LOCK_CNT} = 1;
  return 1;
}
# ===================================================================== unlockdb

sub unlockdb {
  my $self = shift;
  return if !$self->{_LOCK_CNT};
  --$self->{_LOCK_CNT};
  if (!$self->{_LOCK_CNT}) {
    flock(LOCK, 8);
    close LOCK;
  }
}
# ========================================================================= save

sub save {
  my $self = shift;
  return 0 if !$self->lockdb();
#
# Build temporary file
#
  my $tmpfn = TTXData::get('CONFIG')->get('ticketdb').'.tmp';
  if (!open(TMPDB, ">$tmpfn")) {
    $self->{_ERROR_CODE} = 'WRERR';
    $self->unlockdb();
    return 0;
  }
  flock(TMPDB, 2);
  if (TTXCommon::dodec()) {
    if ($] >= 5.008) {
      binmode TMPDB, ":utf8";
    } else {
      binmode TMPDB;
    }
  }
  foreach my $id (keys %{$self->{TICKETS}}) {
    my $line;
    my $tik = $self->{TICKETS}->{$id};
    foreach my $fld ($self->_fields()) {
      my $val = $tik->{$fld};
      $val =~ s/\|/!/g;
      $val =~ s/\r//g;
      $val =~ s/\n/ /g;
      $line .= "$val|";
    }
    print TMPDB "$line\n";
    if ($tik->{messages} ne undef) {
      my $fn = TTXData::get('CONFIG')->get('basedir')."/tickets/$id.cgi";
      if (open(MSG, ">$fn")) {
        flock(MSG, 2);
        if (TTXCommon::dodec()) {
          if ($] >= 5.008) {
            binmode MSG, ":utf8";
          } else {
            binmode MSG;
          }
        }
        foreach my $msg (@{$tik->{messages}}) {
          print MSG "$msg\n$boundary\n";
        }
        truncate(MSG, tell(MSG));
        close MSG;
        umask(0);
        chmod(0777, $fn);
      }
    }
  }
  close(TMPDB);
  umask(0);
  chmod(0777, $tmpfn);
#
# Check if the ticket database exists, create if none.
#
  my $fn = TTXData::get('CONFIG')->get('ticketdb');
  if (! -f $fn) {
    if (!open(DB, ">$fn")) {
      $self->{_ERROR_CODE} = 'WRERR';
      $self->unlockdb();
      return 0;
    }
    close DB;
  }
#
# Check if it's time for backup
#
  my $backupfq = TTXData::get('CONFIG')->get('backupfq');
  $backupfq = 7 * 24 * 60 * 60 if int($backupfq) < 10;
  my $tmext = time();
  $tmext = $tmext - ($tmext % $backupfq);
  my $backupdir = TTXData::get('CONFIG')->get('basedir').'/backup';
  my $backupfn = $backupdir."/tickets$tmext.cgi";
  if (! -f $backupfn) {
    if (! -d $backupdir) {
      umask(0);
      if (!mkdir($backupdir, 0777)) {
        warn "Failed to create directory '$backupdir'";
      }
    }
    if (-d $backupdir) {
      rename $fn, $backupfn;
    }
  }
#
# Replace ticket DB
#
  if (!rename($tmpfn,$fn)) {
    umask 0;
    chmod(0777, $fn);
    if (!rename($tmpfn,$fn)) {
      warn "Failed to 'rename($tmpfn,$fn), make sure the $fn is NOT read-only.";
      $self->{_ERROR_CODE} = 'WRERR';
      $self->unlockdb();
      return 0;
    }
  }
  $self->unlockdb();
  if (TTXData::get('_USECACHE')) {
    eval "use TTXCache";
    TTXCache::purge() if $@ eq undef;
  }
  return 1;
}
# ======================================================================= deltik

sub deltik {
  my $self  = shift;
  my $id = shift;
  my $fn = TTXData::get('CONFIG')->get('basedir')."/tickets/$id.cgi";
  $fn =~ /(.*)/; $fn = $1;
  unlink $fn if -f $fn;
  if (TTXData::get('ISPRO')) {
    TTXFile::delfiles($id);
  }
  delete $self->{TICKETS}->{$id};
}
# ================================================================== ticketbykey

sub ticketbykey {
  my $self  = shift;
  my $key = shift;
  my $id = $key;
  $id =~ s/Z.*$//;
  if (TTXData::get('CONFIG')->get('shortkey') || $self->{TICKETS}->{$id}->{key} eq $key) {
    return $self->ticket($id);
  }
  return undef;
}
# ======================================================================= ticket

sub ticket {
  my ($self, $id, $nomsg) = @_;
  my $tik = $self->{TICKETS}->{$id};
  if ($tik ne undef && $tik->{message} eq undef && !$nomsg) {
    my $fn = TTXData::get('CONFIG')->get('basedir')."/tickets/$id.cgi";
    if (-f $fn && open(MSG, $fn)) {
      my $rawmsg;
      read(MSG, $rawmsg, 64*1024);
      close MSG;
      $rawmsg = TTXCommon::decodeit($rawmsg);
      my @messages = split(/\n$boundary\n/, $rawmsg);
      $tik->{messages} = \@messages;
    }
  }
  return $tik;
}
# ==================================================================== addticket

sub addticket {
  my $self  = shift;
  my $tik = shift;
  my $fn = TTXData::get('CONFIG')->get('ticketid');
  if (! -f $fn) {
    if (!open(ID, ">$fn")) {
      $self->{_ERROR_CODE} = 'WRERR';
      return 0;
    }
    print ID "0\n";
    close ID;
  }
  if (!open(ID,"+<$fn")) {
    $self->{_ERROR_CODE} = 'WRERR';
    return 0;
  }
  flock(ID, 2);
  my $id = <ID>;
  chomp $id;
  ++$id;
  seek(ID, 0, 0);
  print ID "$id\n";
  close ID;
  umask(0);
  chmod(0777, $fn);
  $tik->{open} = time() if $tik->{open} eq undef;
  $tik->{updated} = $tik->{open};
  $tik->{status} = 'PND';
  $tik->{id} = $id;
  $tik->{key} = "$id";
  if (!TTXData::get('CONFIG')->get('shortkey')) {
    $tik->{key} .= "Z$$".int(1000000 + rand(9000000)).int(1000000 + rand(9000000));
  }
  $self->{TICKETS}->{$id} = $tik;
  return $id;
}
# ========================================================================= list

sub list {
  my ($self, $off, $win, $col, $ord, $filter, $drange)  = @_;
  my @list = keys %{$self->{TICKETS}};
  my $tickets = $self->{TICKETS};
  my $byid;
  my $ftxt;
  my $abstract = {};
  if ($filter ne undef) {
    foreach my $f (@{$filter}) {
      my $expr = $f->{expr};
      my $c = $f->{col};
      if ($c eq 'text') {
        $ftxt = $f;
      } elsif ($c eq '-grp-') {
        my $oper = $f->{oper};
        my $grps = join('|', @{$f->{groups}});
        if ($grps ne undef) {
          @list = grep {$tickets->{$_}->{oper} eq $oper || $tickets->{$_}->{grp} =~ /^$grps$/} @list;
        } else {
          @list = grep {$tickets->{$_}->{oper} eq $oper} @list;
        }
      } else {
        $byid = 1 if $c eq 'id';
        @list = grep {$tickets->{$_}->{$c} =~ /$expr/i} @list;
      }
    }
  }
  if (!$byid && TTXData::get('CONFIG')->get('hideoldsolved')) {
    my $oldis = int(TTXData::get('CONFIG')->get('hideoldsolved'));
    $oldis = time() -  $oldis * 3600 * 24;
    @list = grep {$tickets->{$_}->{status} ne 'CLS' || $tickets->{$_}->{closed} > $oldis} @list;
  }
  if ($drange->{fld} ne undef) {
    my %fldmap = ( created => 'open', updated => 'updated', solved => 'closed' );
    my $fld = $fldmap{$drange->{fld}};
    my $stm = $drange->{stm};
    my $etm = $drange->{etm};
    @list = grep {$tickets->{$_}->{$fld} >= $stm && $tickets->{$_}->{$fld} <= $etm} @list;
  }
  if ($ftxt ne undef) {
    my @l1;
    my $tokens = TTXSearch::tokenize($ftxt->{expr});
    my $match;
    my $body;
    my $token;
    foreach my $id (@list) {
      my $t = $self->ticket($id);
      next if $t eq undef;
      foreach my $msg (@{$t->{messages}}) {
        $msg =~ s/^.+\n\n//s;
        $body = TTXMarkup::strip($msg);
        $match = 1;
        foreach $token (@{$tokens}) {
          if ($body !~ /\b$token\b/i) {
            $match = 0;
            last;
          }
        }
        if ($match) {
          $abstract->{$id} = TTXSearch::abstract($body, $tokens);
          push @l1, $id;
          last;
        }
      }
    }
    @list = @l1;
  }
  if (grep(/^$col$/, ('open', 'closed', 'updated', 'id'))) {
    if ($ord eq 'A') {
      @list = sort {$tickets->{$a}->{$col} <=> $tickets->{$b}->{$col}} @list;
    } else {
      @list = sort {$tickets->{$b}->{$col} <=> $tickets->{$a}->{$col}} @list;
    }
  } else {
    if ($ord eq 'A') {
      @list = sort {$tickets->{$a}->{$col} cmp $tickets->{$b}->{$col}} @list;
    } else {
      @list = sort {$tickets->{$b}->{$col} cmp $tickets->{$a}->{$col}} @list;
    }
  }
  $off = 0 if $off < 0 || $off > @list;
  $win = 20 if $win < 1;
  $win = @list - $off if ($off + $win) > @list;
  my $browser;
  $browser->{abstract} = $abstract;
  $browser->{total} = int(@list);
  @{$browser->{list}} = splice @list, $off, $win;
  $browser->{first} = $off;
  $browser->{last} = $off + @{$browser->{list}};
  return $browser;
}
# ==================================================================== errortext

sub errortext {
  my $self = shift;
  return $errmsgs{$self->{_ERROR_CODE}};
}

1;
#
