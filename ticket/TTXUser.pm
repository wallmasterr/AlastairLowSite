package TTXUser;
#
# This module is a part of Trouble Ticket Express package
# http://www.troubleticketexpress.com
#
# COPYRIGHT: 2003-2007, United Web Coders
# http://www.unitedwebcoders.com
#
# $Revision: 452 $
# $Date: 2007-11-05 08:00:58 +0300 (Mon, 05 Nov 2007) $
#

$TTXUser::VERSION='2.24';
BEGIN {
  $TTXUser::REVISION = '$Revision: 452 $';
  if ($TTXUser::REVISION =~ /(\d+)/) {
    $TTXUser::REVISION = $1;
  }
};
use strict;
use TTXData;
use TTXCommon;

my %errmsgs = (
  NOUSER => 'User does not exist',
  OPENERR => 'Error reading file',
  WRERR => 'Error writing file'
);

my $delim;
my $redelim;

# ========================================================================== new

sub new {
  my $class = shift;
  my $self = {};
  bless($self, $class);
  $delim = TTXData::get('CONFIG')->get('delim');
  $delim = ':' if $delim eq undef;
  if ($delim eq '|') {
    $redelim = '\|';
  } else {
    $redelim = $delim;
  }
  if ($_[0] ne undef) {
    $self->load($_[0]);
  }
  return $self;
}
# ========================================================================== get

sub get {
  my $self = shift;
  my $name = shift;
  return $self->{$name};
}
# ========================================================================== set

sub set {
  my $self = shift;
  my $name = shift;
  my $value = shift;
  my $old = $self->{$name};
  $self->{$name} = $value;
  return $old
}
# ==================================================================== listemail

sub listemail {
  $delim = TTXData::get('CONFIG')->get('delim');
  $delim = ':' if $delim eq undef;
  if ($delim eq '|') {
    $redelim = '\|';
  } else {
    $redelim = $delim;
  }
  my $fn = TTXData::get('CONFIG')->get('userdb');
  if (! -f $fn) {
    return undef;
  }
  if (!open(USRDB, $fn)) {
    return undef;
  }
  my @buff = <USRDB>;
  close USRDB;
  chomp @buff;
  my @list;
  foreach my $line (@buff) {
    my @parts = split(/$redelim/, $line);
    push @list, $parts[4];
  }
  return @list;
}
# ========================================================================= list

sub list {
  $delim = TTXData::get('CONFIG')->get('delim');
  $delim = ':' if $delim eq undef;
  if ($delim eq '|') {
    $redelim = '\|';
  } else {
    $redelim = $delim;
  }
  my $fn = TTXData::get('CONFIG')->get('userdb');
  if (! -f $fn) {
    return undef;
  }
  if (!open(USRDB, $fn)) {
    return undef;
  }
  my @buff = <USRDB>;
  close USRDB;
  chomp @buff;
  my @list;
  foreach my $line (@buff) {
    next if length($line) < 5;
    $line =~ s/$redelim.*$//;
    push @list, $line;
  }
  return @list;
}
# ===================================================================== userbysn

sub userbysn {
  my $sn = shift;
  my @lst = list();
  foreach my $uid (@lst) {
    my $u = TTXUser->new($uid);
    next if $u eq undef || $u->{snum} ne $sn;
    return $u;
  }
  return undef;
}
# ========================================================================= load

sub load {
  my $self  = shift;
  my $login = shift;
  my $cfg = TTXData::get('CONFIG');
  my $fn = $cfg->get('userdb');
  if (! -f $fn) {
    $self->{_ERROR_CODE} = 'NOUSER';
    return 0;
  }
  if (!open(USRDB, $fn)) {
    $self->{_ERROR_CODE} = 'OPENERR';
    return 0;
  }
  my @buff = <USRDB>;
  close USRDB;
  chomp @buff;
  my $relogin = $login;
  $relogin =~ s/\./\\./g;
  foreach my $line (@buff) {
    next if $line !~ /^$relogin$redelim/;
    my ($login, $passwd, $fname, $lname, $email, $image, $usemail, $snum, $ro, $sla, $wrkh, $dt, $tr, $me) =
      split(/$redelim/, TTXCommon::decodeit($line));
    $self->{login} = $login;
    $self->{passwd} = $passwd;
    $self->{fname} = $fname;
    $self->{lname} = $lname;
    $self->{email} = $email;
    $self->{image} = $image;
    $self->{usemail} = $usemail;
    $self->{ro} = $ro;
    $self->{snum} = $snum;
    $self->{sla} = $sla;
    $self->{wrkh} = $wrkh;
    $self->{dt} = $dt;
    if ($cfg->get('grant.delete') ne undef) {
      if (grep(/^$relogin$/, split(/,/, $cfg->get('grant.delete')))) {
        $self->{dt} = 1;
      }
    }
    $self->{tr} = $tr;
    if ($cfg->get('grant.assign') ne undef) {
      if (grep(/^$relogin$/, split(/,/, $cfg->get('grant.assign')))) {
        $self->{tr} = 1;
      }
    }
    $self->{me} = $me;
    if ($cfg->get('grant.edit') ne undef) {
      if (grep(/^$relogin$/, split(/,/, $cfg->get('grant.edit')))) {
        $self->{me} = 1;
      }
    }
    return 1;
  }
  $self->{_ERROR_CODE} = 'NOUSER';
  return 0;
}
# ==================================================================== errortext

sub errortext {
  my $self = shift;
  return $errmsgs{$self->{_ERROR_CODE}};
}
# ======================================================================= delete

sub delete {
  my $self  = shift;
  my $fn = TTXData::get('CONFIG')->get('userdb');
  if (! -f $fn || $self->{login} eq undef) {
    $self->{_ERROR_CODE} = 'NOUSER';
    return 0;
  }
  if (open(USRDB,"+<$fn")) {
    flock(USRDB, 2);
    my @users = <USRDB>;
    my $id = $self->{login};
    $id =~ s/\./\\./g;
    @users = grep(!/^$id$redelim/, @users);
    seek(USRDB, 0, 0);
    foreach (@users) { print USRDB $_; }
    truncate(USRDB, tell(USRDB));
    close(USRDB);
  } else {
    $self->{_ERROR_CODE} = 'WRERR';
    return 0;
  }
  return 1;
}
# ========================================================================= save

sub save {
  my $self  = shift;
  my $fn = TTXData::get('CONFIG')->get('userdb');
  if ($self->{login} eq undef) {
    $self->{_ERROR_CODE} = 'NOUSER';
    return 0;
  }
  if (! -f $fn) {
    open(USRDB, ">$fn");
    close USRDB;
    umask(0);
    chmod(0777, $fn);
  }
  if (open(USRDB,"+<$fn")) {
    flock(USRDB, 2);
    my @users = <USRDB>;
    my $id = TTXCommon::encodeit($self->{login});
    $id =~ s/\./\\./g;
    @users = grep(!/^$id$redelim/, @users);
    seek(USRDB, 0, 0);
    if ($delim eq ':') {
      TTXData::get('CONFIG')->set('delim', '|');
      TTXData::get('CONFIG')->save();
      $delim = '|';
      $redelim = '\|';
      foreach my $u (@users) {
        $u =~ s/:/|/g;
        if (length($u) > 5) {
          print USRDB $u;
        }
      }
    } else {
      foreach my $u (@users) {
        if (length($u) > 5) {
          print USRDB $u;
        }
      }
    }
    print USRDB TTXCommon::encodeit(join($delim, map($self->{$_},
          ('login', 'passwd', 'fname', 'lname', 'email', 'image',
           'usemail', 'snum', 'ro', 'sla', 'wrkh', 'dt', 'tr', 'me')))."\n");
    truncate(USRDB, tell(USRDB));
    close(USRDB);
  } else {
    $self->{_ERROR_CODE} = 'WRERR';
    return 0;
  }
  return 1;
}
# ========================================================================= hash

sub hash {
  my $self  = shift;
  my $h = {};
  foreach my $key ($self->vars()) {
    $h->{$key} = $self->{$key};
  }
  return $h;
}

1;
#
