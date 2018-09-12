package TTXUpgrade;
#
# This module is a part of Trouble Ticket Express package
# http://www.troubleticketexpress.com
#
# COPYRIGHT: 2005-2007, United Web Coders
# http://www.unitedwebcoders.com
#
# $Revision: 443 $
# $Date: 2007-10-11 16:27:57 +0400 (Thu, 11 Oct 2007) $
#

$TTXUpgrade::VERSION='2.24';
BEGIN {
  $TTXUpgrade::REVISION = '$Revision: 443 $';
  if ($TTXUpgrade::REVISION =~ /(\d+)/) {
    $TTXUpgrade::REVISION = $1;
  }
};
use strict;
require TTXSetup;

my %upgradepath = (
  '2.182' => { ver => '2.19', code => \&upgrade219 },
  '2.19' => { ver => '2.191', code => \&upgrade2191 },
  '2.191' => { ver => '2.20', code => \&upgrade220 },
  '2.20' => { ver => '2.21', code => \&upgrade221 },
  '2.21' => { ver => '2.22', code => \&upgrade222 },
);

# ====================================================================== upgrade

sub upgrade {
  my $cfg = $_[0];
  my $v = $cfg->get('ttx.version');
  if ($v eq undef) {
    if (-f  $cfg->get('basedir'). "/templates/ticketed.html") {
      $v = '2.182';
    }
  }
  for (my $ver = $upgradepath{$v}; $ver ne undef ; $ver = $upgradepath{$ver->{ver}}) {
    my $err = &{$ver->{code}}($cfg);
    if ($err ne undef) {
      return $err;
    }
    $cfg->set('ttx.version', $ver->{ver});
    $cfg->save();
  }
  return undef;
}

# =================================================================== upgrade219

sub upgrade219 {
  my $cfg = $_[0];
  my $fn = $cfg->get('basedir'). "/templates/header.shtml";
  return "File $fn does not exist" if ! -f $fn;
  return "File $fn is not writable" if ! -w $fn;
  return "Can't open file $fn" if !open(F, "+<$fn");
  flock(F,2);
  my $buff = join('', <F>);
  if ($buff !~ /\btd\.txt\s+\{/) {
    my $addthis = <<EOT;
td.txt  {
  padding-right: 4pt;
  padding-left: 4pt;
  padding-top: 2pt;
  padding-bottom: 1pt;
  border-width:1px;
  border-style:solid;
  border-top-width:0;
  border-bottom-width:0;
  border-right-width:0;
  font-size : 8pt;
  border-color: #FFF;
  color: #666;
  text-align: left;
}
EOT
    $buff =~ s/<\/style>/$addthis\n<\/style>/;
    seek(F,0,0);
    print F $buff;
    truncate(F, tell(F));
  }
  close(F);
  $fn = $cfg->get('basedir'). "/templates/helpdesk.html";
  return "File $fn does not exist" if ! -f $fn;
  return "File $fn is not writable" if ! -w $fn;
  return "Can't open file $fn" if !open(F, "+<$fn");
  flock(F,2);
  $buff = join('', <F>);
  if ($buff =~ /<\s*input\s+type="?hidden"?\s+name="?qwindow"?\s+value="?\(%INPUT_qwindow%\)"?\s*>/) {
    $buff =~ s/<\s*input\s+type="?hidden"?\s+name="?qwindow"?\s+value="?\(%INPUT_qwindow%\)"?\s*>//;
    my $addthis = <<EOT;
        <tr>
          <td align=left>
            <span class=sm>
            Show <input type=text size=3 class=sm name=qwindow value=(%INPUT_qwindow%)> tickets per page.
            Include abstracts <input type=checkbox class=sm name=abstract value=1(%CHECKABSTRACT%)>
            </span>
          </td>
          <td align=right>
            <input type=submit value=Search>&nbsp;<input type=submit name=reset value="Show all">
          </td>
        </tr>
EOT
    my $findthis = '<tr>\s*<td[^>]*><input\s+type="?submit"?[^>]*>[^<]*<input\s+type="?submit"?[^>]*>[^<]*</td>[^<]*</tr>';
    $buff =~ s/$findthis/$addthis\n/i;
    seek(F,0,0);
    print F $buff;
    truncate(F, tell(F));
  }
  close(F);
  $fn = $cfg->get('basedir'). "/templates/ticket.html";
  return "File $fn does not exist" if ! -f $fn;
  return "File $fn is not writable" if ! -w $fn;
  return "Can't open file $fn" if !open(F, "+<$fn");
  flock(F,2);
  $buff = join('', <F>);
  if ($buff =~ /width=700,\s*height=300,\s*resizable/) {
    $buff =~ s/width=700,\s*height=300,\s*resizable/width=700,height=360,resizable/;
    seek(F,0,0);
    print F $buff;
    truncate(F, tell(F));
  }
  close(F);
  $fn = $cfg->get('basedir'). "/templates/answerlib.html";
  return "File $fn does not exist" if ! -f $fn;
  return "File $fn is not writable" if ! -w $fn;
  return "Can't open file $fn" if !open(F, "+<$fn");
  flock(F,2);
  $buff = join('', <F>);
  if ($buff !~ /showcat/) {
    $buff =~ s/-->\s*<\/style>/.lbl { font-size: 9pt; font-weight: 700;}-->\n<\/style>/;
    my $addthis = <<EOT;
<script language=Javascript>
<!--
function showcat(id) {
  location.href='(%ENV_SCRIPT_NAME%)?cmd=answerlib&sid=(%INPUT_sid%)&style=(%INPUT_style%)&cat='+escape(id);
  return false;
}
// -->
</script>
</head>
EOT
    $buff =~ s/<\/head>/$addthis/i;
    $buff =~ s/\(%ANSWERLIBMSG%\)\s*<br>/(%ANSWERLIBMSG%)\n/;
    $addthis = <<EOT;
				  <table cellpadding=1 cellspacing=1>
					  <tr>
						  <td>
                      <select name=cat size=1 OnChange="return showcat(this[this.selectedIndex].value);">
(%CATSELECTOR%)
						</select>
							</td>
						</tr>
						<tr>
						  <td>
                        <select name=answer size=10 OnChange="return showanswer(this[this.selectedIndex].value);">
(%ANSWERSELECTOR%)
                        </select>
							</td>
						</tr>
					</table>
EOT
    $buff =~ s/<select\s+name="?answer"?[^<]*<\/select>/$addthis/i;
    seek(F,0,0);
    print F $buff;
    truncate(F, tell(F));
  }
  close(F);
  $fn = $cfg->get('basedir'). "/templates/newanswer.html";
  return "File $fn does not exist" if ! -f $fn;
  return "File $fn is not writable" if ! -w $fn;
  return "Can't open file $fn" if !open(F, "+<$fn");
  flock(F,2);
  $buff = join('', <F>);
  if ($buff !~ /CATSELECTOR/) {
    $buff =~ s/-->\s*<\/style>/.lbl { font-size: 9pt; font-weight: 700;}-->\n<\/style>/;
    my $addthis = <<EOT;
                <td colspan=2></td>
        </tr>
        <tr>
                <td colspan=2></td>
        </tr>
        <tr>
          <td align=left class=lbl>Select existing category</td>
          <td align=left>
			<select name=cat OnChange="if (this[this.selectedIndex].value) {document.editor.catnew.value = ''}; return false;">
		  	(%CATSELECTOR%)
		  	</select>
		  </td>
        </tr>
        <tr>
                <td align=left class=lbl>or define new one: </td>
                <td align=left><input type=text size=30 name=catnew value="(%INPUT_catnew%)"></td>
        </tr>
        <tr>
                <td colspan=2 valign=top class=lbl>Answer</td>
EOT
    $buff =~ s/<td[^<>]*>\s*Answer\s*<\/td>/$addthis/i;
    seek(F,0,0);
    print F $buff;
    truncate(F, tell(F));
  }
  close(F);
  $fn = $cfg->get('basedir'). "/templates/delanswer.html";
  return "File $fn does not exist" if ! -f $fn;
  return "File $fn is not writable" if ! -w $fn;
  return "Can't open file $fn" if !open(F, "+<$fn");
  flock(F,2);
  $buff = join('', <F>);
  if ($buff !~ /\.lbl/) {
    $buff =~ s/-->\s*<\/style>/.lbl { font-size: 9pt; font-weight: 700;}-->\n<\/style>/;
    seek(F,0,0);
    print F $buff;
    truncate(F, tell(F));
  }
  close(F);
  eval "use TTXLayout";
  if ($@ ne undef) {
    $cfg->set('fltrcols', 'text|subject|oper|status|id');
    $cfg->save();
  } else {
    $cfg->set('fltrcols', 'text|'.$cfg->get('fltrcols'));
  }
  return undef;
}
# =================================================================== upgrade219

sub upgrade2191 {
  my $cfg = $_[0];
  my $fn = $cfg->get('basedir'). "/templates/helpdesk.html";
  return "File $fn does not exist" if ! -f $fn;
  return "File $fn is not writable" if ! -w $fn;
  return "Can't open file $fn" if !open(F, "+<$fn");
  flock(F,2);
  my $buff = join('', <F>);
  if ($buff =~ /<\s*input\s+type="?hidden"?\s+name="?qwindow"?\s+value="?\(%INPUT_qwindow%\)"?\s*>/) {
    $buff =~ s/<\s*input\s+type="?hidden"?\s+name="?qwindow"?\s+value="?\(%INPUT_qwindow%\)"?\s*>//;
    seek(F,0,0);
    print F $buff;
    truncate(F, tell(F));
  }
  close(F);
  return undef;
}
# =================================================================== upgrade220

sub upgrade220 {
  my $cfg = $_[0];
# Disabled in 2.22. Default is do not use cache. Just to avoid problems while
# editing templates.
#  $cfg->set('usecache', 1);
  eval "use TTXSetup";
  if ($@ ne undef) {
    return "Error loading TTXSetup: $@";
  }
  my $v;
  eval '$v = $TTXSetup::VERSION';
  if ($@ ne undef) {
    return "Error reading TTXSetup version: $@";
  }
  if ($v eq undef || $v < 2.20) {
    return "Error: Version mismatch: TTXSetup $v, TTXUpgrade ".$TTXUpgrade::VERSION;
  }
  return TTXSetup::tmplreset($cfg, 'reports.html');
}
# =================================================================== upgrade221

sub upgrade221 {
  return undef;
}
# =================================================================== upgrade222

sub upgrade222 {
  my $cfg = $_[0];
  for my $f ('header.shtml', 'ticketed.html', 'newanswer.html', 'answerlib.html', 'delanswer.html') {
    my $fn = $cfg->get('basedir'). "/templates/$f";
    next if ! -f $fn;
    return "File $fn is not writable" if ! -w $fn;
    return "Can't open file $fn" if !open(F, "+<$fn");
    flock(F,2);
    my $buff = join('', <F>);
    if ($buff !~ /\(%HTML_CHARSET%\)/) {
      $buff =~ s/<head>/<head>\n(%HTML_CHARSET%)/i;
      seek(F,0,0);
      print F $buff;
      truncate(F, tell(F));
    }
    close(F);
  }
  my $fn = $cfg->get('basedir'). "/templates/ticket.html";
  if (-f $fn) {
    return "File $fn is not writable" if ! -w $fn;
    return "Can't open file $fn" if !open(F, "+<$fn");
    flock(F,2);
    my $buff = join('', <F>);
    if ($buff !~ /function preview\(\)/) {
      my $addthis = <<EOT;
<script language="JavaScript"><!--
function preview(){
hwstring="scrollbars=yes,width=600,height=500,resizable=yes,toolbar=no,menubar=no";
var newwin = window.open('', 'winpreview', hwstring);
newwin.focus();
document.forms['preview'].msg.value = document.forms['newticket'].problem.value;
document.forms['preview'].submit();
return false;
}
//--></script>
EOT
      $buff =~ s/<table\s/$addthis<table /i;
    }
    if ($buff !~ /\(%PREVIEW%\)/) {
      $buff =~ s/\(%ANSWERLIB%\)/(%ANSWERLIB%)(%PREVIEW%)/i;
    }
    seek(F,0,0);
    print F $buff;
    if ($buff !~ /value=preview/) {
      print F <<EOT;
<form method="post" action="(%ENV_SCRIPT_NAME%)" id="preview" target="winpreview" >
<input type=hidden name=cmd value=preview>
<input type=hidden name=style value="(%INPUT_style%)">
<input type=hidden name=sid value=(%INPUT_sid%)>
<input type=hidden name=key value=(%INPUT_key%)>
<input type=hidden name=msg>
</form>
EOT
    }
    truncate(F, tell(F));
    close(F);
  }
  my $ccode = TTXSetup::tmplreset($cfg, 'preview.html');
  return $ccode if $ccode ne undef;
  return TTXSetup::tmplreset($cfg, 'roticket.html');
}
1;
#
