package TTXInventory;
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

$TTXInventory::VERSION='2.24';
BEGIN {
  $TTXInventory::REVISION = '$Revision: 436 $';
  if ($TTXInventory::REVISION =~ /(\d+)/) {
    $TTXInventory::REVISION = $1;
  }
};

use strict;
use TTXData;
use TTXCommon;

my $idb = undef;
my $states = undef;
my $lasterror;
my @itemfields = ('id', 'title', 'status', 'img');
my @statefields = ('id', 'title', 'img');

# ====================================================================== notesfn

sub notesfn {
  my $cfg = TTXData::get('CONFIG');
  my $dn = $cfg->get('basedir').'/inventory';
  return "$dn/$_[0].cgi";
}

# ======================================================================== idbfn

sub idbfn {
  my $cfg = TTXData::get('CONFIG');
  my $dn = $cfg->get('basedir').'/inventory';
  my $fn = "$dn/index.cgi";
  if (! -d $dn) {
    if (!mkdir($dn, 0777)) {
      $lasterror = "Failed to create inventory database directory";
      return undef;
    }
  }
  if (! -f $fn) {
    open(IDB, ">$fn");
    close(IDB);
    if (! -f $fn) {
      $lasterror = "Failed to create inventory database";
      return undef;
    }
  }
  return $fn;
}
# ==================================================================== line2item

sub line2item {
  chomp($_[0]);
  my @fields = split(/\|/, TTXCommon::decodeit($_[0]));
  my %item;
  foreach my $key (@itemfields) {
    $item{$key} = shift @fields;
    $item{key} =~ s/^\s+//;
    $item{key} =~ s/\s+$//;
  }
  return %item;
}
# ==================================================================== item2line

sub item2line {
  my $item = $_[0];
  my @vals;
  foreach my $key (@itemfields) {
    my $val = $item->{$key};
    $val =~ s/\|/!/g;
    push @vals, TTXCommon::encodeit($val);
  }
  return join('|', @vals);
}
# ========================================================================= load

sub load {
  if ($idb eq undef) {
    my $fn = idbfn();
    return 0 if $fn eq undef;
    lockdb();
    if (!open(IDB, $fn)) {
      $lasterror = "Failed to open inventory database file";
      return 0;
    }
    flock(IDB,2);
    for (my $line = <IDB>; $line ne undef; $line = <IDB>) {
      my %item = line2item($line);
      next if $item{id} !~ /^\d+$/;
      my $nfn = notesfn($item{id});
      if (-f $nfn) {
        if (open(NOTES, $nfn)) {
          $item{notes} = TTXCommon::decodeit(join('', <NOTES>));
          close(NOTES);
        }
      }
      $idb->{$item{id}} = \%item;
    }
    close(IDB);
    unlockdb();
  }
  return 1;
}
# ========================================================================= list

sub list {
  return keys %{$idb} if load();
  my @empty;
  return @empty;
}
# ====================================================================== getitem

sub getitem {
  return undef if !load();
  if (! exists $idb->{$_[0]}) {
    $lasterror = "Item $_[0] does not exist";
    return undef;
  }
  return $idb->{$_[0]};
}
# ======================================================================= savedb

sub savedb {
  return 1 if $idb eq undef;
  my $fn = idbfn();
  return 0 if $fn eq undef;
  return 0 if !lockdb();
  if (!open(IDB, ">$fn")) {
    $lasterror = "Failed to open inventory database file";
    unlockdb();
    return 0;
  }
  flock(IDB,2);
  foreach my $id (sort {$a <=> $b} keys %{$idb}) {
    next if $id !~ /^\d+$/;
    print IDB item2line($idb->{$id})."\n";
    my $nfn = notesfn($id);
    if ($idb->{$id}->{notes} ne undef) {
      if (open(NOTES, ">$nfn")) {
        print NOTES TTXCommon::encodeit($idb->{$id}->{notes});
        close(NOTES);
      }
    } elsif (-f $nfn) {
      unlink $nfn;
    }
  }
  close(IDB);
  unlockdb();
  if (TTXData::get('_USECACHE')) {
    eval "use TTXCache";
    TTXCache::purge() if $@ eq undef;
  }
  return 1;
}
# ========================================================================== add

sub add {
  my $item = $_[0];
  my $fn = idbfn();
  return undef if $fn eq undef;
  return undef if !lockdb();
  if (!load()) {
    unlockdb();
    return undef;
  }
  my @lst = sort {$a <=> $b } list();
  my $cnt = int(@lst);
  if (!$cnt) {
    $item->{id} = 1;
  } else {
    $item->{id} = int($lst[$cnt - 1]) + 1;
  }
  if (!open(IDB, ">>$fn")) {
    $lasterror = "Failed to open inventory database file";
    unlockdb();
    return undef;
  }
  flock(IDB,2);
  seek(IDB,0,2);
  print IDB item2line($item)."\n";
  close(IDB);
  if ($item->{notes} ne undef) {
    my $nfn = notesfn($item->{id});
    if (open(NOTES, ">$nfn")) {
      print NOTES $item->{notes};
      close(NOTES);
    }
  }
  unlockdb();
  if (TTXData::get('_USECACHE')) {
    eval "use TTXCache";
    TTXCache::purge() if $@ eq undef;
  }
  $idb->{$item->{id}} = $item;
  return $item->{id};
}
# ======================================================================= lockdb
my $_lockcnt = 0;

sub lockdb {
  if ($_lockcnt) {
    ++$_lockcnt;
    return 1;
  }
  my $lockfile = TTXData::get('CONFIG')->get('basedir')."/lockidb.ttx";
  if (! -f $lockfile) {
    if (!open(LOCK, ">$lockfile")) {
      $lasterror = 'LOCKWRERR';
      return 0;
    }
  } elsif (!open(LOCK,"+<$lockfile")) {
    $lasterror = 'LOCKOPNERR';
    return 0;
  }
  flock(LOCK, 2);
  $_lockcnt = 1;
  return 1;
}
# ===================================================================== unlockdb

sub unlockdb {
  return if !$_lockcnt;
  --$_lockcnt;
  if (!$_lockcnt) {
    flock(LOCK, 8);
    close LOCK;
  }
}
# ========================================================================== del

sub del {
  my $id = $_[0];
  return 0 if !lockdb();
  if (!load()) {
    unlockdb();
    return 0;
  }
  if (!exists $idb->{$id}) {
    unlockdb();
    return 1;
  }
  my $nfn = notesfn($id);
  unlink $nfn if -f $nfn;
  delete $idb->{$id};
  my $ccode = 1;
  if ($_lockcnt == 1) {
    $ccode = savedb();
  }
  unlockdb();
  return $ccode;
}
# ======================================================================== sdbfn

sub sdbfn {
  my $cfg = TTXData::get('CONFIG');
  my $dn = $cfg->get('basedir').'/inventory';
  my $fn = "$dn/states.cgi";
  if (! -d $dn) {
    if (!mkdir($dn, 0777)) {
      $lasterror = "Failed to create inventory database directory";
      return undef;
    }
  }
  if (! -f $fn) {
    open(IDB, ">$fn");
    close(IDB);
    if (! -f $fn) {
      $lasterror = "Failed to create status database";
      return undef;
    }
  }
  return $fn;
}
# =================================================================== line2state

sub line2state {
  chomp($_[0]);
  my @fields = split(/\|/, TTXCommon::decodeit($_[0]));
  my %state;
  foreach my $key (@statefields) {
    $state{$key} = shift @fields;
    $state{key} =~ s/^\s+//;
    $state{key} =~ s/\s+$//;
  }
  return %state;
}
# =================================================================== state2line

sub state2line {
  my $state = $_[0];
  my @vals;
  foreach my $key (@statefields) {
    my $val = $state->{$key};
    $val =~ s/\|/!/g;
    push @vals, TTXCommon::encodeit($val);
  }
  return join('|', @vals);
}
# =================================================================== loadstates

sub loadstates {
  if ($states eq undef) {
    $states = {};
    my $fn = sdbfn();
    return undef if $fn eq undef;
    if (!open(SDB, $fn)) {
      $lasterror = "Failed to open status database file";
      return undef;
    }
    flock(SDB,2);
    for (my $line = <SDB>; $line ne undef; $line = <SDB>) {
      my %state = line2state($line);
      next if $state{id} !~ /^\d+$/;
      $states->{$state{id}} = \%state;
    }
    close(SDB);
  }
  return $states;
}
# ===================================================================== addstate

sub addstate {
  my $state = $_[0];
  my $fn = sdbfn();
  return undef if $fn eq undef;
  return undef if !lockdb();
  if (loadstates() eq undef) {
    unlockdb();
    return undef;
  }
  my @lst = sort {$a <=> $b } keys %{$states};
  my $cnt = int(@lst);
  if (!$cnt) {
    $state->{id} = 1;
  } else {
    $state->{id} = int($lst[$cnt - 1]) + 1;
  }
  if (!open(SDB, ">>$fn")) {
    $lasterror = "Failed to open status database file";
    unlockdb();
    return undef;
  }
  flock(SDB,2);
  seek(SDB,0,2);
  print SDB state2line($state)."\n";
  close(SDB);
  unlockdb();
  $states->{$state->{id}} = $state;
  return $state->{id};
}
# =================================================================== savestates

sub savestates {
  return 1 if $states eq undef;
  my $fn = sdbfn();
  return 0 if $fn eq undef;
  return 0 if !lockdb();
  if (!open(SDB, ">$fn")) {
    $lasterror = "Failed to open status database file";
    unlockdb();
    return 0;
  }
  flock(SDB,2);
  foreach my $id (sort {$a <=> $b} keys %{$states}) {
    next if $id !~ /^\d+$/;
    print SDB state2line($states->{$id})."\n";
  }
  close(SDB);
  unlockdb();
  return 1;
}
# ======================================================================== error

sub error {
  return $lasterror;
}
1;
#
