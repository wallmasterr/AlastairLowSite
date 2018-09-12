#!/usr/bin/perl
#
# This script is a part of Trouble Ticket Express package
# http://www.troubleticketexpress.com
#
# COPYRIGHT: 2002-2007, United Web Coders
# http://www.unitedwebcoders.com
#
# Version 2.24
#
# $Revision: 446 $
# $Date: 2007-10-11 18:38:03 +0400 (Thu, 11 Oct 2007) $
#
#
# please feel free to uncomment the following line in order to get rid of
# bogus "usage of uninitialized variable" in your error log file, but
# make sure your Perl supports the 'no warnings' pragma
#
# no warnings 'uninitialized';

# ==== NOTHING TO EDIT BELOW THIS LINE. PLS DO NOT CROSS IF NOT SURE ===========

BEGIN {
  print "HTTP/1.0 200 OK\n" if $ENV{PERLXS} eq "PerlIS";
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
    my $dir;
    $dir = $ENV{'SCRIPT_FILENAME'};
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
use TTXConfig;
#
# Read config
#
my $configfile = "ttxcfg.cgi";
my $cfg = TTXConfig->new($configfile);
if ($cfg->error()) {
  print "Content-type: text/html\n\n<html><body>Fatal error: ".$cfg->errortext()."</body></html>\n";
  exit 0;
}
if ($cfg->get('cfgref') ne undef) {
  if (!$cfg->load($cfg->get('cfgref'))) {
    print "Content-type: text/html\n\n<html><body>Fatal error: ".$cfg->errortext()."</body></html>\n";
    exit 0;
  }
}
#
# Check gd library
#
my $nogd;
if ($cfg->get('captchamode') =~ /^\s*alt\s*$/i) {
  $nogd = 1;
} else {
  eval 'use GD';
  if ($@ ne undef) {
    if ($cfg->get('captchamode') =~ /^\s*gd\s*$/i) {
      print <<EOT;
Content-type: text/html

<html>
<body>
Error loading GD.pm
<br>
$@
</body>
</html>
EOT
      exit 0;
    } else {
      $nogd = 1;
    }
  }
}
if (!$nogd && $cfg->get('captchamode') =~ /^\s*random\s*$/i && (rand(10) < 5)) {
  $nogd = 1;
}
#
# Get key
#
my $keyfn = $ENV{QUERY_STRING};
$keyfn =~ /([0-9-]+)$/;
$keyfn = $1;
my $key;
if ($keyfn =~ /^\d+-\d+$/) {
  if (open(KF, $cfg->get('basedir')."/keys/$keyfn.cgi")) {
    $key = <KF>;
    close KF;
    chomp $key;
  }
}
#
# Generate captcha
#
if (!$nogd) {
  my $im = new GD::Image(50,20);
  my $white = $im->colorAllocate(255,255,255);
  my $black = $im->colorAllocate(0,0,0);
  $im->fill(0,0,$white);
  $im->rectangle(0,0,49,19,$black);
  $im->string(GD::gdGiantFont(), 6, 3, $key, $black);
  print "Content-type: image/gif\nExpires: Wed, 13-Dec-1995 16:28:32 GMT\n\n";
  binmode STDOUT;
  print $im->gif();
} else {
  eval 'use TTXCaptcha';
  if ($@ ne undef) {
    print <<EOT;
Content-type: text/html

<html>
<body>
Error loading TTXCaptcha.pm
<br>
$@
</body>
</html>
EOT
    exit 0;
  }
  binmode STDOUT;
  print TTXCaptcha::image($key);
}
#
# Cleanup
#
my $tm = time();
$tm -= 24*3600;
my $dir = $cfg->get('basedir').'/keys';
if (opendir(KEYDIR, $dir)) {
  my @files = grep { /^\d+-\d+\.cgi/ && -f "$dir/$_" } readdir(KEYDIR);
  closedir KEYDIR;
  foreach my $f (@files) {
    $f =~ /^(\d+)/;
    next if $1 > $tm;
    unlink "$dir/$f";
  }
}
