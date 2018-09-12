#!/usr/bin/perl
#
# This script is a part of
# Trouble Ticket Express package.
# http://www.troubleticketexpress.com
#
# COPYRIGHT: 2002-2006, United Web Coders
# http://www.unitedwebcoders.com
#
# $Revision: 330 $
# $Date: 2007-03-27 18:37:43 +0400 (Tue, 27 Mar 2007) $
#

my $configfile;

# ==== NOTHING TO EDIT BELOW THIS LINE. PLS DO NOT CROSS =======================


BEGIN {
  if ($^O eq 'MSWin32') {
    eval "use FindBin";
    eval "use lib $FindBin::Bin";
    chdir($FindBin::Bin);
  }
}

use strict;
use CGI;
use TTXConfig;
use TTXCommon;
use TTXData;

#
# Global vars
#
my $cfg;
my $query;
my $version = '2.22';
my %data;
print "HTTP/1.0 200 OK\n" if $ENV{PERLXS} eq "PerlIS";
print "Content-type: text/html\n\n";
header();
#
# Read config
#
if ($configfile eq undef) {
  $configfile = 'ttxcfg.cgi';
  my $sd = scriptdir();
  $configfile = "$sd/ttxcfg.cgi" if $sd ne undef;
}
$cfg = TTXConfig->new($configfile);
runsetup() if $cfg eq undef || $cfg->error() ne undef;
if ($cfg->get('cfgref') ne undef) {
  my $regcfg = TTXConfig->new($cfg->get('cfgref'));
  $cfg = $regcfg;
  runsetup() if $cfg->error() ne undef;
}
TTXData::set('CONFIG', $cfg);
#
# Parse input
#
$query = new CGI;
#
# Validate user if id provided
#
if ($query->param('pwd') ne undef) {
   if ($cfg->get('admpwd') ne $query->param('pwd')) {
     login();
   }
} elsif ($cfg->get('admpwd') ne undef) {
  login();
} else {
  runsetup(); # Just to make sure.
}
#
# Execute command
#
my $cmd = $query->param('cmd');
$cmd = 'setup1' if $cmd eq undef;
if ($cmd eq 'setup1') {
  setup1($cfg, $query);
} elsif ($cmd eq 'setup2') {
  setup2($cfg, $query);
} elsif ($cmd eq 'login') {
  dologin();
}

footer();

#========================================================================== stop

sub stop {
  print <<EOT;
<center>
<br>
<table width=500>
<tr>
<td align=left>
$_[0]
</tr>
</td>
</table>
</center>
EOT
}
#===================================================================== foolproof

sub foolproof {
  my ($cfg) = @_;
  my $dbmode = $cfg->get('dbmode');
  if ($dbmode !~ /sql/) {
    stop("SQL mode is not activated yet. Please use".
         " either <a href=\"sqlsetup.cgi\"><b><nobr>MySQL setup</nobr></b><a> or".
         " <a href=\"mssqlsetup.cgi\"><b><nobr>SQL Server setup</nobr></b><a> utility".
         " to configure SQL mode.");
  } elsif($cfg->get('dbschema') < 2.19) {
    stop("Please use this <a href=\"sqlupgrade.cgi\">upgrade script</a> first.");
  } elsif($cfg->get('dbschema') >= 2.22) {
    stop("You have already upgraded your database");
  } else {
    #
    # Check if updated SQL module installed
    #
    if ($cfg->get('dbmode') eq 'mysql') {
      eval "use TTXMySQLTickets";
      if ($@ ne undef) {
        stop("<b>Error loading TTXMySQLTickets, $@</b>");
        return 0;
      }
      my $modver;
      eval '$modver = $TTXMySQLTickets::VERSION';
      if ($@ ne undef) {
        stop("<b>Error querying TTXMySQLTickets, $@</b>");
        return 0;
      }
      if ($modver < 2.22) {
        stop("<b>Please install latest (2.22) version of TTXMySQLTickets.pm<br><br>\n".
             "<center><a href=\"http://www.troubleticketexpress.com/mysql.html\">Order/Download instructions</a></center></b>");
        return 0;
      }
    } else {
      eval "use TTXMSSQLTickets";
      if ($@ ne undef) {
        stop("<b>Error loading TTXMSSQLTickets, $@</b>");
        return 0;
      }
      my $modver;
      eval '$modver = $TTXMSSQLTickets::VERSION';
      if ($@ ne undef) {
        stop("<b>Error querying TTXMSSQLTickets, $@</b>");
        return 0;
      }
      if ($modver < 2.22) {
        stop("<b>Please install latest (2.22) version of TTXMSSQLTickets.pm<br><br>\n".
             "<center><a href=\"http://www.troubleticketexpress.com/mssql.html\">Order/Download instructions</a></center></b>");
        return 0;
      }
    }
    return 1;
  }
  return 0;
}
#======================================================================== setup2

sub setup2 {
  my ($cfg, $query, $msg) = @_;
  my $pwd = TTXCommon::cleanit($query, 'pwd');
  return if !foolproof($cfg);
  my $tickets = TTXCommon::dbtik();
  if ($tickets eq undef) {
    stop("Fatal error: can't access tickets database");
    return;
  }
  my $dbh = $tickets->{DBH};
  if ($dbh eq undef) {
    stop("Fatal error: can't obtain database handle");
    return;
  }
  my $table = $cfg->get('dbpref').'tickets';
  my $cnt = int ($cfg->get('cfldcnt'));
  my $itemidx = ($cnt > 10) ? $cnt:10;
  my $sql;
  if ($cfg->get('dbmode') eq 'mysql') {
    $sql = "ALTER TABLE $table ADD COLUMN ITEM varchar(255) DEFAULT '' NOT NULL";
  } else {
    $sql = "ALTER TABLE $table ADD ITEM varchar(255) DEFAULT '' NOT NULL";
  }
  if (!$dbh->do($sql)) {
    setup1($cfg, $query, "Unable to upgrade table $table, ".$dbh->errstr);
    return;
  }
  $cfg->set('itemidx', $itemidx);
  $cfg->set('dbschema', '2.22');
  $cfg->save();
  print <<EOT;
<center>
<br>
<table width=500>
<tr>
<td align=center>
Your database has been upgraded.
<br><br>
The database supports Inventory Module now.
<br><br>
<a href="ttx.cgi?cmd=login"><b>Login to Trouble Ticket Express</b></a>
</td>
</tr>
</table>
EOT
}
# ========================================================================== gmt

sub gmt {
  my $tm;
  if ($_[0] ne undef) { $tm = $_[0]; }
  else                { $tm = time(); }
  my ($s, $min, $h, $d, $m, $y) = (gmtime($tm));
  $y += 1900;
  ++$m;
  $m = "0$m" if $m < 10;
  $d = "0$d" if $d < 10;
  $h = "0$h" if $h < 10;
  $min = "0$min" if $min < 10;
  $s = "0$s" if $s < 10;
  return  "$y-$m-$d $h:$min:$s";
}
#======================================================================== setup1

sub setup1 {
  my ($cfg, $query, $msg) = @_;
  my $pwd = TTXCommon::cleanit($query, 'pwd');
  if (foolproof($cfg)) {
    my $tickets = TTXCommon::dbtik();
    if ($tickets eq undef) {
      stop("Fatal error: can't access tickets database");
      return;
    }
    my $dbh = $tickets->{DBH};
    if ($dbh eq undef) {
      stop("Fatal error: can't obtain database handle");
      return;
    }
    print <<EOT;
<center>
<br>
<table width=500>
<tr>
<td align=left>
In order to support Inventory Module introduced in rel 2.22 your database
needs to be upgraded. The upgrade will not affect existing data. The upgrade script
will do the following:
<br><br>
1) A new column 'ITEMS' will be added to the tickets table.
</td>
</tr>
</table>
EOT
    if ($msg ne undef) {
      print <<EOT;
<br>
<table width=500>
<tr>
<td align=center>
<b><font color=red>$msg</font></b>
</td>
</tr>
</table>
EOT
    }
    print <<EOT;
<br>
<form action="$ENV{SCRIPT_NAME}" method=post>
<input type=hidden name=cmd value=setup2>
<input type=hidden name=pwd value=$pwd>
<table width=500>
EOT
    print <<EOT;
<tr>
<td align=center>
<input type=submit value="Upgrade database">
</form>
</td>
</tr>
</table>
EOT
  }
}
#======================================================================= dologin

sub dologin {
  my $error;
  if ($query->param('do')) {
    if ($query->param('passwd') eq undef || $query->param('passwd') ne $cfg->get('admpwd')) {
      $error = "Invalid password";
    } else {
      $query->param(-name => 'pwd', -value => $query->param('passwd'));
      $query->param(-name => 'do', -value => '');
      setup1($cfg, $query);
      return;
    }
  }
  $error = "<br><font color=red><b>Error: $error</b></font><br><br>" if $error ne undef;
  print <<EOT;
<center><b>Please login</b>
<br><br>$error
<table cellpadding=3>
<form action=$ENV{SCRIPT_NAME} method=post>
<input type=hidden name=cmd value=login>
<input type=hidden name=do value=1>
<tr>
<td align=left class=lbl>Administrator password</td>
<td align=left><input type=password name=passwd></td>
</tr>
<tr>
<td colspan=2 align=right>
<input type=submit>
</td>
</tr>
</form>
</table>
</center>
EOT
}
#========================================================================= login

sub login {
  $query->param(-name => 'pwd', -value => '');
  $query->param(-name => 'cmd', -value => 'login');
}

#====================================================================== runsetup

sub runsetup {
  print <<EOT;
<html>
<head><title>Trouble Ticket Express</title></head>
<body>
<br><br><center>
<b><font color=red>Error reading configuration file.</font></b>
<br><br>
Please execute <a href=setup.cgi><b>Main Setup Utility</b></a> first.
</center>
</body>
</html>
EOT
  exit;
}
#==================================================================== fatalerror

sub fatalerror {
  print <<EOT;
<html>
<head><title>Trouble Ticket Express</title></head>
<body>
<br><center><h1>Fatal Error: $_[0]</h1>
</body>
</html>
EOT
  exit;
}

sub header {
  print <<EOT;
<html>
<head>
<title>
Trouble Ticket Express - Database upgrade
</title>
<style type="text/css">
body, td { font-family: Verdana, Helvetica, sans-serif; font-size: 10pt;}
A       { color : #2E3197; text-decoration : none; }
A:Hover { color : #C00; text-decoration : underline;}
.sm {font-size: 8pt;}
.tiny {font-size: 4pt;}
.heading {font-size: 13pt;font-weight: 700; color: #2E3197;}
.lbl {font-size: 9pt;font-weight: 700;}
</style>
</head>
<body>
<center>
<table width=700>
<tr>
<td align=left>
EOT
}
# ======================================================================= footer

sub footer {
print <<EOT;
</td></tr>
</table>
<br><br>
rev. $version
</center>
</body>
</html>
EOT
# ==================================================================== scriptdir

sub scriptdir {
  my $dir = $ENV{'SCRIPT_FILENAME'};
  $dir = $ENV{'PATH_TRANSLATED'} if $ENV{'PATH_TRANSLATED'} ne undef;
  $dir = $ENV{'pathTranslated'} if $ENV{'pathTranslated'} ne undef;
  return $ENV{'PWD'} if $dir eq undef;
  my @path = split(/\/|\\/, $dir);
  pop(@path);
  $dir = join("\/", @path);
  return $dir;
}

}

