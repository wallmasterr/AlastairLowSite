package TTXTickets;
#
# This module is a part of Trouble Ticket Express package
# http://www.troubleticketexpress.com
#
# COPYRIGHT: 2002-2007, United Web Coders
# http://www.unitedwebcoders.com
#
# $Revision: 443 $
# $Date: 2007-10-11 16:27:57 +0400 (Thu, 11 Oct 2007) $
#

$TTXTickets::VERSION='2.24';
BEGIN {
  $TTXTickets::REVISION = '$Revision: 443 $';
  if ($TTXTickets::REVISION =~ /(\d+)/) {
    $TTXTickets::REVISION = $1;
  }
};
use strict;
use TTXData;

my @tickfields = ('id', 'key', 'open', 'updated', 'closed', 'status', 'oper', 'email', 'name', 'subject',
                  'lname', 'c0', 'c1', 'c2', 'c3', 'c4', 'c5', 'c6', 'c7', 'c8', 'c9','grp');
my $fldsexpanded = 0;
my $boundary = '-----------asdjhfKJS12869nmboiu7826318---';

# ====================================================================== _fields

sub _fields {
  if (!$fldsexpanded) {
    my $cfg = TTXData::get('CONFIG');
    if ($cfg ne undef) {
      my $cnt = int ($cfg->get('cfldcnt'));
      if (!$cfg->get('itemidx')) {
        $cfg->set('itemidx', ($cnt > 10) ? $cnt:10);
        $cfg->save();
      }
      if ($cnt > 10) {
        for (my $i = 10; $i < $cnt; ++$i) {
          push @tickfields, 'item' if $i eq $cfg->get('itemidx');
          push @tickfields, "c$i";
        }
        push @tickfields, 'item' if $cnt eq $cfg->get('itemidx');
      } else {
        push @tickfields, 'item';
      }
      $fldsexpanded = 1;
    }
  }
  return @tickfields;
}
# ==================================================================== _boundary

sub _boundary {
  return $boundary;
}
# ========================================================================== new

sub new {
  my $class = shift;
  my $self = {};
  bless($self, $class);
  return $self;
}
# ========================================================================= save

sub save {
  warn 'Pure virtual method TTXTickets::save() called';
  return 0;
}
# ======================================================================= deltik

sub deltik {
  warn 'Pure virtual method TTXTickets::deltik() called';
}
# ================================================================== ticketbykey

sub ticketbykey {
  warn 'Pure virtual method TTXTickets::ticketbykey() called';
  return undef;
}
# ======================================================================= ticket

sub ticket {
  warn 'Pure virtual method TTXTickets::ticket() called';
  return undef;
}
# ==================================================================== addticket

sub addticket {
  warn 'Pure virtual method TTXTickets::addticket() called';
  return 0;
}
# ========================================================================= list

sub list {
  warn 'Pure virtual method TTXTickets::list() called';
  my $browser;
  return $browser;
}
# ==================================================================== errortext

sub errortext {
  warn "Pure virtual method TTXTickets::errortext() called";
  return 'Pure virtual method TTXTickets::errortext() called';
}
# ======================================================================== error

sub error {
  my $self = shift;
  return $self->{_ERROR_CODE};
}
# ====================================================================== raw2msg

sub raw2msg {
  my $msg = {};
  my @msgparts = split(/\n\n/, $_[0]);
  my $rawheader = shift @msgparts;
  $msg->{BODY} = join("\n\n", @msgparts);
  my @headerlines = split(/\n/, $rawheader);
  chomp @headerlines;
  foreach my $line (@headerlines) {
    if ($line =~ /^([a-zA-Z][a-zA-Z0-9-]*):\s*(.*)$/) {
      $msg->{uc $1} = $2;
    }
  }
  return $msg;
}

1;
#
