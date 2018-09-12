#!/usr/bin/perl
#
# This script is a part of
# Trouble Ticket Express package.
# http://www.troubleticketexpress.com
#
# COPYRIGHT: 2002-2007, United Web Coders
# http://www.unitedwebcoders.com
#
# $Revision: 430 $
# $Date: 2007-10-11 16:13:40 +0400 (Thu, 11 Oct 2007) $
#
#

my $configfile;
my $VERSION = '2.24';
my $REVISION;

# ==== NOTHING TO EDIT BELOW THIS LINE. PLS DO NOT CROSS =======================


BEGIN {
  print "HTTP/1.0 200 OK\n" if $ENV{PERLXS} eq "PerlIS";
  $REVISION = '$Revision: 430 $';
  if ($REVISION =~ /(\d+)/) {
    $REVISION = $1;
  }
  my $sd = _findsd() || '.';
  $sd =~ /(.*)/;
  $sd = $1;
  eval "use lib '$sd'";
  if ($@) {
    _fatalbegin($@);
    exit 0;
  }
  if ($sd ne '.') {
    chdir $sd;
  }
  eval "use TTXConfig";
  if ($@) {
    if (-f "$sd/TTXConfig.pm") {
      _fatalbegin($@);
    } else {
      _fatalbegin("Incomplete package. Please upload all *.cgi and *.pm files to your web server");
    }
    exit 0;
  }
  sub _fatalbegin {
    print <<EOT;
Content-type: text/html

<html>
<body>
<br><br>
<font color=red><b>Fatal error:</b></font>
$_[0]
<br><br>
<a href="ttx.helpdeskconnect.com"><b>Trouble Ticket Express Help Desk</b></a><br />
EOT
    print "<br /><strong>SDir:</strong> $sd<br />\n";
    foreach my $key (sort keys %ENV) {
      print "<strong>$key:</strong> $ENV{$key}<br />\n";
    }
    print "</body>\n</html>\n";
  }
  sub _findsd {
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

use strict;
use CGI;
use TTXConfig;
use TTXSetup;
use TTXData;

#
# Global vars
#
my $cfg;
my $query;
my %data;

print "Content-type: text/html\n\n";
#
# Read config
#
$configfile = 'ttxcfg.cgi' if $configfile eq undef;
$cfg = TTXConfig->new($configfile);
TTXData::set('CONFIG', $cfg);
my $freshsetup = 1 if $cfg->error() ne undef;
if ($cfg->get('cfgref') ne undef) {
  my $regcfg = TTXConfig->new($cfg->get('cfgref'));
  $cfg = $regcfg;
  $freshsetup = 1 if $cfg->error() ne undef;
  TTXData::set('CONFIG', $cfg);
}
#
# Parse input
#
$query = new CGI;
#
# Validate user if not fresh setup and id provided
#
if (!$freshsetup && $query->param('cmd') ne 'logout') {
  if ($query->param('pwd') ne undef) {
     if ($cfg->get('admpwd') eq $query->param('pwd')) {
       my $seed = join ('', ('.', '/', 0..9, 'A'..'Z', 'a'..'z')[rand 64, rand 64]);
       $cfg->set('admpwdseed', $seed);
       $cfg->save();
       my $cpwd = crypt($cfg->get('admpwd'), $seed);
       $cpwd =~ s/^..//;
       $query->param(-name => 'pwd', value => $cpwd);
     }
     if (crypt($cfg->get('admpwd'), $cfg->get('admpwdseed')) ne $cfg->get('admpwdseed').$query->param('pwd')) {
       login();
     } else {
       my $seed = join ('', ('.', '/', 0..9, 'A'..'Z', 'a'..'z')[rand 64, rand 64]);
       $cfg->set('admpwdseed', $seed);
       $cfg->save();
       my $cpwd = crypt($cfg->get('admpwd'), $seed);
       $cpwd =~ s/^..//;
       $query->param(-name => 'pwd', value => $cpwd);
     }
  } elsif ($cfg->get('admpwd') ne undef) {
    login();
  } else {
    $query->param(-name => 'cmd', -value => 'setup3');
  }
}
header($cfg);
#
# Execute command
#
my $cmd = $query->param('cmd');
$cmd = 'setup1' if $cmd eq undef;
if ($cmd eq 'setup1') {
  TTXSetup::setup1($cfg, $query);
} elsif ($cmd eq 'setup2') {
  TTXSetup::setup2($cfg, $query);
} elsif ($cmd eq 'setup3') {
  TTXSetup::setup3($cfg, $query);
} elsif ($cmd eq 'setup4') {
  TTXSetup::setup4($cfg, $query);
} elsif ($cmd eq 'setup5') {
  TTXSetup::setup5($cfg, $query);
} elsif ($cmd eq 'grps') {
  TTXSetup::grps($cfg, $query);
} elsif ($cmd eq 'inventory') {
  TTXSetup::inventory($cfg, $query);
} elsif ($cmd eq 'logout') {
  if (!$freshsetup) {
    $cfg->set('admpwdseed', '');
    $cfg->save();
  }
  dologin();
} elsif ($cmd eq 'login') {
  dologin();
} elsif ($cmd eq 'smtplog') {
  smtplog();
} elsif ($cmd eq 'sysinfo') {
  TTXSetup::sysinfo($cfg, $query);
}

footer($ENV{'QUERY_STRING'} !~ /pwd=/ ? 1:0);

#======================================================================= dologin

sub dologin {
  my $error;
  if ($query->param('do')) {
    if ($query->param('passwd') eq undef || $query->param('passwd') ne $cfg->get('admpwd')) {
      $error = "Invalid password";
    } else {
      my $seed = join ('', ('.', '/', 0..9, 'A'..'Z', 'a'..'z')[rand 64, rand 64]);
      $cfg->set('admpwdseed', $seed);
      $cfg->save();
      my $cpwd = crypt($cfg->get('admpwd'), $seed);
      $cpwd =~ s/^..//;
      $query->param(-name => 'pwd', value => $cpwd);
      $query->param(-name => 'do', -value => '');
      TTXSetup::setup4($cfg, $query);
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
<br><br>
Subscribe to <a href="http://www.unitedwebcoders.com">United Web Coders</a> news.
<br>
Stay tuned for new software releases and yet to be documented features.
<br>
<br>
<table>
<tr>
<td>
<a href="http://feeds.feedburner.com/uwc"
title="Subscribe to United Web Coders News Feed"
rel="alternate"
type="application/rss+xml">
<img src="http://www.unitedwebcoders.com/i/feed-icon16x16.png" alt="" style="border:0"/></a>
</td><td alig=left>
<a href="http://feeds.feedburner.com/uwc"
rel="alternate"
type="application/rss+xml">
Use RSS news feed.
</a>
</td>
</tr>
</table>
<form
action="http://www.feedburner.com/fb/a/emailverify" method="post"
target="popupwindow"
onsubmit="window.open('http://www.feedburner.com', 'popupwindow', 'scrollbars=yes,width=550,height=520');return true">
<b>or</b>
Subscribe to our mail list
<small><br><br></small>
<span class=lbl>Email: </span><input type="text" style="width:140px" name="email"/>
<input type="hidden" value="http://feeds.feedburner.com/~e?ffid=373254" name="url"/>
<input type="hidden" value="United Web Coders" name="title"/>
<input type="submit" value="Subscribe" />
<small><br><br></small>
<small>Delivered by <a href="http://www.feedburner.com/" target="_blank">FeedBurner</a></small></form></center>
EOT
}
# ====================================================================== smtplog

sub smtplog {
  my $smtplog = $cfg->get('basedir').'/smtptrace.txt';
  my $pwd = $query->param('pwd');
  if (! -f $smtplog) {
    print "<br><center><b>SMTP log file does not exist</b></center><br>\n";
  } elsif (!open(LOG, $smtplog)) {
    print "<br><center><b><font color=red>Error opening SMTP log file.</font></b></center><br>\n";
  } else {
  print <<EOT;
<center>
<br><br>
<form action=$ENV{SCRIPT_NAME} method=post>
<input type=hidden name=cmd value=setup4>
<input type=hidden name=pwd value=$pwd>
<input type=submit value="System Setup Form">
</form>
</center>
EOT
    my @buff = <LOG>;
    close LOG;
    foreach my $line (@buff) {
      $line =~ s/</&lt;/g;
      print "$line<br>";
    }
  }
  print <<EOT;
<center>
<br><br>
<form action=$ENV{SCRIPT_NAME} method=post>
<input type=hidden name=cmd value=setup4>
<input type=hidden name=pwd value=$pwd>
<input type=submit value="System Setup Form">
</form>
</center>
EOT

}
#========================================================================= login

sub login {
  $query->param(-name => 'pwd', -value => '');
  $query->param(-name => 'cmd', -value => 'login');
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
  my $cfg = $_[0];
  my $logout;
  my $charset = 'ISO-8859-1';
  if (!$freshsetup) {
    $logout = "<table width=600><tr><td align=right>".
              "<a href=\"$ENV{SCRIPT_NAME}?cmd=logout\">".
              "<span class=sm><b>logout</b></span></a></td></tr></table>\n";
    if ($cfg->get('forcecharset') ne undef) {
      $charset = $cfg->get('forcecharset');
    } elsif ($cfg->get('charset') ne undef) {
      $charset = $cfg->get('charset');
    }
  }
  print <<EOT;
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.0 Transitional//EN"
"http://www.w3.org/TR/REC-html40/loose.dtd">
<html>
<head>
<meta http-equiv="Content-Type" content="text/html; charset=$charset">
<title>
Trouble Ticket Express Setup
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
<td align=left>$logout
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
