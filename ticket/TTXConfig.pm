package TTXConfig;
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

$TTXConfig::VERSION='2.24';

BEGIN {
  $TTXConfig::REVISION = '$Revision: 435 $';
  if ($TTXConfig::REVISION =~ /(\d+)/) {
    $TTXConfig::REVISION = $1;
  }
};

use strict;

my %errmsgs = (
  NOFILENAME => 'Missing file name',
  NOFILE => 'File does not exist',
  OPENERR => 'Error reading file',
  WRERR => 'Error writing file'
);
my %defaults = (
  userdb => 'users.cgi',
  ticketdb => 'tickets.cgi',
  ticketid => 'ticketid.txt'
);
# ========================================================================== new

sub new {
  my $class = shift;
  my $self = {};
  bless($self, $class);
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
  $value =~ s/\n//g;
  my $old = $self->{$name};
  $self->{$name} = $value;
  return $old
}
# ========================================================================= load

sub load {
  my $self = shift;
  my $fname = shift;
  if ($fname eq undef) {
    $self->{_ERROR_CODE} = 'NOFNAME';
    return 0;
  }
  if (! -f $fname) {
    $self->{_ERROR_CODE} = 'NOFILE';
    return 0;
  }
  if (!open(CFG, $fname)) {
    $self->{_ERROR_CODE} = 'OPENERR';
    return 0;
  }
  my @buff = <CFG>;
  close CFG;
  chomp @buff;
  foreach my $line (@buff) {
    $line =~ s/^\s+//;
    $line =~ s/\s+$//;
    my @parts = split(/=/, $line);
    my $name = shift @parts;
    my $value = join('=', @parts);
    $name =~ s/\s+$//;
    $value =~ s/^\s+//;
    $value =~ /(.*)/;
    $self->{$name} = $1;
  }
  $fname =~ /(.*)/;
  $self->{_CFG_FILE} = $1;
  return 1;
}
# ========================================================================= save

sub save {
  my $self = shift;
  if ($self->{_CFG_FILE} eq undef) {
    $self->{_ERROR_CODE} = 'NOFNAME';
    return 0;
  }
  if ($self->{_CFG_FILE} eq undef) {
    $self->{_ERROR_CODE} = 'NOFILE';
    return 0;
  }
  foreach my $key (keys %defaults) {
    if ($self->{$key} eq undef) {
      $self->{$key} = $self->{basedir} . "/$defaults{$key}";
    }
  }
  $self->{imgurl} = '.' if $self->{imgurl} eq undef;
  my $cfgfn = $self->{_CFG_FILE};
  $cfgfn =~ /(.*)/; $cfgfn = $1;
  if (! -e $cfgfn) {
    if (open(CFG, ">$cfgfn")) {
      close CFG;
    }
  }
  if (!open(CFG, "+<$cfgfn")) {
    $self->{_ERROR_CODE} = 'WRERR';
    return 0;
  }
  flock CFG, 2;
  seek(CFG, 0, 0);
  my $vars = $self->ashash();
  foreach my $key (sort keys %{$vars}) {
    next if $key =~ /^_/;
    next if $vars->{$key} eq undef;
    print CFG "$key=".$vars->{$key}."\n";
  }
  truncate(CFG, tell(CFG));
  close CFG;
  umask(0);
  chmod(0777, $cfgfn);
  if ($self->{usecache}) {
    eval "use TTXCache";
    TTXCache::purge() if $@ eq undef;
  }
  return 1;
}
# ========================================================================= file

sub file {
  my $self = shift;
  return $self->{_CFG_FILE} if $_[0] eq undef;
  my $fn = shift;
  my $old = $self->{_CFG_FILE};
  $self->{_CFG_FILE} = $fn;
  return $old
}
# ======================================================================== error

sub error {
  my $self = shift;
  return $self->{_ERROR_CODE};
}
# ==================================================================== errortext

sub errortext {
  my $self = shift;
  return $errmsgs{$self->{_ERROR_CODE}}." [config]";
}
# ========================================================================= vars

sub vars {
  my $self = shift;
  my @list;
  foreach my $key (sort keys %$self) {
    next if $key =~ /^_/;
    @list = (@list, $key);
  }
  return @list;
}
# ======================================================================= ashash

sub ashash {
  my $self = shift;
  my $hash = {};
  foreach my $key (keys %{$self}) {
    $hash->{$key} = $self->{$key};
  }
  return $hash;
}

1;
#
