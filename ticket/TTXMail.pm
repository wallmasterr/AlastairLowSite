package TTXMail;
#
# This module is a part of Trouble Ticket Express package
# http://www.troubleticketexpress.com
#
# COPYRIGHT: 2003-2007, United Web Coders
# http://www.unitedwebcoders.com
#
# $Revision: 437 $
# $Date: 2007-10-11 16:22:32 +0400 (Thu, 11 Oct 2007) $
#

$TTXMail::VERSION='2.24';
BEGIN {
  $TTXMail::REVISION = '$Revision: 437 $';
  if ($TTXMail::REVISION =~ /(\d+)/) {
    $TTXMail::REVISION = $1;
  }
};

use strict;
use TTXData;
use TTXMarkup;
use TTXCommon;
my $hasb64 = 1;
$hasb64 = 0 unless eval "require MIME::Base64";

my $mailer;
my $smtphost;
my $usesmtp;

my $CRLF    = "\015\012";
my $doemailfix = 0;
# ====================================================================== charset
my $_charset;

sub charset {
  if ($_charset eq undef) {
    $_charset = TTXData::get('CONFIG')->get('charset') || 'ISO-8859-1';
  }
  return $_charset;
}

# ======================================================================= enc

sub enc {
  return $_[0] if $_[0] !~ /[^a-zA-Z0-9 ()[\]_!\/\\{}"';:?<>@#\$%&*\n\r.,-]/;
  return "=?".charset()."?B?".base64($_[0], "")."?=" if !$_[1];
  my $adr = $_[0];
  $adr =~ s/"[^"]*"//;
  $adr =~ s/^[^<]*<//g;
  $adr =~ s/>[^>]*$//g;
  $adr =~ s/^\s+//;
  $adr =~ s/\s+$//;
  my $name = $_[0];
  $name =~ s/<[^>]*>//g;
  $name =~ s/"//g;
  $name =~ s/[a-zA-Z0-9._-]+@[a-zA-Z0-9._-]+//g;
  $name =~ s/^\s+//;
  $name =~ s/\s+$//;
  $name =~ s/\s\s+/ /;
  $name = "=?".charset()."?B?".base64($name, "")."?=" if $name ne undef;
  $name =~ s/\r?\n\r?\s+/ /g;
  my $str;
  if ($name ne undef) {
    $str = "\"$name\" ";
  }
  $str .= "<$adr>";
  return $str;
}
# ========================================================================= smtp

sub smtp {
  if ($usesmtp eq undef) {
    if ($mailer ne undef && -x $mailer) {
      $usesmtp = 0;
    } else {
      $usesmtp = 1;
      unless (eval "require Net::SMTP") { $usesmtp = 0; }
    }
  }
  return $usesmtp;
}
# ===================================================================== sendfile

sub sendfile {
  my ($cfg, $file, $boundary) = @_;
  my $lfn = $file->{localname};
  $lfn =~ s/\\|\///g;  # just to make sure: file always resides in the datadir/files
  $lfn = $cfg->get('basedir')."/files/$lfn";
  if (open(F, $lfn)) {
    binmode(F);
    my ($buff, $rdb);
    while (read(F, $rdb, 4096)) {
      $buff .= $rdb;
    }
    close F;
    return "\n\n--$boundary\nContent-Type: application/octet-stream;\n".
           " name=\"".enc($file->{name}, 0)."\"\n".
           "Content-Transfer-Encoding: base64\nContent-Disposition: attachment;\n".
           " filename=\"".enc($file->{name}, 0)."\"\n\n".
           base64($buff, "\n", 1);
  }
  return "\n\n--$boundary\nContent-Type: application/octet-stream;\n".
         " name=\"error.txt\"\n".
           "Content-Transfer-Encoding: base64\nContent-Disposition: attachment;\n".
           " filename=\"error.txt\"\n\n".
           base64("Failed to attach file ".$file->{name});
}
# ===================================================================== sendmail

sub sendmail {
  my $cfg = TTXData::get('CONFIG');
  $doemailfix = $cfg->get('emailfix');
  if ($cfg->get('broadcast') ne undef) {
    $_[0]->{bcc} = $cfg->get('broadcast');
  }
  $mailer = $cfg->get('mailer');
  $smtphost = $cfg->get('smtp');
  my $html = $_[0]->{msg};
  my $msg = TTXMarkup::strip($html);
  srand($$);
  my $rnd;
  for(my $i = 0; $i < 20; $i++) { $rnd .= int rand 10; }
  my $boundary = "------------$rnd";
  my  $txtboundary = $boundary;
  my $files = $_[0]->{files};
  if ($files ne undef && !int(@{$files})) {
    $files = undef;
  }
  my  $contenttype;
  if ($files ne undef) {
    $contenttype = "MIME-Version: 1.0\nContent-Type: multipart/mixed;\n boundary=\"$boundary\"";
    my $rnd;
    for(my $i = 0; $i < 20; $i++) { $rnd .= int rand 10; }
    $txtboundary = "------------Z$rnd";
  } else {
    $contenttype = "MIME-Version: 1.0\nContent-Type: multipart/alternative;\n boundary=\"$boundary\"";
  }
  my $datetag;
  if ($cfg->get('maildatetag')) {
    my ($sec,$min,$hour,$mday,$mon,$year,$wday) = gmtime(time());
    $year += 1900;
    my @mabbr = qw(Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec);
    my @wabbr = qw(Sun Mon Tue Wed Thu Fri Sat);
    $datetag = "Date: $wabbr[$wday], $mday $mabbr[$mon] $year ".
               sprintf("%02u:%02u:%02u", $hour, $min, $sec).
               " +0000\n";
  }
  if (!smtp()) {
    return 0 if !open(MAIL, "|$mailer -t");
    my $bcc = "Bcc: ".$_[0]->{bcc}."\n" if $_[0]->{bcc} ne undef;
    print MAIL "To: ".$_[0]->{to}."\nFrom: ".enc($_[0]->{from}, 1)."\n".$bcc.
               "Subject: ".enc($_[0]->{subject}, 0).
               "\n$datetag$contenttype\n\n".
               "This is a multi-part message in MIME format\n\n";
    if ($files ne undef) {
      print MAIL "--$boundary\nContent-Type: multipart/alternative;\n boundary=\"$txtboundary\"\n\n";
    }
    print MAIL "--$txtboundary\nContent-type: text/plain; charset=\"".charset()."\"\n".
               "Content-Transfer-Encoding: quoted-printable\n\n".
               quoteit($msg)."\n\n";
    print MAIL "\n\n--$txtboundary\nContent-type: text/html; charset=\"".charset()."\"\n".
                 "Content-Transfer-Encoding: base64\n\n";
    print MAIL base64(htmlpage($html));
    print MAIL "\n--$txtboundary--\n";
    if ($files ne undef) {
      foreach my $file (@{$files}) {
        print MAIL sendfile($cfg, $file, $boundary);
      }
      print MAIL "\n--$boundary--\n";
    }
    print MAIL "\n\n";
    close MAIL;
  } else {
    my $to = $_[0]->{to};
    $to =~ s/"[^"]*"//;
    $to =~ s/^[^<]*<//g;
    $to =~ s/>[^>]*$//g;
    $to =~ s/^\s+//;
    $to =~ s/\s+$//;
    my $from = $_[0]->{from};
    $from =~ s/"[^"]*"//;
    $from =~ s/^[^<]*<//g;
    $from =~ s/>[^>]*$//g;
    $from =~ s/^\s+//;
    $from =~ s/\s+$//;
    if ($cfg->get('smtptrace')) {
      # save original STDERR destination
      open SAVERR, ">&STDERR";
      # redirect STDERR handle to a file
      open STDERR, '>>'.$cfg->get('basedir').'/smtptrace.txt';
      my $oldfh = select STDERR; $| = 1; select($oldfh); # make unbuffered
    }
    my $s = Net::SMTP->new($smtphost, Debug => $cfg->get('smtptrace') ? 1:0);
    if ($s ne undef) {
      if ($cfg->get('smtplogin') ne undef) {
        my $trypop3 = 0;
        if ($s->can('auth')) {
          eval 'use Authen::SASL';
          if ($@ ne undef) {
            if ($cfg->get('smtptrace')) {
              warn $@;
              warn "No SASL";
              $trypop3 = 1;
            }
          } else {
            my $authcode;
            eval "\$authcode = \$s->auth(\$cfg->get('smtplogin'), \$cfg->get('smtppwd'));";
            if ($@ ne undef) {
              $trypop3 = 1;
              if ($cfg->get('smtptrace')) {
                warn $@;
              }
            } elsif (!$authcode) {
              $trypop3 = 1;
              if ($cfg->get('smtptrace')) {
                warn "auth(login, passwd) failed";
              }
            }
          }
        } else {
          $trypop3 = 1;
          if ($cfg->get('smtptrace')) {
              warn "No auth() method";
          }
        }
        if ($trypop3) {
          if ($cfg->get('smtptrace')) {
            warn 'Trying Net::POP3';
          }
          eval "use Net::POP3;";
          if ($@ ne undef) {
            if ($cfg->get('smtptrace')) {
              warn $@;
            }
          } else {
            my $pop = Net::POP3->new($smtphost);
            if (!$pop) { warn "Can't open connection to pop3 server: $!"; }
            elsif (!defined ($pop->login($cfg->get('smtplogin'), $cfg->get('smtppwd')))) {
              warn "Can't authenticate: $!";
            } else {
              my $messages = $pop->list();
              $pop->quit();
            }
          }
        }
      }
      $s->mail($from);
      if ($_[0]->{bcc} ne undef) {
        $s->to($to, $_[0]->{bcc});
      } else {
        $s->to($to);
      }
      $s->data();
      $s->datasend("To: ".$_[0]->{to}."\n");
      $s->datasend("From: ".enc($_[0]->{from}, 1)."\n");
      $s->datasend("Subject: ".enc($_[0]->{subject}, 0).
                   "\n$datetag$contenttype\n\nThis is a multi-part message in MIME format\n\n");
      if ($files ne undef) {
        $s->datasend("--$boundary\nContent-Type: multipart/alternative;\n boundary=\"$txtboundary\"\n\n");
      }
      $s->datasend(	"--$txtboundary\nContent-type: text/plain; charset=\"".charset()."\"\n".
                    "Content-Transfer-Encoding: quoted-printable\n\n".
	                quoteit($msg)."\n\n");
      $s->datasend("--$txtboundary\nContent-type: text/html; charset=\"".charset()."\"\n".
                   "Content-Transfer-Encoding: base64\n\n");
      $s->datasend(base64(htmlpage($html)));
      $s->datasend("\n--$txtboundary--\n\n");
      if ($files ne undef) {
        foreach my $file (@{$files}) {
          $s->datasend(sendfile($cfg, $file, $boundary));
        }
        $s->datasend("\n--$boundary--\n");
      }
      $s->datasend("\n\n");
      $s->dataend();
      $s->quit();
      if ($cfg->get('smtptrace')) {
        # restore original STDERR destination
        open STDERR, ">&SAVERR";
      }
    }
  }
  return 1;
}
# ====================================================================== quoteit

sub quoteit {
  my $in = shift;
  $in = Encode::encode('UTF-8', $in) if TTXCommon::dodec();
  my $out;
  local $_;
  $in =~ s/\015?\012/\n/g;
  while (1) {
    $in =~ s/^(.*?(?:(?:\n)|\Z))//m;
    $_ = $1;
    (defined and length) or last;
    s/([^ \t\n!-<>-~])/sprintf("=%02X", ord($1))/eg;
    s/([ \t]+)$/join('', map { sprintf("=%02X", ord($_)) } split('', $1))/egm;
    my $brokenlines = "";
    $brokenlines .= "$1=\n"
    while s/(.*?^[^\n]{73} (?:
         [^=\n]{2} (?! [^=\n]{0,1} $)
         |[^=\n]    (?! [^=\n]{0,2} $)
         |          (?! [^=\n]{0,3} $)
         ))//xsm;
    $_ = "$brokenlines$_";
    if (length($_) < 74) {
      s/^\.$/=2E/g;
      s/^From /=46rom /g;
    }
    s/\015?\012/$CRLF/g;
    $out .= $_;
    (defined($in) and length($in)) or last;
  }
  $out =~ s/\015//g if $doemailfix;
  return $out;
}
# ======================================================================= base64

sub base64 {
  my $in = $_[0];
  my $isfile = $_[2];
  my $out;
  my $eol = $_[1];
  $eol = "\n" unless defined $eol;
  $in = TTXCommon::encodeit($in) if !$isfile && TTXCommon::dodec();
  while (1) {
    my ($buf, $b64);
    last unless length $in;
    $buf = substr($in, 0, 45);
    substr($in, 0, 45) = '';
    if ($hasb64) {
      $b64 = MIME::Base64::encode_base64($buf, $eol);
    } else {
      $b64 = _b64($buf, $eol);
    }
    $b64 =~ s/\015?\012/$CRLF/g;
    $b64 .= $CRLF if length $eol && $b64 !~ /$CRLF\Z/;
    $out .= $b64;
  }
  return $out;
}
# ========================================================================= _b64
sub _b64 {
  my $out = "";
  my $eol = $_[1];
  $eol = "\n" unless defined $eol;
  pos($_[0]) = 0;
  while ($_[0] =~ /(.{1,45})/gs) {
    $out .= substr(pack('u', $1), 1);
    chop($out);
  }
  $out =~ tr|` -_|AA-Za-z0-9+/|;
  my $padding = (3 - length($_[0]) % 3) % 3;
  $out =~ s/.{$padding}$/'=' x $padding/e if $padding;
  if (length $eol) {
    $out =~ s/(.{1,76})/$1$eol/g;
  }
  return $out;
}
# ===================================================================== htmlpage

sub htmlpage {
  my $pg = $_[0];
  $pg =~ s/\r//g;
  $pg =~ s/\n/<br \/>\n/g;
  $pg = TTXMarkup::html($pg);
  my $buff = <<EOT;
<html>
<head>
<style type="text/css">
.dummy {}
body, td {font-family: verdana,arial,helvetica,sans-serif;font-size: 10pt;color: #000000;}
</style>
</head>
<body>
$pg
</body>
</html>
EOT
  return $buff;
}
1;
#
