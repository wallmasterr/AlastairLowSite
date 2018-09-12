package TTXMSSQLSetup;
#
# This module is a part of Trouble Ticket Express package
# http://www.troubleticketexpress.com
#
# COPYRIGHT: 2005-2007, United Web Coders
# http://www.unitedwebcoders.com
#
# $Revision: 438 $
# $Date: 2007-10-11 16:23:42 +0400 (Thu, 11 Oct 2007) $
#

$TTXMSSQLSetup::VERSION='2.24';
BEGIN {
  $TTXMSSQLSetup::REVISION = '$Revision: 438 $';
  if ($TTXMSSQLSetup::REVISION =~ /(\d+)/) {
    $TTXMSSQLSetup::REVISION = $1;
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
  my $dsn = cleanit($query, 'dbdsn1') || cleanit($query, 'dbdsn') || $cfg->get('dbdsn');
  my $user = cleanit($query, 'user') || $cfg->get('dbuser');
  my $pass = cleanit($query, 'pass') || $cfg->get('dbpass');
  my $prefix = cleanit($query, 'prefix');
  $prefix = $cfg->get('dbpref') if !$query->param('do');
  my $imgurl = $cfg->get('imgurl');
#
# Check if DBI module installed
#
  eval "use DBI";
  if ($@ ne undef) {
    $error = <<EOT;
The DBI Perl library was not found on this server.<br>
Please install DBI library prior to running this program.<br>
<table cellpadding=5><tr><td align=left><font color=black>Try this:<br>
EOT
    if ($^O eq 'MSWin32') {
      $error .= <<EOT;
<b>&nbsp;&nbsp;&nbsp;C:\></b><i>ppm.bat</i><br>
<b>&nbsp;&nbsp;&nbsp;ppm></b> <i>install DBI</i><br>
EOT
    } else {
      $error .= <<EOT;
<b>#</b><i>perl -MCPAN -e shell</i><br>
<b><u>cpan></u></b> <i>install DBI</i><br>
EOT
    }
    $error .= <<EOT;
</font></td></tr></table>
EOT
  }
#
# Check if ODBC DBD driver installed
#
  if ($error eq undef) {
    my @drivers = DBI->available_drivers(1);
    if (!grep(/ODBC/, @drivers)) {
      $error = <<EOT;
The ODBC DBD driver was not found on this server.<br>
Please install ODBC DBD driver prior to running this program.<br>
<table cellpadding=5><tr><td align=left><font color=black>Try this:<br>
EOT
      my $drv = 'DBD::ODBC';
      if ($^O eq 'MSWin32') {
      $error .= <<EOT;
<b>&nbsp;&nbsp;&nbsp;C:\></b><i>ppm.bat</i><br>
<b>&nbsp;&nbsp;&nbsp;ppm></b> <i>install $drv</i><br>
EOT
      } else {
      $error .= <<EOT;
<b>#</b><i>perl -MCPAN -e shell</i><br>
<b><u>cpan></u></b> <i>install $drv</i><br>
EOT
      }
    $error .= <<EOT;
</font></td></tr></table>
EOT
    }
  }
#
# Check if any ODBC DSNs defined
#
  my @dsns;
  if ($error eq undef) {
    @dsns = grep {s/^DBI:ODBC://} DBI->data_sources('ODBC');
    $error = "No ODBC DSN records found on this server.<br>Please configure DSN prior to running this program."
      if !@dsns;
  }
#  foreach my $d (@dsns) {
#        print "$d<br>\n";
#  }
  if ($error eq undef && $query->param('do')) {
    $cfg->set('dbdsn', $dsn);
    $cfg->set('dbuser', $user);
    $cfg->set('dbpass', $pass);
    $cfg->set('dbpref', $prefix);
    $doimport = 1 if $cfg->get('dbmode') ne 'mssql';
    $error = build($cfg);
    if ($error eq undef) {
      eval "use TTXMSSQLTickets";
      if ($@) {
        $cfg->set('dbmode', 'plaintext');
      } else {
        $cfg->set('dbmode', 'mssql');
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
  if ($cfg->get('dbmode') eq 'mssql') {
    $warning = "YOU HAVE ALREADY ENABLED SQL SERVER MODE<br>\n".
              "THIS SCRIPT WILL RESET YOUR TICKETS DATABASE<br>\n".
              "ALL TICKETS SUBMITTED USING SQL MODE WILL BE LOST!";
  }
  $error = "<br><b><font color=red>Error: $error</font></b><br><br>" if $error ne undef;
  $warning = "\n<br><b><font color=red>$warning</font></b><br><br>" if $warning ne undef;
  print <<EOT;
<center><b>Microsoft SQL Server Module Setup</b><br>
<span class=sm>(go to <a href="setup.cgi?cmd=setup4&pwd=$pwd">Main Setup Utility</a> form)</span>
<br>$error$warning
<form action=$ENV{SCRIPT_NAME} method=post id=mainform>
<input type=hidden name=cmd value=setup1>
<input type=hidden name=do value=1>
<input type=hidden name=pwd value=$pwd>
<table border=0 cellpadding=0 cellspacing=0>
<tr height=1><td colspan=2 align=center height=1 bgcolor="#9b9b9b"><img
src="$imgurl/dot.gif" height=1></td></tr>
<tr><td colspan=2><br>
SQL Server database access info. Please contact your hosting provider or system admin if not sure.
<br><br>
A Data Source Name (DSN) is the logical name that is used by Open Database Connectivity (ODBC)
to refer to the drive and other information that is required to access data. The name is used by
Trouble Ticket Express for a connection to an ODBC data source, such as a Microsoft
SQL Server database. To set this name, use the ODBC tool in Control Panel.<br><br>
</td></tr>
<tr><td align=right><b>DSN:</b></td>
<td>&nbsp;&nbsp;<select name=dbdsn1 onChange="document.forms['mainform'].dbdsn.value='';"><option></option>
EOT
  my $dsnval = $dsn;
  $dsnval = s/"/&quot;/g;
  foreach my $d (@dsns) {
    my $quotedsn = $d; $quotedsn =~ s/"/&quot;/g;
    my $quotedsn1 = $d; $quotedsn =~ s/</&lt;/g;
    print "<option value=\"$quotedsn\"";
    if ($d eq $dsn) {
      print " selected";
      $dsnval = undef;
    }
    print ">$quotedsn1</option>\n";
  }
  print <<EOT;
</select>
other: <input type=text name=dbdsn value="$dsnval" onChange="document.forms['mainform'].dbdsn1.options[0].selected=true;">
</td></tr>
<tr><td align=right><b>User:</b></td><td>&nbsp;&nbsp;<input type=text name=user value="$user"></td></tr>
<tr><td align=right><b>Password:</b></td><td>&nbsp;&nbsp;<input type=password name=pass value="$pass"></td></tr>

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
<br><br>
The import procedure may take several minutes to complete.<br><b>Do not click twice!</b>
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
    print "You are proud owner of the Trouble Ticket Express Microsoft SQL Server Edition.\n".
    "Please <b>do not</b> run database setup utility unless you want to make changes to the database settings.\n"
  }
  print "<br><br>\n";
  if ($cfg->get('dbmode') ne 'mssql') {
    print <<EOT;
<b>IMPORTANT</b>
Trouble Ticket Express still uses plain text database.
Neither new tickets, nor follow-up messages to existing tickets will be added to the SQL Server database.
In order to enable SQL Server features you must install a SQL Server add-on module to your web server.
The module may be ordered on-line at our web site. After uploading the SQL Server add-on module to your web server,
please run this script once more - it will update your SQL Server database to ensure it includes
recent data from your plain text database and will switch Trouble Ticket Express into SQL Server mode.
<br><br>
<center>
<a href="http://www.troubleticketexpress.com/mssql.html"><b>Order MS SQL add-on module</b></a>
</center>
<br><br>
EOT
  } else {
    print "Trouble Ticket Express now uses SQL Server database.<br><br>\n";
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
  my @manda = ('dbdsn', 'dbuser', 'dbpass');
  my $id2name = {
    dbdsn => 'DSN',
    dbuser => 'User ID',
    dbpass => 'User Password'
  };
  my $error;
  foreach my $fld (@manda) {
    my $val = $cfg->get($fld);
    if ($val eq undef) {
      $error .= "Missing ".$id2name->{$fld}."<br>\n";
    }
  }
#
# Step one - connect to ms sql database engine
#
#  my $dsn = "DBI:mysql:database=".$cfg->get('dbid').";host=".$cfg->get('dbhost').";port=".$cfg->get('dbport');
  my $dbh = DBI->connect('DBI:ODBC:'.$cfg->get('dbdsn'), $cfg->get('dbuser'), $cfg->get('dbpass'),
                       {RaiseError => 0, AutoCommit => 1});
  if (!$dbh) {
    return "Error connecting to a database. $DBI::errstr";
  }
#
# Still alive? Good. Try to create tables now.
#
  my $sth = $dbh->prepare("EXECUTE sp_tables");
  $sth->execute();
  my %tables;
  while (my @row = $sth->fetchrow_array()) {
    $tables{$row[2]} = 1;
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
    my %fldlen = (
      email => 128,
      name => 128,
      oper => 32,
      subject => 255,
      lname => 50,
      grp => 10,
      status => 3,
      key => 64,
      item => 255
    );
    my $boundary = TTXTickets::_boundary();
    my $fn = $cfg->get('ticketdb');
    return undef if ! -f $fn;
    return "Database import failed: error reading ticket database" if !open(DB, $fn);
    my @buff = <DB>;
    close DB;
    chomp @buff;
    $| = 1;
    my $N = 'N' if TTXCommon::dodec();
    foreach my $line (@buff) {
      print "\n";
      my @fields = split(/\|/, $line);
      my %tik;
      my $sql = "INSERT INTO ".$cfg->get('dbpref')."tickets VALUES(";
      my $values;
      foreach my $fld (@tickfields) {
        $tik{$fld} = TTXCommon::decodeit(shift @fields);
        $tik{$fld} = '' if $tik{$fld} eq undef;
        $values .= ',' if $values ne undef;
        if ($fld =~ /^(open|updated|closed)$/) {
          $values .= $dbh->quote(gmt($tik{$fld}));
        } elsif ($fld eq 'id') {
          $values .= $dbh->quote($tik{$fld});
        } elsif ($fld =~ /^c\d+$/) {
          $values .= $N.$dbh->quote(substr($tik{$fld},0,255));
        } else {
          $values .= $N.$dbh->quote(substr($tik{$fld},0,$fldlen{$fld}));
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
          my $author = substr($header{FROM},0,32);
          my $date = gmt($header{DATE});
          my $internal = $header{INTERNAL} ? '1':'0';
          my $isoper = $header{OPERATOR} ? '1':'0';
          $rawheader = '';
          foreach my $hdrkey (sort keys %header) {
            next if grep(/^$hdrkey$/, ('FROM', 'DATE', 'INTERNAL', 'BODY', 'OPERATOR'));
            $rawheader .= "$hdrkey: $header{$hdrkey}\n";
          }
          if (!$dbh->do("INSERT INTO ".$cfg->get('dbpref')."messages (TID, AUTHOR, DATE, ISOPER, INTERNAL, HEADERS, MSG) VALUES ".
                    "('$tik{id}',".$N.$dbh->quote($author).",'$date','$isoper','$internal',".
                    $N.$dbh->quote($rawheader).','.$N.$dbh->quote($body).')')) {
            return "Error importing messages of ticket #"."$tik{id}. ".$dbh->errstr;
          }
        }
      }
    }
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
  my %flbl = (
    varchar => 'varchar',
    char => 'char',
    text => 'text'
  );
  if (TTXCommon::dodec()) {
    foreach my $lbl (keys %flbl) {
      $flbl{$lbl} = 'n'.$flbl{$lbl};
    }
  }
  if ($table eq 'tickets') {
    $sql = <<EOT;
CREATE TABLE $tablename (
  ID bigint  UNIQUE DEFAULT '' NOT NULL,
  ACCESSKEY $flbl{varchar}(64)  DEFAULT '' NOT NULL ,
  OPENED datetime  DEFAULT '0000-00-00 00:00:00' NOT NULL,
  UPDATED datetime  DEFAULT '0000-00-00 00:00:00' NOT NULL,
  CLOSED datetime  DEFAULT '0000-00-00 00:00:00' NOT NULL,
  STATUS $flbl{char}(3)  DEFAULT '' NOT NULL,
  OPER $flbl{varchar}(32)  DEFAULT '' NOT NULL,
  EMAIL $flbl{varchar}(128)  DEFAULT '' NOT NULL,
  NAME $flbl{varchar}(128)  DEFAULT '' NOT NULL,
  SUBJECT $flbl{varchar}(255)  DEFAULT '' NOT NULL,
  LNAME $flbl{varchar}(50)  DEFAULT '' NOT NULL,
  C0 $flbl{varchar}(255)  DEFAULT '' NOT NULL,
  C1 $flbl{varchar}(255)  DEFAULT '' NOT NULL,
  C2 $flbl{varchar}(255)  DEFAULT '' NOT NULL,
  C3 $flbl{varchar}(255)  DEFAULT '' NOT NULL,
  C4 $flbl{varchar}(255)  DEFAULT '' NOT NULL,
  C5 $flbl{varchar}(255)  DEFAULT '' NOT NULL,
  C6 $flbl{varchar}(255)  DEFAULT '' NOT NULL,
  C7 $flbl{varchar}(255)  DEFAULT '' NOT NULL,
  C8 $flbl{varchar}(255)  DEFAULT '' NOT NULL,
  C9 $flbl{varchar}(255)  DEFAULT '' NOT NULL,
  GRP $flbl{varchar}(10)  DEFAULT '' NOT NULL,
EOT
    my $cnt = int ($cfg->get('cfldcnt'));
    if (!$cfg->get('itemidx')) {
      $cfg->set('itemidx', ($cnt > 10) ? $cnt:10);
      $cfg->save();
    }
    if ($cnt > 10) {
      my $i;
      for ($i = 10; $i < $cnt; ++$i) {
        $sql .= "ITEM $flbl{varchar}(255) DEFAULT '' NOT NULL,\n" if $i == $cfg->get('itemidx');
        $sql .= "C$i $flbl{varchar}(255) DEFAULT '' NOT NULL,\n";
      }
      $sql .= "ITEM $flbl{varchar}(255) DEFAULT '' NOT NULL,\n" if $i == $cfg->get('itemidx');
    } else {
      $sql .= "ITEM $flbl{varchar}(255) DEFAULT '' NOT NULL,\n";
    }
    $sql .= "PRIMARY KEY (ID))\n";
  } elsif ($table eq 'messages') {
    $sql = <<EOT;
CREATE TABLE $tablename (
  MID BIGINT IDENTITY PRIMARY KEY,
  TID BIGINT NOT NULL DEFAULT '0',
  AUTHOR $flbl{varchar}(32)  DEFAULT '' NOT NULL ,
  DATE DATETIME  DEFAULT '0000-00-00 00:00:00' NOT NULL ,
  INTERNAL $flbl{char}(1)  DEFAULT '0' NOT NULL ,
  ISOPER $flbl{char}(1)  DEFAULT '0' NOT NULL ,
  HEADERS $flbl{text}  DEFAULT '' NOT NULL,
  MSG $flbl{text}  DEFAULT '' NOT NULL
)
EOT
  }
  $sql =~ s/\n/ /g;
  if (!$dbh->do($sql)) {
    return "Error creating table $tablename, ".$dbh->errstr;
  }
  if ($table eq 'messages') {
    $dbh->do("CREATE INDEX TID ON $tablename (TID)");
  }
  return undef;
}
1;
#
