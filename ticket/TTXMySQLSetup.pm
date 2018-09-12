package TTXMySQLSetup;
#
# This module is a part of Trouble Ticket Express package
# http://www.troubleticketexpress.com
#
# COPYRIGHT: 2002-2007, United Web Coders
# http://www.unitedwebcoders.com
#
# $Revision: 438 $
# $Date: 2007-10-11 16:23:42 +0400 (Thu, 11 Oct 2007) $
#

$TTXMySQLSetup::VERSION='2.24';
BEGIN {
  $TTXMySQLSetup::REVISION = '$Revision: 438 $';
  if ($TTXMySQLSetup::REVISION =~ /(\d+)/) {
    $TTXMySQLSetup::REVISION = $1;
  }
};

use TTXConfig;
require TTXUser;
require TTXTickets;
use strict;

my $cfg = {};
my $query = {};
my $newdb;
my $doimport;
my $pwd;

# ======================================================================= setup1

sub setup1 {
  $cfg = $_[0];
  $query = $_[1];
  my $error;
  $pwd = cleanit($query, 'pwd');
  my $dbid = cleanit($query, 'dbid') || $cfg->get('dbid');
  my $host = cleanit($query, 'host') || $cfg->get('dbhost') || 'localhost';
  my $port = cleanit($query, 'port') || $cfg->get('dbport') || 3306;
  my $user = cleanit($query, 'user') || $cfg->get('dbuser');
  my $pass = cleanit($query, 'pass') || $cfg->get('dbpass');
  my $prefix = cleanit($query, 'prefix');
  $prefix = $cfg->get('dbpref') if !$query->param('do');
  my $imgurl = $cfg->get('imgurl');
#
# Check if DBI module installed
#
  eval "use DBI";
  $error = "The DBI Perl library was not found on this server.<br>Please install DBI library prior to running this program." if $@;
#
# Check if MySQL DBD driver installed
#
  if ($error eq undef) {
    my @drivers = DBI->available_drivers(1);
    $error = "The MySQL DBD driver was not found on this server.<br>Please install MySQL DBD driver prior to running this program."
      if !grep(/mysql/, @drivers);
  }
  if ($error eq undef && $query->param('do')) {
    $cfg->set('dbid', $dbid);
    $cfg->set('dbhost', $host);
    $cfg->set('dbport', $port);
    $cfg->set('dbuser', $user);
    $cfg->set('dbpass', $pass);
    $cfg->set('dbpref', $prefix);
    $doimport = 1 if $cfg->get('dbmode') ne 'mysql';
    $error = build($cfg);
    if ($error eq undef) {
      eval "use TTXMySQLTickets";
      if ($@) {
        $cfg->set('dbmode', 'plaintext');
      } else {
        $cfg->set('dbmode', 'mysql');
        $cfg->set('dbschema', '2.22');
      }
      $cfg->save();
    }
  }
  if ($query->param('do') && $error eq undef ) {
    ok();
    return;
  }
  my $warning;
  if ($cfg->get('dbmode') eq 'mysql') {
    $warning = "YOU HAVE ALREADY ENABLED MYSQL MODE<br>\n".
              "THIS SCRIPT WILL RESET YOUR TICKETS DATABASE<br>\n".
              "ALL TICKETS SUBMITTED USING MYSQL MODE WILL BE LOST!";
  }
  $error = "<br><b><font color=red>Error: $error</font></b><br><br>" if $error ne undef;
  $warning = "\n<br><b><font color=red>$warning</font></b><br><br>" if $warning ne undef;
  print <<EOT;
<center><b>MySQL Module Setup</b><br>
<span class=sm>(go to <a href="setup.cgi?cmd=setup4&pwd=$pwd">Main Setup Utility</a> form)</span>
<br>$error$warning
<form action=$ENV{SCRIPT_NAME} method=post>
<input type=hidden name=cmd value=setup1>
<input type=hidden name=do value=1>
<input type=hidden name=pwd value=$pwd>
<table border=0 cellpadding=0 cellspacing=0>
<tr height=1><td colspan=2 align=center height=1 bgcolor="#9b9b9b"><img
src="$imgurl/dot.gif" height=1></td></tr>
<tr><td colspan=2><br>
MySQL database access info. Please contact your hosting provider or system admin if not sure.<br><br>
</td></tr>
<tr><td align=right><b>MySQL Host:</b></td><td>&nbsp;&nbsp;<input type=text name=host value="$host"></td></tr>
<tr><td align=right><b>MySQL Port:</b></td><td>&nbsp;&nbsp;<input type=text name=port value="$port"></td></tr>
<tr><td align=right><b>Database ID:</b></td><td>&nbsp;&nbsp;<input type=text name=dbid value="$dbid"></td></tr>
<tr><td align=right><b>MySQL User:</b></td><td>&nbsp;&nbsp;<input type=text name=user value="$user"></td></tr>
<tr><td align=right><b>MySQL Password:</b></td><td>&nbsp;&nbsp;<input type=password name=pass value="$pass"></td></tr>

<tr><td colspan=2 align=center>&nbsp;</td></tr>
<tr height=1><td colspan=2 align=center height=1 bgcolor="#9b9b9b"><img
src="$imgurl/dot.gif" height=1></td></tr>
<tr><td colspan=2><br>
If you have access to a single database or would like to use existing database, you may
provide a prefix, which will be added to the names of all the Trouble
Ticket Express tables.<br><br>
</td></tr>
<tr><td align=right><b>Table prefix</b> (optional)<b>:</b></td><td>&nbsp;&nbsp;<input type=text name=prefix value="$prefix"></td></tr>
<tr><td colspan=2 align=center>
<br><input type=submit value="Save Settings">
</td></tr>
</form>
</table>
<br>
<br>Login to <a href="ttx.cgi?cmd=login"><b>Trouble Ticket Express</b></a>
</center>
EOT
}
# =========================================================================== ok

sub ok {
  print "<center><table width=600><tr><td align=left><center><b>Congratulations!</b></center><br><br>\n";
  if ($newdb) {
    print "You have created Trouble Ticket Express database and imported existing tickets.\n"
  } elsif ($doimport) {
    print "You have imported existing tickets into Trouble Ticket Express database.\n"
  } else {
    print "You are proud owner of the Trouble Ticket Express MySQL Edition.\n".
    "Please do not run database setup utility unless you want to make changes to the database settings.\n"
  }
  print "<br><br>\n";
  if ($cfg->get('dbmode') ne 'mysql') {
    print <<EOT;
<b>IMPORTANT</b>
Trouble Ticket Express still uses plain text database.
Neither new tickets, nor follow-up messages to existing tickets will be added to the MySQL database.
In order to enable MySQL features you must install a MySQL add-on module to your web server.
The module may be ordered on-line at our web site. After uploading the MySQL add-on module to your web server,
please run this script once more - it will update your MySQL database to ensure it includes
recent data from your plain text database and will switch Trouble Ticket Express into MySQL mode.
<br><br>
<center>
<a href="http://www.troubleticketexpress.com/mysql.html"><b>Order MySQL add-on module</b></a>
</center>
<br><br>
EOT
  } else {
    print "Trouble Ticket Express now uses MySQL database.<br><br>\n";
  }
  print "<center><a href=\"setup.cgi?cmd=setup4&pwd=$pwd\"><b>Main Setup Utility</b></a><br>".
        "<a href=\"ttx.cgi?cmd=login\"><b>Trouble Ticket Express</b></a></center>\n";
  print "</td></tr></table></center>\n";
}
# ====================================================================== cleanit

sub cleanit {
  my ($query, $input) = @_;
  my $val = $query->param($input);
  $val =~ s/^\s+//;
  $val =~ s/\s+$//;
  $query->param(-name => $input, -value => $val);
  return $val;
}
# ======================================================================== build

sub build {
  my $cfg = $_[0];
  $newdb = 0;
  my @manda = ('dbid', 'dbuser', 'dbpass');
  my $id2name = {
    dbid => 'Database ID',
    dbuser => 'MySQL User ID',
    dbpass => 'MySQL User Password'
  };
  my $error;
  foreach my $fld (@manda) {
    my $val = $cfg->get($fld);
    if ($val eq undef) {
      $error .= "Missing ".$id2name->{$fld}."<br>\n";
    }
  }
#
# Step one - connect to mysql database engine
#
  my $dsn = "DBI:mysql:database=".$cfg->get('dbid').";host=".$cfg->get('dbhost').";port=".$cfg->get('dbport');
  my $dbh = DBI->connect($dsn, $cfg->get('dbuser'), $cfg->get('dbpass'),
                       {RaiseError => 0, AutoCommit => 1});
  if (!$dbh) {
# got to check as to why
    if ($DBI::err !~ /\b1049\b/) {
      $error = "Error connecting to a database. $DBI::errstr";
      return $error;
    } else {
# Well, we are allowed to connect but database does not exist.
# Will try to create...
      my $drh = DBI->install_driver('mysql');
      if (!$drh) {
        $error = "Error loading mysql DBD driver. $DBI::errstr";
        return $error;
      }
      my $rc = $drh->func('createdb',
                         $cfg->get('dbid'),
                         $cfg->get('dbhost'),
                         $cfg->get('dbuser'),
                         $cfg->get('dbpass'),
                         'admin');
      if (!$rc) {
        $error = "Failed to create database '".$cfg->get('dbid')."'";
        return $error;
      }
      $newdb = 1;
      $dbh = DBI->connect($dsn, $cfg->get('dbuser'), $cfg->get('dbpass'),
                       {RaiseError => 0, AutoCommit => 1});
      if (!$dbh) {
        $error = "Error connecting to a database. $DBI::errstr";
        return $error;
      }
    }
  }
#
# Still alive? Good. Try to create tables now.
#
  my $sth = $dbh->prepare("SHOW TABLES");
  $sth->execute();
  my %tables;
  while (my @row = $sth->fetchrow_array()) {
    $tables{$row[0]} = 1;
  }
  if (!$tables{$cfg->get('dbpref')."tickets"} && !$tables{$cfg->get('dbpref')."messages"}) {
    $doimport = 1;
  } elsif ($doimport) {
    $dbh->do("DROP TABLE ".$cfg->get('dbpref')."tickets") if $tables{$cfg->get('dbpref')."tickets"};
    $dbh->do("DROP TABLE ".$cfg->get('dbpref')."messages") if $tables{$cfg->get('dbpref')."messages"};
    $tables{$cfg->get('dbpref')."tickets"} = 0;
    $tables{$cfg->get('dbpref')."messages"} = 0;
  }
  foreach my $table ('tickets', 'messages') {
    if (!$tables{$cfg->get('dbpref').$table}) {
      $error = addtable($dbh, $cfg, $table);
      return $error if $error ne undef;
    }
  }
#
# Import data if needed
#
  if ($doimport) {
    my @tickfields = TTXTickets::_fields();
    my $boundary = TTXTickets::_boundary();
    my $fn = $cfg->get('ticketdb');
    return undef if ! -f $fn;
    return "Database import failed: error reading ticket database" if !open(DB, $fn);
    my @buff = <DB>;
    close DB;
    chomp @buff;
    $| = 1;
    $dbh->do("SET AUTOCOMMIT=0;");
    my $cmtcnt = 0;
    foreach my $line (@buff) {
      print "\n";
      ++$cmtcnt;
      if ($cmtcnt > 99) {
        $dbh->do("COMMIT;");
        $cmtcnt = 0;
      }
      my @fields = split(/\|/, $line);
      my %tik;
      my $sql = "INSERT IGNORE INTO ".$cfg->get('dbpref')."tickets VALUES(";
      my $values;
      foreach my $fld (@tickfields) {
        $tik{$fld} = TTXCommon::decodeit(shift @fields);
        $tik{$fld} = '' if $tik{$fld} eq undef;
        $values .= ',' if $values ne undef;
        if ($fld =~ /^(open|updated|closed)$/) {
          $values .= $dbh->quote(gmt($tik{$fld}));
        } else {
          $values .= TTXCommon::decodeit($dbh->quote($tik{$fld}));
        }
      }
      $sql .= "$values)";
      if (!$dbh->do($sql)) {
        $error = "Error importing ticket #"."$tik{id}. ".$dbh->errstr;
        last;
      }
      my $msgfn = $cfg->get('basedir')."/tickets/$tik{id}.cgi";
      if (-f $msgfn && open(MSG, $msgfn)) {
        my $rawmsg;
        read(MSG, $rawmsg, 64*1024);
        close MSG;
        my @messages = split(/\n$boundary\n/, $rawmsg);
        foreach my $msg (@messages) {
          my @msgparts = split(/\n\n/, TTXCommon::decodeit($msg));
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
          my $author = $header{FROM} || '-';
          my $date = gmt($header{DATE});
          my $internal = $header{INTERNAL} ? '1':'0';
          my $isoper = $header{OPERATOR} ? '1':'0';
          $rawheader = '';
          foreach my $hdrkey (sort keys %header) {
            next if grep(/^$hdrkey$/, ('FROM', 'DATE', 'INTERNAL', 'BODY', 'OPERATOR'));
            $rawheader .= "$hdrkey: $header{$hdrkey}\n";
          }
          if (!$dbh->do("INSERT IGNORE INTO ".$cfg->get('dbpref')."messages (TID, AUTHOR, DATE, ISOPER, INTERNAL, HEADERS, MSG) VALUES ".
                    "('$tik{id}',".TTXCommon::decodeit($dbh->quote($author)).",'$date','$isoper','$internal',".
                    TTXCommon::decodeit($dbh->quote($rawheader)).','.TTXCommon::decodeit($dbh->quote($body)).')')) {
            return "Error importing messages of ticket #"."$tik{id}. ".$dbh->errstr;
          }
        }
      }
    }
    $dbh->do("COMMIT");
  }
  return $error;
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
# ===================================================================== addtable

sub addtable {
  my ($dbh, $cfg, $table) = @_;
  my $tablename = $cfg->get('dbpref').$table;
  my $sql;
  if ($table eq 'tickets') {
    $sql = <<EOT;
CREATE TABLE $tablename (
  ID bigint(20)  DEFAULT '0' NOT NULL ,
  ACCESSKEY varchar(64)  DEFAULT '' NOT NULL ,
  OPEN datetime  DEFAULT '0000-00-00 00:00:00' NOT NULL ,
  UPDATED datetime  DEFAULT '0000-00-00 00:00:00' NOT NULL ,
  CLOSED datetime  DEFAULT '0000-00-00 00:00:00' NOT NULL ,
  STATUS char(3)  DEFAULT '' NOT NULL ,
  OPER varchar(32)  DEFAULT '' NOT NULL ,
  EMAIL varchar(128)  DEFAULT '' NOT NULL ,
  NAME varchar(128)  DEFAULT '' NOT NULL ,
  SUBJECT varchar(255)  DEFAULT '' NOT NULL ,
  LNAME varchar(50)  DEFAULT '' NOT NULL ,
  C0 varchar(255)  DEFAULT '' NOT NULL ,
  C1 varchar(255)  DEFAULT '' NOT NULL ,
  C2 varchar(255)  DEFAULT '' NOT NULL ,
  C3 varchar(255)  DEFAULT '' NOT NULL ,
  C4 varchar(255)  DEFAULT '' NOT NULL ,
  C5 varchar(255)  DEFAULT '' NOT NULL ,
  C6 varchar(255)  DEFAULT '' NOT NULL ,
  C7 varchar(255)  DEFAULT '' NOT NULL ,
  C8 varchar(255)  DEFAULT '' NOT NULL ,
  C9 varchar(255)  DEFAULT '' NOT NULL ,
  GRP varchar(10)  DEFAULT '' NOT NULL ,
EOT
    my $cnt = int ($cfg->get('cfldcnt'));
    if (!$cfg->get('itemidx')) {
      $cfg->set('itemidx', ($cnt > 10) ? $cnt:10);
      $cfg->save();
    }
    if ($cnt > 10) {
      my $i;
      for ($i = 10; $i < $cnt; ++$i) {
        $sql .= "ITEM varchar(255) DEFAULT '' NOT NULL,\n" if $i == $cfg->get('itemidx');
        $sql .= "C$i varchar(255) DEFAULT '' NOT NULL,\n";
      }
      $sql .= "ITEM varchar(255) DEFAULT '' NOT NULL,\n" if $i == $cfg->get('itemidx');
    } else {
      $sql .= "ITEM varchar(255) DEFAULT '' NOT NULL,\n";
    }
    $sql .= <<EOT;
  PRIMARY KEY (ID),
  UNIQUE ID (ID),
  KEY ID_2 (ID)
)
EOT
  } elsif ($table eq 'messages') {
    $sql = <<EOT;
CREATE TABLE $tablename (
  MID BIGINT AUTO_INCREMENT NOT NULL,
  TID BIGINT NOT NULL DEFAULT '0',
  AUTHOR VARCHAR(32) DEFAULT '' NOT NULL ,
  DATE DATETIME DEFAULT '0000-00-00 00:00:00' NOT NULL ,
  INTERNAL CHAR(1)  DEFAULT '0' NOT NULL ,
  ISOPER CHAR(1)  DEFAULT '0' NOT NULL ,
  HEADERS TEXT NOT NULL,
  MSG TEXT NOT NULL,
  PRIMARY KEY (MID),
  UNIQUE ID (MID),
  KEY TID (TID)
)
EOT
  }
  $sql =~ s/\n/ /g;
  if (!$dbh->do($sql)) {
    return "Error creating table $tablename, ".$dbh->errstr;
  }
  return undef;
}
1;
#
