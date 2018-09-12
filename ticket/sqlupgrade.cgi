#!/usr/bin/perl
#
# This script is a part of
# Trouble Ticket Express package.
# http://www.troubleticketexpress.com
#
# COPYRIGHT: 2002-2007, United Web Coders
# http://www.unitedwebcoders.com
#
# $Revision: 397 $
# $Date: 2007-08-31 11:31:32 +0400 (Fri, 31 Aug 2007) $
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
my $version = '2.21';
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
  } elsif($cfg->get('dbschema') > 2.18) {
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
      if ($modver < 2.19) {
        stop("<b>Please install latest (2.19) version of TTXMySQLTickets.pm<br><br>\n".
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
      if ($modver < 2.19) {
        stop("<b>Please install latest (2.19) version of TTXMSSQLTickets.pm<br><br>\n".
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
  my $msgtable = TTXCommon::cleanit($query, 'dbmessages');
  $msgtable = $cfg->get('dbmessages') if $msgtable eq undef;
  $msgtable = $cfg->get('dbpref').'messages' if $msgtable eq undef;
  $msgtable =~ /^([a-zA-Z][a-zA-Z0-9_]+)$/;
  my $tmp = $1;
  if ($tmp eq undef) {
   setup1($cfg, $query, "Invalid table name: $tmp");
   return;
  }
  $msgtable = $tmp;
  if (texists($cfg, $dbh, $msgtable)) {
    if (!isttxtable($cfg, $dbh, $msgtable)) {
      setup1($cfg, $query, "Table <i>$msgtable</i> exist");
      return;
    }
    if (!$dbh->do("DROP TABLE $msgtable")) {
      stop("Fatal error: Unable to delete table $msgtable, ".$dbh->errstr);
      return;
    }
  }
  my $sql = "CREATE TABLE $msgtable (\n";
  if ($cfg->get('dbmode') eq 'mysql') {
    $sql .= "MID BIGINT UNIQUE AUTO_INCREMENT NOT NULL PRIMARY KEY,\n";
  } else {
    $sql .= "MID BIGINT IDENTITY PRIMARY KEY,\n";
  }
  $sql .= <<EOT;
  TID BIGINT NOT NULL DEFAULT '0',
  AUTHOR VARCHAR(32)  DEFAULT '' NOT NULL ,
  DATE DATETIME  DEFAULT '0000-00-00 00:00:00' NOT NULL ,
  INTERNAL CHAR(1)  DEFAULT '0' NOT NULL ,
  ISOPER CHAR(1)  DEFAULT '0' NOT NULL ,
  HEADERS TEXT  DEFAULT '' NOT NULL ,
  MSG TEXT  DEFAULT '' NOT NULL
EOT
  if ($cfg->get('dbmode') eq 'mysql') {
    $sql .= ",\nKEY TID (TID)";
  }
  $sql .= "\n)";
  if (!$dbh->do($sql)) {
    setup1($cfg, $query, "Unable to create table $msgtable, ".$dbh->errstr);
    return;
  }
  if ($cfg->get('dbmode') eq 'mssql') {
    $dbh->do("CREATE INDEX TID ON $msgtable (TID)");
  }
  if ($msgtable ne $cfg->get('dbpref').'messages') {
    $cfg->set('dbmessages', $msgtable);
    $cfg->save();
  }
  #
  # Stop Trouble Ticket Express
  #
  my $tm = time();
  $cfg->set('dbupdate', $tm);
  $cfg->save();
  my $cnt = 0;
  my $sth = $dbh->prepare('SELECT ID FROM '.$cfg->get('dbpref').'tickets');
  if ($sth eq undef) {
    stop("Fatal error: Unable to build SQL statement, ".$dbh->errstr);
    return;
  }
  if (!$sth->execute()) {
    stop("Fatal error: Unable to query tickets table, ".$dbh->errstr);
    return;
  }
  $| = 1;
  my $boundary = $tickets->_boundary();
  my @tiklist;
  for (my @row = $sth->fetchrow_array(); @row; @row = $sth->fetchrow_array()) {
    my $t = time();
    if (($t - $tm) > 10) {
      $tm = $t;
      $cfg->set('dbupdate', $tm);
      $cfg->save();
      print "\n";  # keep browser connection alive
    }
    push @tiklist, $row[0];
  }
  $sth->finish();
  foreach my $id (@tiklist) {
    my $t = time();
    if (($t - $tm) > 10) {
      $tm = $t;
      $cfg->set('dbupdate', $tm);
      $cfg->save();
    }
    print "\n";  # keep browser connection alive
    $sth = $dbh->prepare('SELECT MSG FROM '.$cfg->get('dbpref')."tickets WHERE ID='$id'");
    if ($sth eq undef) {
      stop("Fatal error: Unable to build SQL statement, ".$dbh->errstr);
      return;
    }
    if (!$sth->execute()) {
      stop("Fatal error: Unable to query tickets table, ".$dbh->errstr);
      return;
    }
    my @row = $sth->fetchrow_array();
    $sth->finish();
    my @messages = split(/\n$boundary\n/, $row[0]);
    foreach my $msg (@messages) {
      my @msgparts = split(/\n\n/, $msg);
      my $rawheader = shift @msgparts;
      my $body = join("\n\n", @msgparts);
      my @headerlines = split(/\n/, $rawheader);
      chomp @headerlines;
      my %header;
      foreach my $line (@headerlines) {
        if ($line =~ /^([a-zA-Z][a-zA-Z0-9-]*):\s*(.*)$/) {
          $header{uc $1} = $2;
        }
      }
      my $author = $header{FROM};
      my $date = gmt($header{DATE});
      my $internal = $header{INTERNAL} ? '1':'0';
      my $isoper = $header{OPERATOR} ? '1':'0';
      $rawheader = '';
      foreach my $hdrkey (sort keys %header) {
        next if grep(/^$hdrkey$/, ('FROM', 'DATE', 'INTERNAL', 'BODY', 'OPERATOR'));
        $rawheader .= "$hdrkey: $header{$hdrkey}\n";
      }
      if (!$dbh->do("INSERT INTO $msgtable (TID, AUTHOR, DATE, ISOPER, INTERNAL, HEADERS, MSG) VALUES ".
                    "('$id',".$dbh->quote(substr($author,0,32)).",'$date','$isoper','$internal',".
                    $dbh->quote($rawheader).','.$dbh->quote($body).')')) {
        $cfg->set('dbupdate', '');
        $cfg->save();
        stop("Fatal error: Unable to insert message record, ".$dbh->errstr);
        return;
      }
    }
  }
  $cfg->set('dbupdate', '');
  $cfg->set('dbschema', '2.19');
  $cfg->save();
  print <<EOT;
<center>
<br>
<table width=500>
<tr>
<td align=center>
Your database has been upgraded.
<br><br>
The full text search feature is availble now.
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
    my $msgtable = TTXCommon::cleanit($query, 'dbmessages');
    my $qmtbl = $msgtable;
    $msgtable = $cfg->get('dbmessages') if $msgtable eq undef;
    $msgtable = $cfg->get('dbpref').'messages' if $msgtable eq undef;
    $msgtable =~ /^([a-zA-Z][a-zA-Z0-9_]+)$/;
    my $tmp = $1;
    if ($tmp eq undef) {
      $msg .= "\nInvalid table name: $tmp";
    }
    $msgtable = $tmp;
    print <<EOT;
<center>
<br>
<table width=500>
<tr>
<td align=left>
In order to support full text search feature introduced in rel 2.19 your database
needs to be upgraded. The upgrade will not affect existing data. The upgrade script
will do the following:
<br><br>
1) A new table will be created. The table will store all messages
(each trouble ticket consists of one or more messages).
<br><br>
2) Existing messages will be copied into the new table. This will not
destroy your existing data.
<br><br>
<b>IMPORTANT</b> During upgrade process the Trouble Ticket Express
will not be available. It will show the following message: "The help desk system
is temporary unavailable due to scheduled maintenance. We will resume operations
within next 5 minutes."
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
    if (texists($cfg, $dbh, $msgtable) && !isttxtable($cfg, $dbh, $msgtable)) {
        print <<EOT;
<tr>
<td align=left>
Please specify name of the table to use for storing messages. The name must be a valid table name
(please refer to your database server manuals for a definition of valid table names) and the
table may not exist.<br><br>
<b>Message table:</b> <input type=text name=dbmessages value="$qmtbl">
</td>
</tr>
EOT
    }
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
#======================================================================= texists

sub texists {
  my ($cfg, $dbh, $msgtable) = @_;
  my $sth;
  if ($cfg->get('dbmode') eq 'mysql') {
    $sth = $dbh->prepare('SHOW TABLES LIKE '.$dbh->quote($msgtable));
  } else {
    $sth = $dbh->prepare('EXECUTE sp_tables '.$dbh->quote($msgtable));
  }
  $sth->execute();
  my @row = $sth->fetchrow_array();
  return (@row > 0) ? 1:0;
}
# =================================================================== isttxtable

sub isttxtable {
  my ($cfg, $dbh, $msgtable) = @_;
  my $sth;
  my @musthave = ('MID', 'TID', 'AUTHOR', 'INTERNAL', 'DATE', 'ISOPER', 'MSG');
  if ($cfg->get('dbmode') eq 'mysql') {
    $sth = $dbh->prepare("DESCRIBE $msgtable");
  } else {
    $sth = $dbh->prepare("SELECT COLUMN_NAME FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = '$msgtable'");
  }
  $sth->execute();
  my $hitcnt = 0;
  for (my @row = $sth->fetchrow_array(); @row; @row = $sth->fetchrow_array()) {
    my $id = $row[0];
    if (grep(/^$id$/i, @musthave)) { ++$hitcnt; }
    else { return 0; }
  }
  return ($hitcnt == int @musthave) ? 1:0;
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
