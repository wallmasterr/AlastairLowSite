#!/usr/bin/perl
#
# This script is a part of
# Trouble Ticket Express package.
# http://www.troubleticketexpress.com
#
# COPYRIGHT: 2005-2007, United Web Coders
# http://www.unitedwebcoders.com
#
# $Revision: 447 $
# $Date: 2007-10-11 18:39:10 +0400 (Thu, 11 Oct 2007) $
#

my $configfile;
my $VERSION = '2.24';
my $REVISION;

# ==== NOTHING TO EDIT BELOW THIS LINE. PLS DO NOT CROSS =======================


BEGIN {
  if ($^O eq 'MSWin32') {
    eval "use FindBin";
    eval "use lib $FindBin::Bin";
    chdir($FindBin::Bin);
  }
  $REVISION = '$Revision: 447 $';
  if ($REVISION =~ /(\d+)/) {
    $REVISION = $1;
  }
}

use strict;
use CGI;
use TTXConfig;
use TTXMSSQLSetup;
use TTXData;

#
# Global vars
#
my $cfg;
my $query;
my %data;

print "HTTP/1.0 200 OK\n" if $ENV{PERLXS} eq "PerlIS";
print "Content-type: text/html\n\n";
header();
#
# Read config
#
$configfile = 'ttxcfg.cgi' if $configfile eq undef;
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
  TTXMSSQLSetup::setup1($cfg, $query);
} elsif ($cmd eq 'login') {
  dologin();
}

footer();

#======================================================================= dologin

sub dologin {
  my $error;
  if ($query->param('do')) {
    if ($query->param('passwd') eq undef || $query->param('passwd') ne $cfg->get('admpwd')) {
      $error = "Invalid password";
    } else {
      $query->param(-name => 'pwd', -value => $query->param('passwd'));
      $query->param(-name => 'do', -value => '');
      TTXMSSQLSetup::setup1($cfg, $query);
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
Trouble Ticket Express - MS SQL Server Module Setup
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
rev. $VERSION.$REVISION
</center>
</body>
</html>
EOT
}
