#!/usr/bin/perl
#
# Visit the Trouble Ticket Express home page for release notes and setup info
# http://www.troubleticketexpress.com
#
# COPYRIGHT: 2002-2007, United Web Coders.
# http://www.unitedwebcoders.com
#
# $Revision: 431 $
# $Date: 2007-10-11 16:14:00 +0400 (Thu, 11 Oct 2007) $
#
my $configfile;
my $defaultcmd = 'newticket';

# ==== NOTHING TO EDIT BELOW THIS LINE. PLS DO NOT CROSS =======================

my $version = '2.24';
my $REVISION;

BEGIN {
  print "HTTP/1.0 200 OK\n" if $ENV{PERLXS} eq "PerlIS";
  $REVISION = '$Revision: 431 $';
  if ($REVISION =~ /(\d+)/) {
    $REVISION = $1;
  }
  my $sd = _findsd() || '.';
  $sd =~ /(.*)/;
  $sd = $1;
  my $path = $ENV{PATH};
  $path =~ /(.*)/;
  $ENV{PATH} = $1;
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
<a href="http://ttx.helpdeskconnect.com"><b>Trouble Ticket Express Help Desk</b></a>
</body>
</html>
EOT
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
use TTXCommon;
use TTXData;
require TTXSession;
require TTXUser;
require TTXDictionary;
eval "require TTXFile";
TTXData::set('ISPRO', 1) if $@ eq undef;

# please uncomment the following line in order to get rid of
# bogus "usage of uninitialized variable" in your error log file, but
# make sure your Perl supports the 'no warnings' pragma

#  no warnings 'uninitialized';

#
# Global vars
#
my $cfg;
my $query;
my $user;
my %data;
my $usecache = 0;
my $originalcookie;
my $cmdcnt = 0;
my $MAXCMD = 10;

my $cmddef = {
 login      => { action => 'TTXLogin::login',   access => 0 },
 ticket     => { action => 'TTXTicket::ticket',  access => 0 },
 claim      => { action => 'TTXTicket::claim',  access => 1 },
 keyfinder  => { action => 'TTXTicket::keyform',  access => 0, template => 'keyform.html'  },
 keyform    => { action => 'TTXTicket::keyform',  access => 0 },
 newticket  => { action => 'TTXTicket::newticket',  access => 0 },
 confirmnew => { action => 'TTXTicket::confirmnew',  access => 0 },
 markuphelp => { action => 'TTXMarkup::help',  access => 0, noheader => 1, template => 'markuphelp.html' },
 answerlib => { action => 'TTXOrder::answerlib',  access => 1, noheader => 1, template => 'orderalib.html' },
 newanswer => { action => 'TTXAnswerLib::newanswer',  access => 1, noheader => 1 },
 delanswer => { action => 'TTXAnswerLib::delanswer',  access => 1, noheader => 1 },
 editanswer => { action => 'TTXAnswerLib::editanswer',  access => 1, noheader => 1, template => 'newanswer.html' },
 ticketed => { action => 'TTXTickEd::ticketed',  access => 1, noheader => 1, template => 'ticketed.html' },
 helpdesk   => { action => 'TTXDesk::helpdesk', access => 1 },
 reports   => { action => 'TTXReports::main', access => 1 },
 survey => { action => 'TTXSurvey::survey',  access => 0 },
 cfrmsurvey => { action => 'TTXSurvey::confirm',  access => 0 },
 annotate => { action => 'TTXPrint::annotate',  access => 0, noheader => 1 },
 'print' => { action => 'TTXPrint::print',  access => 0, noheader => 1  },
 preview => { action => 'TTXPreview::preview',  access => 0, noheader => 1  },
 groupcommand   => { action => 'TTXGrpCmd::do', access => 1 },
 msgedit   => { action => 'TTXMsgEdit::edit', access => 1, noheader => 1   },
 msgdel   => { action => 'TTXMsgEdit::del', access => 1, noheader => 1   },
};
eval "require TTXAnswerLib";
if ($@ eq undef) {
  $cmddef->{answerlib}->{action} = 'TTXAnswerLib::answerlib';
  $cmddef->{answerlib}->{template} = 'answerlib.html';
}
eval "use TTXMyTickets";
if ($@ eq undef) {
  $cmddef->{mytickets}->{action} = 'TTXMyTickets::mytickets';
  $cmddef->{mytickets}->{template} = 'helpdesk.html';
}
eval "require TTXDashBoard";
if ($@ eq undef) {
  $cmddef->{showitem}->{action} = 'TTXDashBoard::showitem';
  $cmddef->{showitem}->{noheader} = 1;
  $cmddef->{showitem}->{access} = 1;
  $cmddef->{dashboard}->{action} = 'TTXDashBoard::dashboard';
  $cmddef->{dashboard}->{access} = 1;
}
eval "require TTXLookup";
if ($@ eq undef) {
  $cmddef->{lookup}->{action} = 'TTXLookup::lookup';
  $cmddef->{lookup}->{noheader} = 1;
  $cmddef->{lookup}->{access} = 1;
  $cmddef->{lookup}->{template} = '#';
}
#
# Read config
#
if ($configfile eq undef) {
  $configfile = 'ttxcfg.cgi';
  my $sd = scriptdir();
  $configfile = "$sd/ttxcfg.cgi" if $sd ne undef;
}
$cfg = TTXConfig->new($configfile);
if ($cfg->error()) {
  print "Content-type: text/html\n\n";
  fatalerror($cfg->errortext())
}
if ($cfg->get('cfgref') ne undef) {
  if (!$cfg->load($cfg->get('cfgref'))) {
    print "Content-type: text/html\n\n";
    fatalerror($cfg->errortext());
  }
}
if ($cfg->get('order1256')) {
  $cmddef->{ticket}->{template} = 'ticket1256.html';
}
if ($cfg->get('validate') ne undef) {
  $cmddef->{confirmnew}->{template} = 'confirmnewvalidate.html';
}
TTXData::set('CONFIG', $cfg);
if ($cfg->get('cookiename') eq undef) {
  $cfg->set('cookiename', 'TTXPRESS');
}
readglobals();
if ($cfg->get('httphost') ne $ENV{HTTP_HOST} || $cfg->get('scriptname') ne $ENV{SCRIPT_NAME}) {
  $cfg->set('httphost', $ENV{HTTP_HOST});
  $cfg->set('scriptname', $ENV{SCRIPT_NAME});
  $cfg->save();
}
if ($cfg->get('ttx.version') eq undef || $cfg->get('ttx.version') < $version) {
  eval 'use TTXUpgrade';
  if ($@ ne undef) {
    print "Content-type: text/html\n\n";
    fatalerror('TTXUpgrade.pm not found. Please upload the file to the scripts directory.');
  }
  my $err = TTXUpgrade::upgrade($cfg);
  if ($err ne undef) {
    print "Content-type: text/html\n\n";
    fatalerror("Error during upgrade: $err");
  }
}
if ($cfg->get('internaldesk')) {
  $cmddef->{newticket}->{access} = 1;
  $defaultcmd = 'helpdesk';
}
#
# Stop here if database upgrade is in progress
#
if ($cfg->get('dbupdate') > 0) {
  if ((time() - $cfg->get('dbupdate')) > 120) {
    # the upgrade process died
    $cfg->set('dbupdate', '');
    $cfg->save();
  } else {
    print "Content-type: text/html\n\n";
    upgrademsg();
    exit;
  }
}
#
# Set charset
#
if ($cfg->get('forcecharset') eq undef) {
  my $charset = TTXDictionary::translate('CHARSET');
  if ($charset ne undef && $charset ne 'CHARSET' && $charset ne $cfg->get('charset')) {
    $cfg->set('charset', $charset);
    $cfg->save();
  }
} elsif ($cfg->get('forcecharset') ne $cfg->get('charset')) {
  $cfg->set('charset', $cfg->get('forcecharset'));
  $cfg->save();
}
if ($cfg->get('charset') eq undef) {
  $cfg->set('charset', $cfg->set('charset', 'ISO-8859-1'));
}
#
# Parse input
#
my $tmpdir = $cfg->get('basedir').'/tmp';
if (! -d $tmpdir) {
  mkdir($tmpdir, 0777);
}
if (-d $tmpdir && -w $tmpdir) {
  $ENV{TMPDIR} = $tmpdir if $ENV{TMPDIR} eq undef || ! -d $ENV{TMPDIR} || ! -w $ENV{TMPDIR};
}
eval '$query = new CGI';
if ($@ ne undef) {
  warn "New CGI failed, error: $@";
  print <<EOT;
Content-type: text/html

<html>
<body>
<br><br><br><br>
<center>
<b><font color=red>The file you are trying to upload is too big</font>
<br><br>
Please use your browser 'Back' button to return to previous page.
</center>
</body>
</html>
EOT
  exit;
}
if ($query eq undef) {
  print "Content-type: text/html\n\n";
  exit;
}
if ($query->param('cmd') eq 'file' && TTXData::get('ISPRO')) {
  TTXFile::download($query->param('fid'), $query->param('fn'));
  exit;
}
if ($query->param('cmd') eq 'img') {
  eval "use TTXImage";
  if (!$@) {
    TTXImage::show($query->param('fid'), $query->param('fid'));
  }
  exit;
}
if ($cfg->get('charset') =~ /^utf/i) {
  if ($] >= 5.008) {
    binmode STDOUT, ":utf8";
  } else {
    binmode STDOUT;
  }
}
#
# Create User object if session id provided
#
print "Content-type: text/html\n"; # Single new-line, as more headers may follow
my $savestate = $|;
$|=1;
$|=$savestate;
#
# Retrieve session ID
#
my $sid;
if ($query->param('sid') ne undef) {
  $sid = $query->param('sid');
} elsif($cfg->get('rememberme')) {
  $sid = $cfg->get('_GLOBAL_SID');
}
if ($sid ne undef) {
  my $session = TTXSession->new($sid);
  if ($session ne undef && $session->get('login') ne undef) {
    if ($session->expired()) {
      $session->logout();
      $query->param(-name => 'sid', -value => '');
      $cfg->set('_GLOBAL_SID', undef);
      $query->param(-name => 'cmd', -value => 'helpdesk');
      login('[%Your session expired%]');
    } else {
      $session->refresh();
      $user = TTXUser->new($session->get('login'));
      if ($user eq undef || $user->get('login') eq undef) {
        $query->param(-name => 'sid', -value => '');
        $user = undef;
      } elsif ($query->param('cmd') eq 'logout') {
        $session->logout();
        $query->param(-name => 'sid', -value => '');
        $cfg->set('_GLOBAL_SID', undef);
        $query->param(-name => 'cmd', -value => '');
        login('[%You were logged out%]');
        $user = undef;
      } else {
        $user->set('session', $session);
      }
    }
  } else {
    $query->param(-name => 'sid', -value => '');
    $cfg->set('_GLOBAL_SID', undef);
  }
} else {
  if ($cfg->get('quicklink') && $query->param('cmd') eq 'helpdesk') {
    my $oper = $query->param('o');
    my $tk = $query->param('tk');
    my $p = $query->param('p');
    if ($oper ne undef && $tk =~ /^\d+Z/ && $p ne undef) {
       my $u = TTXUser->new($oper);
       if ($u ne undef && $u->{passwd} ne undef) {
         $tk =~ s/Z.*//;
         my $salt = $tk;
         $salt = $salt % 100;
         $salt = "0$salt" if $salt < 10;
         $p = "$salt$p";
         if ($p eq crypt($u->{passwd}.$tk, $p)) {
           $query->param(-name => 'cmd', -value => 'login');
           $query->param(-name => 'nextcmd', -value => 'helpdesk');
           $query->param(-name => 'login', -value => $oper);
           $query->param(-name => 'passwd', -value => $u->{passwd});
           $query->param(-name => 'dologin', -value => 1);
         }
       }
    }
  }
}
if ($query->param('cmd') eq 'logout') {
  $query->param(-name => 'cmd', -value => '');
  $cfg->set('_GLOBAL_SID', undef);
  login("You were logged out");
}
if ($user ne undef) {
  $cfg->set('_USER', $user);
  $data{USERID} = $user->{login};
  if ($user->get('ro')) {
    $cmddef->{ticket}->{template} = 'roticket.html';
  }
  if($cfg->get('rememberme') && $query->param('sid') ne undef) {
    $cfg->set('_GLOBAL_SID', $query->param('sid'));
    $query->param('sid', '');
  }
}
if ($cfg->get('HTMLBASEWIDTH') eq undef) {
  $cfg->set('HTMLBASEWIDTH', 700);
  $cfg->save();
}
if ($query->param('cmd') eq undef) {
  $query->param(-name => 'cmd', -value => $defaultcmd);
}
#
# Consult cache
#
my $pagesignature;
if ($cfg->get('usecache')) {
  eval "use TTXCache";
  if ($@ eq undef) {
    $usecache = 1;
    TTXData::set('_USECACHE', 1);
    my $pgid = TTXCache::hit($cfg, $query);
    $pagesignature = TTXCache::signature($query);
    my $sessig;
    if ($query->param('sid') ne undef) {
      my $session = TTXSession->new($query->param('sid'));
      if ($session ne undef && $user ne undef &&
          $session->get('login') ne undef &&
          $user->{login} eq $session->get('login')) {
        $sessig = $session->get('signature');
        $session->set('signature', $pagesignature);
        $session->save();
      }
    }
    if ($pgid) {
      my $pgout = TTXCache::page($cfg, $pgid);
      if ($pgout ne undef) {
        print "\n$pgout";
        TTXCache::logit('H|'.$query->param('cmd').'|'.length($pgout));
        exit;
      }
    } else {
      TTXCache::logit('M|'.$query->param('cmd'));
    }
  }
}
#
# Execute command
#
command($query->param('cmd'));
if ($cfg->get('grpsellbl') eq undef) {
  $cfg->set('grpsellbl', 'Group');
}
my $cfgvars = $cfg->ashash();
foreach my $key (keys %{$cfgvars}) {
  my $val = $cfgvars->{$key};
  if (TTXCommon::dodec() && grep(/^$key$/, ('company', 'grpsellbl'))) {
    $val = TTXCommon::decodeit($val);
  }
  $data{"CONFIG_".uc $key} = $val;
}
foreach my $key (keys %ENV) {
  $data{"ENV_".uc $key} = $ENV{$key};
}
foreach my $key ($query->param) {
  $data{"INPUT_".$key} = TTXCommon::decodeit($query->param($key));
  if ($key ne 'problem') {
    $data{"INPUT_".$key} =~ s/"/&quot;/g;
  } else {
    $data{"INPUT_".$key} =~ s/</&lt;/g;
  }
}
if (defined $cmddef->{dashboard} && $cfg->get('_USER') ne undef) {
  $data{DASHBOARDLINK} = "<a href=\"$ENV{SCRIPT_NAME}?cmd=dashboard&sid=".$query->param('sid').
                         "&style=".$query->param('style').'">[%Dashboard%]</a> |';
}
if ($query->param('checkupdate')) {
  $data{CHECKUPDATE} = "<a href=\"http://www.troubleticketexpress.com\"><img border=0 src=\"http://www.troubleticketexpress.com/cgi-bin/ttx/checkupdate.cgi?$version\"></a>";
}
$data{VERSION} = "$version.$REVISION";
if ($cfg->get('dbmode') eq 'mysql') {
  $data{ISPRO} .= 'MySQL Edition';
} elsif ($cfg->get('dbmode') eq 'mssql') {
  $data{ISPRO} .= 'SQL Server Edition';
} else {
  $data{ISPRO} .= 'Standard Edition';
  my $u = $cfg->get('_USER');
  if ($u ne undef) {
    $data{ISPRO} .= ', upgrade to <a href="sqlsetup.cgi">MySQL</a> or '.
                    '<a href="mssqlsetup.cgi">SQL Server</a> edition.'
  }
}
$data{HTMLBASEWIDTH} = $cfg->get('HTMLBASEWIDTH');
$data{HELPDESKCMD} = ($cfg->get('_USER') ne undef) ? 'helpdesk':'ticket';
if ($query->param('cmd') eq 'mytickets' ||
    ($query->param('cmd') eq 'ticket' && $query->param('emailkey') ne undef && $query->param('sid') eq undef)) {
  $data{HELPDESKCMD} = 'mytickets&emailkey=' . $query->param('emailkey');
}
if ($cfg->get('_USER') ne undef) {
  my $u = $cfg->get('_USER');
  $data{USERID} = $u->{login};
  $data{USERFNAME} = $u->{fname};
  $data{USERLNAME} = $u->{lname};
  $data{LOGGEDAS} = TTXDictionary::translate('Logged as').' '.$u->{fname}.' '.$u->{lname};
  if ($cfg->get('dbmode') =~ /sql/ && $cfg->get('dbschema') < 2.19) {
    $data{ISPRO} .= ' <font color=red><b>NOTE:</b></font> <a href="sqlupgrade.cgi"><b>Database upgrade required.</b></a>';
  } elsif ($cfg->get('dbmode') =~ /sql/ && $cfg->get('dbschema') < 2.22) {
    $data{ISPRO} .= ' <font color=red><b>NOTE:</b></font> <a href="sqlupgrade222.cgi"><b>Database upgrade required.</b></a>';
  }
}
if ($cfg->get('_USER') ne undef) {
  my $uid = $cfg->get('_USER')->get('login');
  if ($cfg->get('grant.reports') eq undef || grep(/^$uid$/, split(/,/,$cfg->get('grant.reports')))) {
    $data{LOGINLOGOUT} .= "<a href=\"$ENV{SCRIPT_NAME}?cmd=reports&sid=".
                          $query->param('sid')."&style=".$query->param('style').'">[%Reports%]</a> | ';
  }
}
if (!$cfg->get('nologinlink')) {
  $data{LOGINLOGOUT} .= "<a href=\"$ENV{SCRIPT_NAME}?cmd=".(($cfg->get('_USER') ne undef) ? 'logout':'login').
                     "&sid=".$query->param('sid')."&style=".$query->param('style')."\">".(($cfg->get('_USER') ne undef) ? '[%Logout%]':'[%Login%]').
                     "</a>";
}
if ($cfg->get('home') ne undef) {
  $data{HOMELINK} .= '<a href="'.$cfg->get('home').'">[%Home%]</a> |';
}
if ($data{ERROR_MESSAGE} ne undef) {
  $data{ERROR_BOX} =<<EOT;
<table width=$data{HTMLBASEWIDTH} cellpadding=0 cellspacing=0>
<tr>
<td align=center bgcolor="#CFDCE8">
<br>
<table width=500 cellpadding=0 cellspacing=0>
        <tr>
                <td class=error align=center>$data{ERROR_MESSAGE}</td>
        </tr>
</table>
<br>
</td>
</tr>
</table>
EOT
}
my $template = TTXCommon::decodeit(loadtemplate());
$template =~ s/\(%\s*([a-zA-Z0-9_]+)\s*%\)/$data{$1}/g;
$template =~ s/\[%%\]//g;
$template =~ s/\[%([^]]+)%\]/TTXDictionary::translate($1)/ge;
print preparecookie()."\n$template";
#
# Update cache
#
if ($usecache) {
  TTXCache::store($cfg, $query, $template, $pagesignature);
}
exit;


#================================================================== loadtemplate

sub loadtemplate {
  my ($t, $style);
  if ($query->param('cmd') eq 'newticket' && $query->param('form') ne undef) {
    my @parts = split(/\/|\\/, $query->param('form'));
    $t = pop @parts;
    $t .= '.html';
  }
  if ($t eq undef) {
    $t = $cmddef->{$query->param('cmd')}->{template};
    $t = $query->param('cmd').".html" if $t eq undef;
  }
  my $fn = $cfg->get('basedir')."/templates";
  if ($query->param('style') ne undef) {
    my @parts = split(/\/|\\/, $query->param('style'));
    $style = pop @parts;
  }
  my $template;
  if ($t ne '#') {
    if ($style ne undef) {
      if ((! -f "$fn/$style/$t" || !open(TMPL, "$fn/$style/$t")) &&
          (! -f "$fn/$t" || !open(TMPL, "$fn/$t"))) {
        fatalerror("Missing template $t");
      }
    } elsif (! -f "$fn/$t" || !open(TMPL, "$fn/$t")) {
      fatalerror("Missing template $t");
    }
    my @buff = <TMPL>;
    close TMPL;
    $template = join('', @buff);
  } else {
    my @action_path = split(/::/, $cmddef->{$query->param('cmd')}->{action});
    pop @action_path;
    my $module = join("::", @action_path);
    if ($module eq undef) {
      fatalerror("No module defined for embedded template");
    }
    eval "use $module";
    fatalerror("Unable to load module $module<br><br>$@<br><br>SD:".scriptdir()) if $@;
    {
      no strict 'refs';
      my $tmplcmd = $module.'::xtemplate';
      eval '$template = ($tmplcmd)->($cfg, $query, \%data)';
      fatalerror("Failed to load embedded template, $@") if $@ ne undef;
    }
  }
  if (!($cmddef->{$query->param('cmd')}->{noheader} || $query->param('noheader'))) {
    if (($style ne undef && open(TMPL, "$fn/$style/header.shtml")) || open(TMPL, "$fn/header.shtml")) {
      my @hdr = <TMPL>;
      close TMPL;
      $template = join('', @hdr) . $template;
    }
    if (($style ne undef && open(TMPL, "$fn/$style/footer.shtml")) || open(TMPL, "$fn/footer.shtml")) {
      my @ftr = <TMPL>;
      close TMPL;
      $template .= join('', @ftr);
    }
  }
  return $template;
}
#======================================================================= command

sub command {
  my $cmd = $_[0];
  ++$cmdcnt;
  return undef if $cmdcnt > $MAXCMD;
  if (!defined $cmddef->{$cmd}) {
    fatalerror("Unknown command [$cmd]");
  }
  if ($cmddef->{$cmd}->{access}) {
    if ($cfg->get('_USER') eq undef) {
      $cmd = 'login';
      login('[%This command is available to operator only. Please login.%]');
    }
  }
  my @action_path = split(/::/, $cmddef->{$cmd}->{action});
  my $func = pop @action_path;
  my $module = join("::", @action_path);
  if ($module eq undef) {
    fatalerror("No module defined for [$cmd] action");
  }
  if ($func eq undef) {
    fatalerror("No function defined for [$cmd] action");
  }
  $module =~ /(.*)/; $module = $1;
  eval "use $module";
  fatalerror("Unable to load module $module<br><br>$@<br><br>SD:".scriptdir()) if $@;
  my $markcmd = $cmd;
  {
    no strict 'refs';
    $cmd = ($cmddef->{$cmd}->{action})->($cfg, $query, \%data);
  }
  fatalerror("Recursive call to $cmd") if $cmd eq $markcmd;
  if ($cmd ne undef) {
    $query->param(-name => 'cmd', -value => $cmd);
    command($cmd);
  }
  return undef;
}
#========================================================================= login

sub login {
  $query->param(-name => 'nextcmd', -value => $query->param('cmd'));
  $query->param(-name => 'loginmsg', -value => $_[0]);
  $query->param(-name => 'cmd', -value => 'login');
  $query->param(-name => 'form', -value => '');
}

#==================================================================== fatalerror

sub fatalerror {
  print <<EOT;
Content-type: text/html

<html>
<head><title>Trouble Ticket Express</title></head>
<body>
<br><center><h1>Fatal Error: $_[0]</h1>
</body>
</html>
EOT
  exit;
}
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
# =================================================================== upgrademsg

sub upgrademsg {
  print <<EOT;
<html>
<body>
<br><br>
<center>
The help desk system is temporary unavailable due to scheduled maintenance.
<br><br>
We will resume operations within next 5 minutes.
<br><br>
</center>
</body>
</html>
EOT
}
#=================================================================== readglobals

sub readglobals {
  my @http_cookie = split(/; /,$ENV{'HTTP_COOKIE'});
  my %cookies;
  foreach (@http_cookie) {
    my @parts = split('=',$_);
    my $n = shift @parts;
    my $v = join('=', @parts);
    $cookies{$n}=$v;
  }
  my $cookiename = $cfg->get('cookiename');
  if ($cookies{$cookiename} ne undef) {
    $originalcookie = $cookies{$cookiename};
    my @globals = split (/&/, $cookies{$cookiename});
    foreach (@globals) {
      my @parts = split('=',$_);
      my $n = shift @parts;
      my $v = join('=', @parts);
      $v =~ s/%0D%0A/\n/g;
      $v =~ s/%0A%0D/\n/g;
      $v =~ tr/+/ /;
      $v =~ s/%([A-Fa-f0-9]{2})/pack("c",hex($1))/ge;
      $cfg->set("_GLOBAL_$n", $v);
    }
  }
}
#================================================================= preparecookie

sub preparecookie {
  return undef if $cfg->get('_NOCOOKIE');
  my $cookie;
  foreach my $global (keys %{$cfg}) {
    next if $global !~ /^_GLOBAL_/;
    my $name = $global;
    $name =~ s/^_GLOBAL_//;
    my $value = $cfg->get($global);
    next if $value eq undef;
    $value =~ s/([^a-zA-Z0-9_])/sprintf("%%%X", ord($1))/eg;
    $cookie .= '&' if $cookie ne undef;
    $cookie .= "$name=$value";
  }
  return undef if $cookie eq $originalcookie;
  return "Set-Cookie: ".$cfg->get('cookiename')."=$cookie; path=/; expires=Mon, 28-Dec-2037 00:00:00 GMT\n";
}

# end of file
