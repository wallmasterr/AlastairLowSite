package TTXSetup;
#
# This module is a part of Trouble Ticket Express package
# http://www.troubleticketexpress.com
#
# COPYRIGHT: 2002-2007, United Web Coders
# http://www.unitedwebcoders.com
#
# $Revision: 453 $
# $Date: 2007-11-05 08:01:29 +0300 (Mon, 05 Nov 2007) $
#

$TTXSetup::VERSION='2.24';
BEGIN {
  $TTXSetup::REVISION = '$Revision: 453 $';
  if ($TTXSetup::REVISION =~ /(\d+)/) {
    $TTXSetup::REVISION = $1;
  }
};
use TTXConfig;
require TTXCommon;
require TTXUser;
use strict;

my $cfg = {};
my $query = {};
my $ttpreview = <<EOT;
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.0 Transitional//EN"
"http://www.w3.org/TR/REC-html40/loose.dtd">
<html>
<head>
<meta http-equiv="Content-Type" content="text/html; charset=[%CHARSET%]">
<style type="text/css">
body, td { font-family: Verdana, Helvetica, sans-serif; font-size: 10pt;}
A       { color : #2E3197; text-decoration : none; }
A:Hover { color : #C00; text-decoration : underline;}
.sm {font-size: 8pt;}
.tiny {font-size: 4pt;}
.heading {font-size: 13pt;font-weight: 700; color: #2E3197;}
.lbl { font-size: 9pt; font-weight: 700;}
td.error  {
  background-color: #FFC;
  padding-right: 5pt;
  padding-left: 5pt;
  padding-top: 3pt;
  padding-bottom: 3pt;
  border-width:1px;
  border-style:solid;
  border-color: #996;
  font-weight: 700;
  color: #F00;
}
td.trow  {
  padding-right: 2pt;
  padding-left: 2pt;
  border-style:solid;
  border-bottom-width:2px;
  border-right-width: 0px;
  border-left-width:1px;
  border-top-width:0;
  border-color: #FFF;
  background-color: #CCC;
  text-align: center;
  font-size : 11px;
  font-weight: 700;
}
td.orow  {
  padding-right: 4pt;
  padding-left: 4pt;
  padding-top: 2pt;
  padding-bottom: 1pt;
  border-width:1px;
  border-style:solid;
  border-top-width:0;
  border-bottom-width:0;
  border-right-width:0;
  font-size : 11px;
  border-color: #FFF;
}
td.erow  {
  padding-right: 4pt;
  padding-left: 4pt;
  padding-top: 2pt;
  padding-bottom: 1pt;
  border-width:1px;
  border-style:solid;
  border-top-width:0;
  border-bottom-width:0;
  border-right-width:0;
  font-size : 11px;
  border-color: #FFF;
}
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
  font-size : 11px;
  border-color: #FFF;
  color: #666;
  text-align: left;
}
td.omsg  {
  background-color: #EEE;
  padding-right: 3pt;
  padding-left: 3pt;
  padding-top: 2pt;
  padding-bottom: 2pt;
  border-width:1px;
  border-style:solid;
  border-color: #FFF;
}
td.imsg  {
  background-color: #EEE;
  padding-right: 3pt;
  padding-left: 3pt;
  padding-top: 2pt;
  padding-bottom: 2pt;
  border-width:1px;
  border-style:solid;
  border-color: #FFF;
}
td.cmsg  {
  background-color: #D0D0D0;
  padding-right: 3pt;
  padding-left: 3pt;
  padding-top: 2pt;
  padding-bottom: 2pt;
  border-width:1px;
  border-style:solid;
  border-color: #FFF;
}
</style>
<title>[%Message Preview%]</title>
</head>
<body>
<center>
<table width="90%" cellpadding=0 cellspacing=0>
        <tr>
                <td class=heading align=left nowrap>(%PAGEHEADING%)</td>
        </tr>
</table>
<br class=tiny>
<table width="90%" cellpadding=0 cellspacing=0>
        <tr>
                <td style="background-color: #CCC;"><img src="(%CONFIG_IMGURL%)/dot.gif" width="100%" height=2></td>
        </tr>
</table>
<table width="90%" cellspacing=0 cellpadding=0 bgcolor="#CFDCE8" style="padding-left: 5px; padding-right: 5px">
  <tr>
    <td align=left>
<br class=tiny>
    (%MESSAGE%)
<br class=tiny>
<br class=tiny>
    </td>
  </tr>
</table>
<table width="90%" cellpadding=0 cellspacing=0>
        <tr>
                <td style="background-color: #CCC;"><img src="(%CONFIG_IMGURL%)/dot.gif" width="100%" height=2></td>
        </tr>
</table>
<br class=tiny>
<table width="90%" cellpadding=0 cellspacing=0>
        <tr>
                <td align=right><input type=submit value="[%Close Window%]" onclick="window.close()" />
                </td>
        </tr>
</table>
</center>
</body>
</html>
EOT

my $ttshowitem = <<EOT;
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.0 Transitional//EN"
"http://www.w3.org/TR/REC-html40/loose.dtd">
<html>
<head>
<meta http-equiv="Content-Type" content="text/html; charset=[%CHARSET%]">
<title>(%ITEMLABEL%) (%ITEM_TITLE%)</title>
<style type="text/css">
<!--
body, td, p { font-family: Verdana, Helvetica, sans-serif; font-size: 10pt;}
-->
</style>
<script language=Javascript>
<!--
function closeme()
{
 //parentisticket = (%INPUT_isticket%);
 //if (parentisticket) {
 //  msg = opener.newticket.problem.value;
 //  opener.location.href = "(%ENV_SCRIPT_NAME%)?cmd=ticket&sid=(%INPUT_sid%)&key=(%TICKET_key%)&problem="+escape(msg);
 // }
 // else {
 //  opener.update();
 // }
 window.close();
 return false;
}
//-->
</script>
</head>
<body>
<center>
<font color=red><b>(%ERROR_MESSAGE%)</b></font><font color=blue><b>(%MESSAGE%)</b></font>
<form action="(%ENV_SCRIPT_NAME%)" method=post>
<input type=hidden name=sid value="(%INPUT_sid%)">
<input type=hidden name=isticket value="(%INPUT_isticket%)">
<input type=hidden name=cmd value=showitem>
<input type=hidden name=style value="(%INPUT_style%)">
<input type=hidden name=id value="(%INPUT_id%)">
<input type=hidden name=do value=1>
<table cellspacing=0 cellpadding=5>
  <td colspan=3 align=left>
  <b><font size="+1">(%ITEM_TITLE%)</font></b>
  </td>
  </tr>
  <tr>
  <td align=center><img src="(%ITEM_IMG%)"></td>
  <td align=left><nobr><b>[%Status%]:</b> <img src="(%ITEM_STATUS_IMG%)"> (%STATUS_SELBOX%)</nobr></td>
  <td align=right><input type=submit value="[%Update%]">
  <input type=submit class=button onClick="return closeme()" value="[%Close Window%]"></td>
  </tr>
  <tr>
  <td colspan=3 align=left>
  <b>[%Notes%]</b><br>
  (%ITEM_QNOTES%)
  </td>
  </tr>
  <tr>
  <td colspan=3 align=left>
  <b><small>[%add notes%]</small></b><br>
  <textarea wrap=virtual cols=70 name=notes rows=6>(%QNOTES%)</textarea>
  </td>
  </tr>
  <tr>
  <td colspan=3 align=center>
<input type=submit value="[%Update%]">
<input type=submit class=button onClick="return closeme()" value="[%Close Window%]">
  </td>
  </tr>
</table>
</form>
</center>
</body>
</html>
EOT

my $ttdashboard = <<EOT;
<script language="JavaScript"><!--
function showitem(ID){ hwstring="scrollbars=yes,width=650,height=350,resizable=yes,toolbar=no,menubar=no"; var newwin = window.open("(%ENV_SCRIPT_NAME%)?cmd=showitem&id=" + ID + "&sid=(%INPUT_sid%)&style=(%INPUT_style%)&update=1", "ItemInfo", hwstring); return false; }
//--></script>
<script language="JavaScript"><!--
function rowhl(id, inrow) {
  var row = document.getElementById('tr'+id);
  var odd = id % 2;
  var c = (odd) ? '#EEEEEE' : '#CCCCCC';
  row.style.backgroundColor = (inrow) ? '#FFFFD9' : c;
}
//--></script>
<style type="text/css">
td.top   {
border-style:solid;
border-color: #CCC;
border-bottom-width:0px;
border-right-width:0px;
border-left-width:0px;
border-top-width:1px;
}
td.topr   {
border-style:solid;
border-color: #CCC;
border-bottom-width:0px;
border-right-width:1px;
border-left-width:0px;
border-top-width:1px;
}
td.topl   {
border-style:solid;
border-color: #CCC;
border-bottom-width:0px;
border-right-width:0px;
border-left-width:1px;
border-top-width:1px;
}
td.r   {
border-style:solid;
border-color: #CCC;
border-bottom-width:0px;
border-right-width:1px;
border-left-width:0px;
border-top-width:0px;
}
td.btmrl   {
border-style:solid;
border-color: #CCC;
border-bottom-width:1px;
border-right-width:1px;
border-left-width:1px;
border-top-width:0px;
}
</style>
<table width=(%HTMLBASEWIDTH%) cellspacing=0 cellpadding=5>
(%ITEMLIST%)
</table>
EOT

my $ttlogin = <<EOT;
<table width=(%HTMLBASEWIDTH%) cellspacing=0 cellpadding=0 bgcolor="#CFDCE8">
        <tr>
                <td align=center>
<br><b>(%INPUT_loginmsg%)</b><br class=tiny><br class=tiny>
<table cellpadding=3 cellspacing=0>
<form method=post action="(%ENV_SCRIPT_NAME%)">
<input type=hidden name=cmd value=login>
<input type=hidden name=dologin value=1>
<input type=hidden name=nextcmd value="(%INPUT_nextcmd%)">
<input type=hidden name=style value="(%INPUT_style%)">
<input type=hidden name=tk value="(%INPUT_tk%)">
        <tr>
                <td align=right class=lbl>[%User ID%]</td>
                <td align=left><input type=text style="font-family: Verdana, Geneva, Helvetica, sans-serif; font-size: 10pt;" name=login value="(%INPUT_login%)"></td>
        </tr>
        <tr>
                <td align=right class=lbl>[%Password%]</td>
                <td align=left><input type=password style="font-family: Verdana, Geneva, Helvetica, sans-serif; font-size: 10pt;" name=passwd value="(%INPUT_passwd%)"></td>
        </tr>
        <tr>
                <td colspan=2 align=right><input type=submit class=button value="[%Login%]"><br class=tiny><br class=tiny></td>
        </tr>
        </form>
</table>
                </td>
        </tr>
</table>
EOT

my $ttorderalib =<<EOT;
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.0 Transitional//EN"
"http://www.w3.org/TR/REC-html40/loose.dtd">
<html>
<head>
<title>Answer library</title>
<style type="text/css">
<!--
body, td, p { font-family: Verdana, Helvetica, sans-serif; font-size: 10pt;}
-->
</style>
</head>
<body>
<br>
<b>Answer Library</b> module is not installed on your server.
<br><br>
The module allows organizing answers to common questions. Your staff can quickly access canned
answers for instant solutions that save problem-resolution time. New staff members will benefit
from the canned answer library for training, enabling them to hit the ground running and be
productive right from their first day.
<br><br>
You may see the Answer Library module in action through our
<a href="http://www.troubleticketexpress.com/trouble-ticket-demo.html" target=_blank><b><nobr>demo help desk</nobr></b></a>.
<br><br>
For more detailed description and ordering info please refer to
<a href="http://www.troubleticketexpress.com/canned-answers.html" target=_blank><b><nobr>Answer Library page</nobr></b></a>.
</body>
</html>
EOT

my $ttheader =<<EOT;
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.0 Transitional//EN"
"http://www.w3.org/TR/REC-html40/loose.dtd">
<html>
<head>
<meta http-equiv="Content-Type" content="text/html; charset=[%CHARSET%]">
<style type="text/css">
body, td { font-family: Verdana, Helvetica, sans-serif; font-size: 10pt;}
A       { color : #2E3197; text-decoration : none; }
A:Hover { color : #C00; text-decoration : underline;}
.sm {font-size: 11px;}
.tiny {font-size: 4pt;}
.heading {font-size: 13pt;font-weight: 700; color: #2E3197;}
.lbl { font-size: 9pt; font-weight: 700;}
td.error  {
  background-color: #FFC;
  padding-right: 5pt;
  padding-left: 5pt;
  padding-top: 3pt;
  padding-bottom: 3pt;
  border-width:1px;
  border-style:solid;
  border-color: #996;
  font-weight: 700;
  color: #F00;
}
td.trow  {
  padding-right: 2pt;
  padding-left: 2pt;
  border-style:solid;
  border-bottom-width:2px;
  border-right-width: 0px;
  border-left-width:1px;
  border-top-width:0;
  border-color: #FFF;
  background-color: #CCC;
  text-align: center;
  font-size : 11px;
  font-weight: 700;
}
td.orow  {
  padding-right: 4pt;
  padding-left: 4pt;
  padding-top: 2pt;
  padding-bottom: 1pt;
  border-width:1px;
  border-style:solid;
  border-top-width:0;
  border-bottom-width:0;
  border-right-width:0;
  font-size : 11px;
  border-color: #FFF;
}
td.erow  {
  padding-right: 4pt;
  padding-left: 4pt;
  padding-top: 2pt;
  padding-bottom: 1pt;
  border-width:1px;
  border-style:solid;
  border-top-width:0;
  border-bottom-width:0;
  border-right-width:0;
  font-size : 11px;
  border-color: #FFF;
}
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
  font-size : 11px;
  border-color: #FFF;
  color: #666;
  text-align: left;
}
td.omsg  {
  background-color: #E8E8CF;
  padding-right: 3pt;
  padding-left: 3pt;
  padding-top: 2pt;
  padding-bottom: 2pt;
  border-width:1px;
  border-style:solid;
  border-color: #FFF;
}
td.imsg  {
  background-color: #E8E8E8;
  padding-right: 3pt;
  padding-left: 3pt;
  padding-top: 2pt;
  padding-bottom: 2pt;
  border-width:1px;
  border-style:solid;
  border-color: #FFF;
}
td.cmsg  {
  background-color: #E8DCCF;
  padding-right: 3pt;
  padding-left: 3pt;
  padding-top: 2pt;
  padding-bottom: 2pt;
  border-width:1px;
  border-style:solid;
  border-color: #FFF;
}
</style>
<title>(%CONFIG_COMPANY%)</title>
</head>
<body>
<center>
<table width=(%HTMLBASEWIDTH%) cellpadding=0 cellspacing=0>
        <tr>
                <td align=left><span class=sm><font color="#AAAAAA"><b>(%LOGGEDAS%)</b></font></span></td>
                <td align=right class=sm>
                        (%HOMELINK%) (%DASHBOARDLINK%) <a href="(%ENV_SCRIPT_NAME%)?cmd=(%HELPDESKCMD%)&sid=(%INPUT_sid%)&style=(%INPUT_style%)">[%Tickets%]</a> | <a href="(%ENV_SCRIPT_NAME%)?cmd=newticket&sid=(%INPUT_sid%)&style=(%INPUT_style%)">[%Contact us%]</a> | (%LOGINLOGOUT%)
                </td>
        </tr>
</table>
<table width=(%HTMLBASEWIDTH%) cellpadding=0 cellspacing=0>
        <tr>
                <td class=heading align=left nowrap>(%PAGEHEADING%)</td>
        </tr>
</table>
<br class=tiny>
<table width=(%HTMLBASEWIDTH%) cellpadding=0 cellspacing=0>
        <tr>
                <td style="background-color: #CCC;"><img src="(%CONFIG_IMGURL%)/dot.gif" width=(%HTMLBASEWIDTH%) height=2></td>
        </tr>
</table>
(%ERROR_BOX%)
EOT

my $ttfooter =<<EOT;
<table width=(%HTMLBASEWIDTH%) cellpadding=0 cellspacing=0>
        <tr>
                <td style="background-color: #CCC;"><img src="(%CONFIG_IMGURL%)/dot.gif" width=(%HTMLBASEWIDTH%) height=2></td>
        </tr>
        <tr>
                <td><img src="(%CONFIG_IMGURL%)/dot.gif" width=(%HTMLBASEWIDTH%) height=2></td>
        </tr>
        <tr>
                <td align=left class=sm><font color="777777"><a href="http://www.troubleticketexpress.com"
                style="color : #666;">Help desk software</a> by <a href="http://www.unitedwebcoders.com"
                style="color : #666;">United Web Coders</a> rev. (%VERSION%) (%ISPRO%)</font> (%CHECKUPDATE%)</td>
        </tr>
</table>
</center>
</body>
</html>
EOT

my $tthelpdesk =<<EOT;
<script language="JavaScript"><!--
function ticked(ID){ hwstring="scrollbars=yes,width=450,height=(%TICKEDHEIGHT%),resizable=yes,toolbar=no,menubar=no"; var newwin = window.open("(%ENV_SCRIPT_NAME%)?cmd=ticketed&tid=" + ID + "&sid=(%INPUT_sid%)", "TicketEditor", hwstring); }
//--></script>
<script language="JavaScript"><!--
function showitem(ID){ hwstring="scrollbars=yes,width=650,height=350,resizable=yes,toolbar=no,menubar=no"; var newwin = window.open("(%ENV_SCRIPT_NAME%)?cmd=showitem&id=" + ID + "&sid=(%INPUT_sid%)&style=(%INPUT_style%)&isticket=0", "ItemInfo", hwstring); return false; }
//--></script>
<script language="JavaScript"><!--
function setsort(orderby, direction)
{
 document.forms['hd'].qoffset.value='0';
 document.forms['hd'].qsort.value=orderby;
 document.forms['hd'].qsortorder.value=direction;
 document.forms['hd'].submit();
 return false;
}
//--></script>
<script language=Javascript> <!--
function update()
{
 document.forms['hd'].submit();
 return false;
}
var htimeout = null;
function setrefreshrate(tmout) {
  if (htimeout != null) {
    clearTimeout(htimeout);
    htimeout = null;
  }
  if (tmout > 0) {
    htimeout = setTimeout(update, tmout * 1000);
  }
}
//-->
</script>
<script language="JavaScript"><!--
function scroll(off, win)
{
 document.forms['hd'].qoffset.value=off;
 document.forms['hd'].qwindow.value=win;
 document.forms['hd'].submit();
 return false;
}
//--></script>
<script language="JavaScript"><!--
function rowhl(id, inrow) {
  var row = document.getElementById('tr'+id);
  var odd = id % 2;
  var c = (odd) ? '#F0F0E1' : '#E8E8CF';
  row.style.backgroundColor = (inrow) ? '#FFFFD9' : c;
}
//--></script>
<script language="javascript"><!--
function SelectDeselectAll(strCheck) {
	var elements = document.forms["ticketlist"].elements;
    for (var i = 0; i < elements.length; i++) {
      if (elements[i].type == 'checkbox' && elements[i].name == 'tid') {
        elements[i].checked = strCheck;
      }
    }
}
//--></script>
<table width=(%HTMLBASEWIDTH%) cellspacing=0 cellpadding=0 bgcolor="#C6D7CF">
<form method=post action="(%ENV_SCRIPT_NAME%)" name=hd>
<input type=hidden name=cmd value=(%INPUT_cmd%)>
<input type=hidden name=style value="(%INPUT_style%)">
<input type=hidden name=sid value=(%INPUT_sid%)>
<input type=hidden name=do value=1>
<input type=hidden name=emailkey value=(%INPUT_emailkey%)>
<input type=hidden name=qsort value="(%INPUT_qsort%)">
<input type=hidden name=qsortorder value="(%INPUT_qsortorder%)">
<input type=hidden name=qoffset value=(%INPUT_qoffset%)>
        <tr>
                <td class=tiny>&nbsp</td>
        </tr>
        <tr>
                <td>(%TICKETFILTER%)</td>
        </tr>
        <tr>
                <td class=tiny>&nbsp</td>
        </tr>
</table>
<br class=tiny>
<table width=(%HTMLBASEWIDTH%) cellspacing=0 cellpadding=0>
        <tr>
          <td align=left>
            <span class=sm>
            [%Show%] <input type=text size=3 class=sm name=qwindow value=(%INPUT_qwindow%)> [%tickets per page.%]
            [%Include abstracts%] <input type=checkbox class=sm name=abstract value=1(%CHECKABSTRACT%)>
            &nbsp;&nbsp;[%Autorefresh rate%] <select name=autorefresh onchange="setrefreshrate(this.options[this.selectedIndex].value)">
              <option value="0">[%never%]</option>
              <option value="60">[%1 min%]</option>
              <option value="180">[%3 min%]</option>
              <option value="300">[%5 min%]</option>
              <option value="600">[%10 min%]</option>
            </select>
<script type="text/javascript"><!--
  var i;
  var inauto = '(%INPUT_autorefresh%)';
  if (inauto == '') {
    inauto = '(%CONFIG_AUTOREFRESH%)';
  }
	for (i = 0; i < document.forms['hd'].autorefresh.options.length; i++) {
	  if (document.forms['hd'].autorefresh.options[i].value == inauto) {
	    document.forms['hd'].autorefresh.options[i].selected = true;
      setrefreshrate(document.forms['hd'].autorefresh.options[i].value);
	  }
	}
	//--></script>
            </span>
          </td>
          <td align=right>
            <input type=submit value="[%Search%]">&nbsp;<input type=submit name=reset value="[%Show all%]">
          </td>
        </tr>
        </form>
</table>
<br class=tiny>
<table width=(%HTMLBASEWIDTH%) cellspacing=0 cellpadding=0 >
(%TICKETLIST%)
</table>
<br class=tiny>
EOT

my $ttreports =<<EOT;
<table width=(%HTMLBASEWIDTH%) cellspacing=0 cellpadding=0 bgcolor="#C6D7CF">
<form method=post action="(%ENV_SCRIPT_NAME%)">
<input type=hidden name=cmd value=(%INPUT_cmd%)>
<input type=hidden name=style value="(%INPUT_style%)">
<input type=hidden name=sid value=(%INPUT_sid%)>
<input type=hidden name=do value=1>
        <tr>
                <td class=tiny>&nbsp</td>
        </tr>
        <tr>
                <td align="left">(%REPORTQUERY%)</td>
        </tr>
        <tr>
                <td>(%TICKETFILTER%)</td>
        </tr>
        <tr>
                <td class=tiny>&nbsp</td>
        </tr>
</table>
<br class=tiny>
<table width=(%HTMLBASEWIDTH%) cellspacing=0 cellpadding=0>
 <tr>
  <td align=right>
   <input type=submit value="[%Build Report%]">
  </td>
 </tr>
</form>
</table>
<br class=tiny>
<table width=(%HTMLBASEWIDTH%) cellspacing=0 cellpadding=0 >
(%REPORT%)
</table>
<br class=tiny>
EOT

my $ttmarkuphelp =<<EOT;
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.0 Transitional//EN"
"http://www.w3.org/TR/REC-html40/loose.dtd">
<html>
<head>
<meta http-equiv="Content-Type" content="text/html; charset=[%CHARSET%]">
<title>[%Markup Quick Guide%]</title>
<style type="text/css">
<!--
body, td, p {
    font-family: Verdana, Helvetica, sans-serif;
    font-size: 10pt;
}
-->
</style>
</head>
<body>
<center>
<table cellspacing=0 cellpadding=6 style="border-style:solid; border-width:1px; border-color: #CCC;">
        <tr>
                <td style="border-style:solid; border-width:1px; border-color: #CCC;">
                        [b] Sample text [/b]
                </td>
                <td style="border-style:solid; border-width:1px; border-color: #CCC;">
                        <b> Sample text </b>
                </td>
        </tr>
        <tr>
                <td style="border-style:solid; border-width:1px; border-color: #CCC;">
                        [i] Sample text [/i]
                </td>
                <td style="border-style:solid; border-width:1px; border-color: #CCC;">
                        <i> Sample text </i>
                </td>
        </tr>
        <tr>
                <td style="border-style:solid; border-width:1px; border-color: #CCC;">
                        [u] Sample text [/u]
                </td>
                <td style="border-style:solid; border-width:1px; border-color: #CCC;">
                        <u> Sample text </u>
                </td>
        </tr>
        <tr>
                <td style="border-style:solid; border-width:1px; border-color: #CCC;">
                        [code] Sample text [/code]
                </td>
                <td style="border-style:solid; border-width:1px; border-color: #CCC;">
                        <code> Sample text </code>
                </td>
        </tr>
        <tr>
                <td style="border-style:solid; border-width:1px; border-color: #CCC;">
                        [url http://www.troubleticketexpress.com]Trouble Ticket Express[/url]
                </td>
                <td style="border-style:solid; border-width:1px; border-color: #CCC;">
                        <a href="http://www.troubleticketexpress.com" target=_blank>Trouble Ticket Express</a>
                </td>
        </tr>
        <tr>
                <td style="border-style:solid; border-width:1px; border-color: #CCC;">
                        [img http://www.helpdeskconnect.com/i/sml.gif]
                </td>
                <td style="border-style:solid; border-width:1px; border-color: #CCC;">
                        <img src="http://www.helpdeskconnect.com/i/sml.gif">
                </td>
        </tr>
        <tr>
                <td style="border-style:solid; border-width:1px; border-color: #CCC;">
                        [(]
                </td>
                <td style="border-style:solid; border-width:1px; border-color: #CCC;">
                        [
                </td>
        </tr>
</table>
</center>
</body>
</html>
EOT

my $ttprint =<<EOT;
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.0 Transitional//EN"
"http://www.w3.org/TR/REC-html40/loose.dtd">
<html>
<head>
<meta http-equiv="Content-Type" content="text/html; charset=[%CHARSET%]">
<style type="text/css">
body, td { font-family: Verdana, Helvetica, sans-serif; font-size: 10pt;}
A       { color : #2E3197; text-decoration : none; }
A:Hover { color : #C00; text-decoration : underline;}
.sm {font-size: 8pt;}
.tiny {font-size: 4pt;}
.heading {font-size: 13pt;font-weight: 700; color: #2E3197;}
.lbl { font-size: 9pt; font-weight: 700;}
td.error  {
  background-color: #FFC;
  padding-right: 5pt;
  padding-left: 5pt;
  padding-top: 3pt;
  padding-bottom: 3pt;
  border-width:1px;
  border-style:solid;
  border-color: #999;
  font-weight: 700;
  color: #F00;
}
td.trow  {
  padding-right: 2pt;
  padding-left: 2pt;
  border-style:solid;
  border-bottom-width:1px;
  border-right-width: 0px;
  border-left-width:1px;
  border-top-width:0;
  border-color: #999;
  background-color: #CCC;
  text-align: center;
  font-size : 8pt;
  font-weight: 700;
}
td.orow  {
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
  border-color: #999;
}
td.erow  {
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
  border-color: #999;
}
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
  border-color: #999;
  color: #666;
  text-align: left;
}
td.omsg  {
  background-color: #FFF;
  padding-right: 3pt;
  padding-left: 3pt;
  padding-top: 2pt;
  padding-bottom: 2pt;
  border-width:1px;
  border-style:solid;
  border-color: #999;
}
td.imsg  {
  background-color: #FFF;
  padding-right: 3pt;
  padding-left: 3pt;
  padding-top: 2pt;
  padding-bottom: 2pt;
  border-width:1px;
  border-style:solid;
  border-color: #999;
}
td.cmsg  {
  background-color: #FFF;
  padding-right: 3pt;
  padding-left: 3pt;
  padding-top: 2pt;
  padding-bottom: 2pt;
  border-width:1px;
  border-style:solid;
  border-color: #999;
}
</style>
<title>(%CONFIG_COMPANY%)</title>
</head>
<body>
<table width=(%PRINTBASEWIDTH%) cellpadding=0 cellspacing=0>
        <tr>
                <td class=heading align=left nowrap>(%PAGEHEADING%)</td>
        </tr>
</table>
<br class=tiny>
<table width=(%PRINTBASEWIDTH%) cellpadding=0 cellspacing=0>
        <tr>
                <td style="background-color: #CCC;"><img src="(%CONFIG_IMGURL%)/dot.gif" width=(%PRINTBASEWIDTH%) height=2></td>
        </tr>
</table>
(%ERROR_BOX%)
<table width=(%PRINTBASEWIDTH%) cellspacing=0 cellpadding=0 bgcolor="white" style="padding-left: 5px; padding-right: 5px">
        <tr>
                <td align=left class=lbl>[%Subject%]</td>
                <td>&nbsp;&nbsp;</td>
                <td align=left>(%TICKET_subject%)</td>
                <td align=left class=lbl>[%(%CONFIG_GRPSELLBL%)%]</td>
                <td>&nbsp;&nbsp;</td>
                <td align=left>(%TICKET_GROUP%)</td>
        </tr>
        <tr>
                <td align=left class=lbl>[%Status%]</td>
                <td>&nbsp;&nbsp;</td>
                <td align=left width=90%>(%TICKET_status%)</td>
                <td align=left class=lbl>[%Operator%]</td>
                <td>&nbsp;&nbsp;</td>
                <td align=left>(%TICKET_oper%)</td>
        </tr>
        <tr>
                <td align=left class=lbl>[%Created%]</td>
                <td>&nbsp;&nbsp;</td>
                <td align=left>(%TICKET_open%)</td>
                <td align=left class=lbl>[%Customer%]</td>
                <td>&nbsp;&nbsp;</td>
                <td align=left><nobr>(%TICKET_name%) ((%TICKET_email%))</nobr></td>
        </tr>
        <tr>
                <td align=left class=lbl>[%Solved%]</td>
                <td>&nbsp;&nbsp;</td>
                <td align=left>(%TICKET_closed%)</td>
                <td align=left class=lbl><nobr>[%Access key%]</nobr></td>
                <td>&nbsp;&nbsp;</td>
                <td align=left>(%TICKET_key%)</td>
        </tr>
        <tr>
                <td colspan=6 class=tiny>&nbsp;</td>
        </tr>
</table>
<table width=(%PRINTBASEWIDTH%) cellspacing=0 cellpadding=5>
        <tr>
                <td align=left>(%INPUT_notes%)</td>
         </tr>
</table>
<table width=(%PRINTBASEWIDTH%) cellspacing=0 cellpadding=0>
(%MESSAGES%)
        <tr>
                <td colspan=2 class=tiny>&nbsp;</td>
        </tr>
</table>
<table width=(%PRINTBASEWIDTH%) cellpadding=0 cellspacing=0>
        <tr>
                <td style="background-color: #CCC;"><img src="(%CONFIG_IMGURL%)/dot.gif" width=(%PRINTBASEWIDTH%) height=2></td>
        </tr>
</table>
</body>
</html>
EOT

my $ttannotate =<<EOT;
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.0 Transitional//EN"
"http://www.w3.org/TR/REC-html40/loose.dtd">
<html>
<head>
<meta http-equiv="Content-Type" content="text/html; charset=[%CHARSET%]">
<title>Annotate Ticket</title>
<style type="text/css">
<!--
body, td, p { font-family: Verdana, Helvetica, sans-serif; font-size: 10pt;}
-->
</style>
</head>
<body>
<center>
<font color=red><b>(%ERROR_MESSAGE%)</b></font><font color=blue><b>(%MESSAGE%)</b></font>
<table cellspacing=0 cellpadding=4>
<form action="(%ENV_SCRIPT_NAME%)" method=post>
<input type=hidden name=sid value="(%INPUT_sid%)">
<input type=hidden name=cmd value=print>
<input type=hidden name=style value="(%INPUT_style%)">
<input type=hidden name=key value="(%INPUT_key%)">
		<tr>
				<td align=right><b>[%Ticket%]</b></td>
				<td align=left><b>(%TICKET_id%)</b></td>
		</tr>
		<tr>
				<td align=right><b>[%Email%]</b></td>
				<td align=left>(%TICKET_email%)</td>
		</tr>
		<tr>
				<td align=right><b>[%Customer%]</b></td>
				<td align=left>(%TICKET_name%)</td>
		</tr>
		<tr>
				<td align=right><b>[%Subject%]</b></td>
				<td align=left>(%TICKET_subject%)</td>
		</tr>
		<tr>
				<td align=right><b>[%Comments%]</b></td>
				<td align=left><textarea rows=5 cols=40 name=notes></textarea></td>
		</tr>
    <tr>
		    <td colspan=2>
 						<input type=submit class=boldcontent value="[%Print%]">
    		</td>
				</form>
		</tr>
</table>
</body>
</html>
EOT

my $ttroticket =<<EOT;
<table width=(%HTMLBASEWIDTH%) cellspacing=0 cellpadding=0 bgcolor="#C6D7CF" style="padding-left: 5px; padding-right: 5px">
<!--        <tr>
                <td align=right colspan=6 class=sm><a href="(%ENV_SCRIPT_NAME%)?cmd=annotate&sid=(%INPUT_sid%)&key=(%INPUT_key%)" target="_blank">printable version</a></td>
        </tr> -->
        <tr>
                <td align=left class=lbl>[%Subject%]</td>
                <td>&nbsp;&nbsp;</td>
                <td align=left>(%TICKEDOPEN%)(%TICKET_subject%)(%TICKEDCLOSE%)</td>
                <td align=left class=lbl>[%Group%]</td>
                <td>&nbsp;&nbsp;</td>
                <td align=left>(%TICKET_GROUP%)</td>
        </tr>
        <tr>
                <td align=left class=lbl>[%Status%]</td>
                <td>&nbsp;&nbsp;</td>
                <td align=left width=90%>(%TICKET_status%)</td>
                <td align=left class=lbl>[%Operator%]</td>
                <td>&nbsp;&nbsp;</td>
                <td align=left>(%TICKET_oper%)</td>
        </tr>
        <tr>
                <td align=left class=lbl>[%Created%]</td>
                <td>&nbsp;&nbsp;</td>
                <td align=left>(%TICKET_open%)</td>
                <td align=left class=lbl>[%Customer%]</td>
                <td>&nbsp;&nbsp;</td>
                <td align=left><nobr>(%TICKET_name%) (<a href="mailto:(%TICKET_email%)">(%TICKET_email%)</a>)</nobr></td>
        </tr>
        <tr>
                <td align=left class=lbl>[%Solved%]</td>
                <td>&nbsp;&nbsp;</td>
                <td align=left>(%TICKET_closed%)</td>
                <td align=left class=lbl><nobr>[%Access key%]</nobr></td>
                <td>&nbsp;&nbsp;</td>
                <td align=left>(%TICKET_key%)</td>
        </tr>
        <tr>
                <td colspan=6 class=tiny>&nbsp;</td>
        </tr>
</table>
<br class=tiny>
<table width=(%HTMLBASEWIDTH%) cellspacing=0 cellpadding=0>
(%MESSAGES%)
</table>
EOT

my $ttticket =<<EOT;
<script language="javascript"><!--
numberoftimes = 0;
        function onlyonce() {
        numberoftimes += 1;
        if (numberoftimes > 1) {
                var themessage = "[%Please be patient. Submission is in progress...%]";
            alert(themessage);
            return false;
        } else {
                return true;
        }
}
// -->
</script>
<script language="JavaScript"><!--
function msgedit(TID, MID){ hwstring="scrollbars=yes,width=600,height=450,resizable=yes,toolbar=no,menubar=no"; var newwin = window.open("(%ENV_SCRIPT_NAME%)?cmd=msgedit&tid=" + TID + "&mid=" + MID + "&sid=(%INPUT_sid%)&style=(%INPUT_style%)", "TTXMsgEditor", hwstring); }
//--></script>
<script language="JavaScript"><!--
function msgdel(TID, MID){
 if (confirm("[%Please confirm message deletion%]")) {
   msg = document.newticket.problem.value;
   window.location.href = "(%ENV_SCRIPT_NAME%)?cmd=msgdel&sid=(%INPUT_sid%)&tid="+ TID + "&mid=" + MID + "&style=(%INPUT_style%)&problem="+escape(msg);
 }
}
//--></script>
<script language="JavaScript"><!--
function ticked(ID){ hwstring="scrollbars=yes,width=450,height=(%TICKEDHEIGHT%),resizable=yes,toolbar=no,menubar=no"; var newwin = window.open("(%ENV_SCRIPT_NAME%)?cmd=ticketed&tid=" + ID + "&sid=(%INPUT_sid%)&style=(%INPUT_style%)&isticket=1", "TicketEditor", hwstring); }
//--></script>
<script language="JavaScript"><!--
function showitem(ID){ hwstring="scrollbars=yes,width=650,height=350,resizable=yes,toolbar=no,menubar=no"; var newwin = window.open("(%ENV_SCRIPT_NAME%)?cmd=showitem&id=" + ID + "&sid=(%INPUT_sid%)&style=(%INPUT_style%)&isticket=1", "ItemInfo", hwstring); return false; }
//--></script>
<script language="JavaScript"><!--
function confirmdel()
{
 return confirm("[%Please confirm ticket removal%]");
}
//--></script>
<script language="JavaScript"><!--
function answerlib(){
hwstring="scrollbars=yes,width=700,height=360,resizable=yes,toolbar=no,menubar=no";
var newwin = window.open("(%ENV_SCRIPT_NAME%)?cmd=answerlib&sid=(%INPUT_sid%)&style=(%INPUT_style%)", 'TTXAnswerLib', hwstring);
newwin.focus();
return false;
}
//--></script>
<script language="JavaScript"><!--
function preview(){
hwstring="scrollbars=yes,width=600,height=500,resizable=yes,toolbar=no,menubar=no";
var newwin = window.open('', 'winpreview', hwstring);
newwin.focus();
document.forms['formpreview'].msg.value = document.forms['newticket'].problem.value;
document.forms['formpreview'].submit();
return false;
}
//--></script>
<script language="JavaScript"><!--
function markuphelp(){
hwstring="scrollbars=yes,width=650,height=300,resizable=yes,toolbar=no,menubar=no";
var newwin = window.open("(%ENV_SCRIPT_NAME%)?cmd=markuphelp", 'TTXQuickHelp', hwstring);
return false;
}
//--></script>
<script language="JavaScript"><!--
var caretPos = null;

function trackme(fld) {
  if (typeof(fld.createTextRange) != 'undefined') {
    caretPos = document.selection.createRange().duplicate();
  }
}
function markup(bbopen, bbclose, fld) {
  // IE
  if (caretPos != null && fld.createTextRange) {
    var range = caretPos;
    var wasempty = range.text.length == 0 ? true : false;
    range.text = bbopen + range.text + bbclose;
    if (wasempty) {
      range.moveStart('character', -bbopen.length);
      range.moveEnd('character', -bbclose.length);
      range.select();
    } else {
      fld.focus(range);
    }
  } else if (typeof(fld.selectionStart) != "undefined") {
    var savescroll = fld.scrollTop;
    var start = fld.selectionStart;
    var end = fld.selectionEnd;
    var txt = fld.value.substring(start, end);
    fld.value = fld.value.substr(0, start) + bbopen + txt + bbclose + fld.value.substr(end);
    var pos;
    if (txt.length == 0) {
      pos = start + bbopen.length;
    } else {
      pos = start + bbopen.length + txt.length + bbclose.length;
    }
    fld.selectionStart = pos;
    fld.selectionEnd = pos;
    fld.focus();
    fld.scrollTop = savescroll;
  }
}
//--></script>


<table width=(%HTMLBASEWIDTH%) cellspacing=0 cellpadding=0 bgcolor="#C6D7CF" style="padding-left: 5px; padding-right: 5px">
<form method=post action="(%ENV_SCRIPT_NAME%)" name=newticket id=newticket enctype="multipart/form-data" onsubmit="return onlyonce()">
<input type=hidden name=cmd value=ticket>
<input type=hidden name=style value="(%INPUT_style%)">
<input type=hidden name=sid value=(%INPUT_sid%)>
<input type=hidden name=do value=1>
<input type=hidden name=tid value=(%INPUT_tid%)>
<input type=hidden name=key value=(%INPUT_key%)>
<input type=hidden name=qsort value="(%INPUT_qsort%)">
<input type=hidden name=qsortorder value="(%INPUT_qsortorder%)">
<input type=hidden name=qoffset value=(%INPUT_qoffset%)>
<input type=hidden name=qwindow value=(%INPUT_qwindow%)>
<input type=hidden name=oper value=(%INPUT_oper%)>
<input type=hidden name=status value=(%INPUT_status%)>
<input type=hidden name=lname value=(%INPUT_lname%)>
<input type=hidden name=emailkey value=(%INPUT_emailkey%)>
<input type=hidden name=c0 value="(%INPUT_c0%)">
<input type=hidden name=c1 value="(%INPUT_c1%)">
<input type=hidden name=c2 value="(%INPUT_c2%)">
<input type=hidden name=c3 value="(%INPUT_c3%)">
<input type=hidden name=c4 value="(%INPUT_c4%)">
<input type=hidden name=c5 value="(%INPUT_c5%)">
<input type=hidden name=c6 value="(%INPUT_c6%)">
<input type=hidden name=c7 value="(%INPUT_c7%)">
<input type=hidden name=c8 value="(%INPUT_c8%)">
<input type=hidden name=c9 value="(%INPUT_c9%)">
<input type=hidden name=fltrsubj value="(%INPUT_fltrsubj%)">
        <tr>
                <td colspan=6 class=tiny>&nbsp</td>
        </tr>
        (%PRINTANNOTATE%)
        (%INVENTORYROW%)
        <tr>
                <td align=left class=lbl>[%Subject%]</td>
                <td>&nbsp;&nbsp;</td>
                <td align=left>(%TICKEDOPEN%)(%TICKET_subject%)(%TICKEDCLOSE%)</td>
                <td align=left class=lbl>[%(%CONFIG_GRPSELLBL%)%]</td>
                <td>&nbsp;&nbsp;</td>
                <td align=left>(%TICKET_GROUP%)</td>
        </tr>
        <tr>
                <td align=left class=lbl>[%Status%]</td>
                <td>&nbsp;&nbsp;</td>
                <td align=left width=90%>[%(%TICKET_status%)%]</td>
                <td align=left class=lbl>[%Operator%]</td>
                <td>&nbsp;&nbsp;</td>
                <td align=left>(%TICKET_oper%)</td>
        </tr>
        <tr>
                <td align=left class=lbl>[%Created%]</td>
                <td>&nbsp;&nbsp;</td>
                <td align=left>(%TICKET_open%)</td>
                <td align=left class=lbl>[%Customer%]</td>
                <td>&nbsp;&nbsp;</td>
                <td align=left><nobr>(%TICKET_name%) (<a href="mailto:(%TICKET_email%)">(%TICKET_email%)</a>)</nobr></td>
        </tr>
        <tr>
                <td align=left class=lbl>[%Solved%]</td>
                <td>&nbsp;&nbsp;</td>
                <td align=left>(%TICKET_closed%)</td>
                <td align=left class=lbl><nobr>[%Access key%]</nobr></td>
                <td>&nbsp;&nbsp;</td>
                <td align=left>(%TICKET_key%)</td>
        </tr>
        <tr>
                <td colspan=6 class=tiny>&nbsp</td>
        </tr>
</table>
<br class=tiny>
<table width=(%HTMLBASEWIDTH%) cellspacing=0 cellpadding=0>
(%MESSAGES%)
        <tr>
          <td colspan=2 class=tiny>&nbsp</td>
        </tr>
        <tr>
          <td colspan=2>
            <table width=(%HTMLBASEWIDTH%) cellspacing=0 cellpadding=0>
              <tr>
                <td valign=top align=left bgcolor="#CFDCE8" style="padding-left: 5px">
                        <br><span class=lbl>[%New status%]</span><br class=tiny>
                        (%NEWSTATUS%)
                </td>
                <td valign=top align=left>
                  <table width="100%" cellspacing=0 cellpadding=0>
                    <tr>
                      <td valign=top align=left bgcolor="#CFDCE8" style="padding-left: 15px"><br><span class=lbl>&nbsp;[%Message%]</span>(%ANSWERLIB%)(%PREVIEW%)
                        &nbsp;&nbsp;<a href=# onClick="return markuphelp()" tabindex="-1">[%Markup help%]</a><br class=tiny>
                      </td>
                    </tr>
                    <tr>
                      <td align=left valign=top bgcolor="#CFDCE8" style="padding-left: 15px">
                       <input alt="Bold" title="Bold" tabindex="-1" type=submit
                       style="margin: 3px; font-size: small; width: 23px; height: 23px; font-weight: bold; font-family: Times, serif;" value=B
                       onclick="markup('[b]', '[/b]', document.forms.newticket.problem); return false;"><input
                       alt="Italic" title="Italic" tabindex="-1" type=submit
                       style="margin: 3px; font-size: small; width: 23px; height: 23px; font-weight: normal; font-style: italic;  font-family: Times, serif;"
                       value=I onclick="markup('[i]', '[/i]', document.forms.newticket.problem); return false;"><input
                       alt="Underline" title="Underline" tabindex="-1" type=submit
                       style="margin: 3px; font-size: small; width: 23px; height: 23px; font-weight: normal; text-decoration: underline; font-family: Times, serif;"
                       value=U onclick="markup('[u]', '[/u]', document.forms.newticket.problem); return false;"><input
                       alt="Code" title="Code" tabindex="-1" type=submit
                       style="margin: 3px; font-size: small; width: 23px; height: 23px; font-weight: normal; font-family: Times, serif;"
                       value="#" onclick="markup('[code]', '[/code]', document.forms.newticket.problem); return false;"><input
                       alt="Small" title="Small" tabindex="-1" type=submit
                       style="margin: 3px; font-size: small; width: 23px; height: 23px; font-weight: normal; font-family: Times, serif;"
                       value="s" onclick="markup('[small]', '[/small]', document.forms.newticket.problem); return false;"><input
                       alt="Hyperlink" title="Hyperlink" tabindex="-1" type=submit
                       style="margin: 3px; font-size: small; width: 33px; height: 23px; font-weight: normal; font-family: Times, serif;"
                       value="url" onclick="markup('[url http://www.example.com]', '[/url]', document.forms.newticket.problem); return false;"><input
                       alt="Image" title="Image" tabindex="-1" type=submit
                       style="margin: 3px; font-size: small; width: 33px; height: 23px; font-weight: normal; font-family: Times, serif;"
                       value="img" onclick="markup('[img http://www.example.com/picture.jpg]', '', document.forms.newticket.problem); return false;">
                      </td>
                    </tr>
                    <tr>
                      <td align=left valign=top bgcolor="#CFDCE8" style="padding-left: 15px">
                        <textarea name=problem id=problem wrap=virtual cols=60 rows=10 onselect="trackme(this);" onclick="trackme(this);" onkeyup="trackme(this);" onchange="trackme(this);">(%INPUT_problem%)</textarea><br class=tiny>
                        (%FILEFORMS%)<br class=tiny>(%TRACKTIME%)
                        <input type=submit value="[%Add message%]">
                        <input type=submit name=cancel value="[%No changes%]">
                        (%DELTICKET%)<br><br class=tiny>
                      </td>
                    </tr>
                  </table>
                </td>
              </tr>
            </table>
          </td>
        </tr>
        </form>
</table>
<form method="post" action="(%ENV_SCRIPT_NAME%)" id="formpreview" target="winpreview" >
<input type=hidden name=cmd value=preview>
<input type=hidden name=style value="(%INPUT_style%)">
<input type=hidden name=sid value=(%INPUT_sid%)>
<input type=hidden name=key value=(%INPUT_key%)>
<input type=hidden name=msg>
</form>
EOT

my $ttnewticket =<<EOT;
<script language="javascript"><!--
numberoftimes = 0;
        function onlyonce() {
        numberoftimes += 1;
        if (numberoftimes > 1) {
                var themessage = "[%Please be patient. Submission is in progress...%]";
            alert(themessage);
            return false;
        } else {
                return true;
        }
}
// -->
</script>
<script language="JavaScript"><!--
function preview(){
hwstring="scrollbars=yes,width=600,height=500,resizable=yes,toolbar=no,menubar=no";
var newwin = window.open('', 'winpreview', hwstring);
newwin.focus();
document.forms['formpreview'].msg.value = document.forms['newticket'].problem.value;
document.forms['formpreview'].submit();
return false;
}
//--></script>
<script language="JavaScript"><!--
var caretPos = null;

function trackme(fld) {
  if (typeof(fld.createTextRange) != 'undefined') {
    caretPos = document.selection.createRange().duplicate();
  }
}
function markup(bbopen, bbclose, fld) {
  // IE
  if (caretPos != null && fld.createTextRange) {
    var range = caretPos;
    var wasempty = range.text.length == 0 ? true : false;
    range.text = bbopen + range.text + bbclose;
    if (wasempty) {
      range.moveStart('character', -bbopen.length);
      range.moveEnd('character', -bbclose.length);
      range.select();
    } else {
      fld.focus(range);
    }
  } else if (typeof(fld.selectionStart) != "undefined") {
    var savescroll = fld.scrollTop;
    var start = fld.selectionStart;
    var end = fld.selectionEnd;
    var txt = fld.value.substring(start, end);
    fld.value = fld.value.substr(0, start) + bbopen + txt + bbclose + fld.value.substr(end);
    var pos;
    if (txt.length == 0) {
      pos = start + bbopen.length;
    } else {
      pos = start + bbopen.length + txt.length + bbclose.length;
    }
    fld.selectionStart = pos;
    fld.selectionEnd = pos;
    fld.focus();
    fld.scrollTop = savescroll;
  }
}
//--></script>

<table width=(%HTMLBASEWIDTH%) cellspacing=0 cellpadding=0 bgcolor="#CFDCE8">
  <tr>
    <td align=center><br class=tiny>
<form method=post action="(%ENV_SCRIPT_NAME%)" name=newticket enctype="multipart/form-data" onsubmit="return onlyonce()">
<input type=hidden name=cmd value=newticket>
<input type=hidden name=style value="(%INPUT_style%)">
<input type=hidden name=sid value=(%INPUT_sid%)>
<input type=hidden name=do value=1>
<input type=hidden name=tid value=(%INPUT_tid%)>
<input type=hidden name=form value=(%INPUT_form%)>
      <table cellspacing=0 cellpadding=3>
      <tr>
        <td align=right class=lbl>[%Name%]<font color=red><sup>*</sup></font></td>
        <td align=left><input type=text size=25 name=name value="(%INPUT_name%)"></td>
      </tr>
      <tr>
        <td align=right class=lbl>[%Email%]<font color=red><sup>*</sup></font></td>
        <td align=left><input type=text size=25 name=email value="(%INPUT_email%)"></td>
      </tr>
      (%CUSTOMVARS%)
      (%ITEMSELSTD%)
      (%OPERSELSTD%)
      (%GROUPSELSTD%)
      <tr>
        <td align=right class=lbl>[%Subject%]<font color=red><sup>*</sup></font></td>
        <td align=left><input type=text size=40 name=subject value="(%INPUT_subject%)"></td>
      </tr>
      (%KIDFORM%)
      <tr>
        <td colspan=2 align=center>
           <table cellspacing=0 cellpadding=0>
              <tr>
                <td align=left>
                  <span class=lbl>[%Problem%]</span>&nbsp;&nbsp;&nbsp;<a href=#teditor tabindex="-1" onClick="return preview()">[%preview%]</a><br class=tiny>
                       <input alt="Bold" title="Bold" tabindex="-1" type=submit
                       style="margin: 3px; font-size: small; width: 23px; height: 23px; font-weight: bold; font-family: Times, serif;" value=B
                       onclick="markup('[b]', '[/b]', document.forms.newticket.problem); return false;"><input
                       alt="Italic" title="Italic" tabindex="-1" type=submit
                       style="margin: 3px; font-size: small; width: 23px; height: 23px; font-weight: normal; font-style: italic;  font-family: Times, serif;"
                       value=I onclick="markup('[i]', '[/i]', document.forms.newticket.problem); return false;"><input
                       alt="Underline" title="Underline" tabindex="-1" type=submit
                       style="margin: 3px; font-size: small; width: 23px; height: 23px; font-weight: normal; text-decoration: underline; font-family: Times, serif;"
                       value=U onclick="markup('[u]', '[/u]', document.forms.newticket.problem); return false;"><input
                       alt="Code" title="Code" tabindex="-1" type=submit
                       style="margin: 3px; font-size: small; width: 23px; height: 23px; font-weight: normal; font-family: Times, serif;"
                       value="#" onclick="markup('[code]', '[/code]', document.forms.newticket.problem); return false;"><input
                       alt="Small" title="Small" tabindex="-1" type=submit
                       style="margin: 3px; font-size: small; width: 23px; height: 23px; font-weight: normal; font-family: Times, serif;"
                       value="s" onclick="markup('[small]', '[/small]', document.forms.newticket.problem); return false;"><input
                       alt="Hyperlink" title="Hyperlink" tabindex="-1" type=submit
                       style="margin: 3px; font-size: small; width: 33px; height: 23px; font-weight: normal; font-family: Times, serif;"
                       value="url" onclick="markup('[url http://www.example.com]', '[/url]', document.forms.newticket.problem); return false;"><input
                       alt="Image" title="Image" tabindex="-1" type=submit
                       style="margin: 3px; font-size: small; width: 33px; height: 23px; font-weight: normal; font-family: Times, serif;"
                       value="img" onclick="markup('[img http://www.example.com/picture.jpg]', '', document.forms.newticket.problem); return false;"><br>
                  <textarea name=problem wrap=virtual cols=50 rows=10 onselect="trackme(this);" onclick="trackme(this);" onkeyup="trackme(this);" onchange="trackme(this);">(%INPUT_problem%)</textarea>
                </td>
              </tr>
           </table>
        </td>
      </tr>
      <tr><td colspan=2 align=left>(%FILEFORMS%)</td></tr>
      <tr>
        <td align=left>(%INTERNALCHECKBOX%)</td>
        <td align=right><input type=submit value="[%Submit%]"><br><br class=tiny></td>
      </tr>
</form>
      </table>
    </td>
  </tr>
</table>
<form method="post" action="(%ENV_SCRIPT_NAME%)" id="formpreview" target="winpreview" >
<input type=hidden name=cmd value=preview>
<input type=hidden name=style value="(%INPUT_style%)">
<input type=hidden name=sid value=(%INPUT_sid%)>
<input type=hidden name=key value=(%INPUT_key%)>
<input type=hidden name=msg>
</form>
EOT

my $ttconfirmnew =<<EOT;
<br class=tiny>
<table width=(%HTMLBASEWIDTH%) cellspacing=0 cellpadding=0>
        <tr>
                <td width=50>&nbsp;</td>
                <td align=left>
                        We have received your message and created <nobr>a service ticket #<font color=red><b>(%TICKETID%)</b></font>.</nobr>
                        Please refer to this number in all follow-up communications relating to this specific issue.
                        <br><br>
                        <span class=sm><b>Note:</b> We have sent a confirmation email to <b>(%INPUT_email%)</b> including instructions
                        for tracking status of your ticket. If you did not receive the confirmation shortly after submission of your inquiry,
                        there is something wrong with the email address you provided. Please be advised that if we cannot deliver a confirmation,
                        we cannot deliver an answer as well. In an event of email delivery problems please use our online system in order to
                        fetch an answer.</span>
                        <br><br>
                        In order to access your service request via our online system, please use the following access key:
                        <br><br>
                        <center><b><font color=red>(%TICKETKEY%)</font></b>
                        <br></br>
                        or follow this link
                        <br><br>
                        <a href="(%ENV_SCRIPT_NAME%)?cmd=ticket&key=(%TICKETKEY%)"><b>Ticket #(%TICKETID%)</b></a> (do not forget to bookmark it)
                        <br><br>
                        </center>
                        (both key and link have been sent to your email address <b>(%INPUT_email%)</b> as well)
                        <br><br>
                </td>
                <td width=50>&nbsp;</td>
        </tr>
</table>
<br class=tiny>
EOT

my $ttclaim =<<EOT;
<script language="JavaScript"><!--
function confirmdel()
{
 return confirm("[%Please confirm ticket removal%]");
}
//--></script>
<table width=(%HTMLBASEWIDTH%) cellspacing=0 cellpadding=0 bgcolor="#C6D7CF" style="padding-left: 5px">
<form method=post action="(%ENV_SCRIPT_NAME%)">
<input type=hidden name=cmd value=claim>
<input type=hidden name=style value="(%INPUT_style%)">
<input type=hidden name=sid value=(%INPUT_sid%)>
<input type=hidden name=do value=1>
<input type=hidden name=tid value=(%INPUT_tid%)>
<input type=hidden name=key value=(%INPUT_key%)>
<input type=hidden name=qsort value="(%INPUT_qsort%)">
<input type=hidden name=qsortorder value="(%INPUT_qsortorder%)">
<input type=hidden name=qoffset value=(%INPUT_qoffset%)>
<input type=hidden name=qwindow value=(%INPUT_qwindow%)>
<input type=hidden name=oper value=(%INPUT_oper%)>
<input type=hidden name=status value=(%INPUT_status%)>
<input type=hidden name=lname value=(%INPUT_lname%)>
<input type=hidden name=c0 value="(%INPUT_c0%)">
<input type=hidden name=c1 value="(%INPUT_c1%)">
<input type=hidden name=c2 value="(%INPUT_c2%)">
<input type=hidden name=c3 value="(%INPUT_c3%)">
<input type=hidden name=c4 value="(%INPUT_c4%)">
<input type=hidden name=c5 value="(%INPUT_c5%)">
<input type=hidden name=c6 value="(%INPUT_c6%)">
<input type=hidden name=c7 value="(%INPUT_c7%)">
<input type=hidden name=c8 value="(%INPUT_c8%)">
<input type=hidden name=c9 value="(%INPUT_c9%)">
<input type=hidden name=fltrsubj value="(%INPUT_fltrsubj%)">
        <tr>
                <td colspan=3 class=tiny>&nbsp</td>
        </tr>
        <tr>
                <td align=left class=lbl>[%Status%]</td>
                <td>&nbsp;&nbsp;</td>
                <td align=left>[%(%TICKET_status%)%]</td>
        </tr>
        <tr>
                <td align=left class=lbl>[%Subject%]</td>
                <td>&nbsp;&nbsp;</td>
                <td width=90% align=left>(%TICKET_subject%)</td>
        </tr>
        <tr>
                <td align=left class=lbl>[%(%CONFIG_GRPSELLBL%)%]</td>
                <td>&nbsp;&nbsp;</td>
                <td width=90% align=left>(%TICKET_GROUP%)</td>
        </tr>
        <tr>
                <td align=left class=lbl>[%Created%]</td>
                <td>&nbsp;&nbsp;</td>
                <td align=left>(%TICKET_open%)</td>
        </tr>
        <tr>
                <td colspan=3 class=tiny>&nbsp</td>
        </tr>
</table>
<br class=tiny>
<table width=(%HTMLBASEWIDTH%) cellspacing=0 cellpadding=0>
(%MESSAGES%)
</table>
<br class=tiny>(%WANTED%)
<table width=(%HTMLBASEWIDTH%) cellspacing=0 cellpadding=0 bgcolor="#CFDCE8">
    <tr>
                <td align=center>
                        <br class=tiny><br class=tiny>
                        <input type=submit value="[%Claim ownership%]">(%DELTICKET%)&nbsp;&nbsp;<input type=submit name=cancel value="[%Cancel%]">
                        <br><br class=tiny><br class=tiny>
                </td>
        </tr>
        </form>
</table>
EOT

my $ttanswerlib =<<EOT;
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.0 Transitional//EN"
"http://www.w3.org/TR/REC-html40/loose.dtd">
<html>
<head>
<meta http-equiv="Content-Type" content="text/html; charset=[%CHARSET%]">
<title>[%Answer library%]</title>
<style type="text/css">
<!--
body, td, p { font-family: Verdana, Helvetica, sans-serif; font-size: 10pt;}
.lbl { font-size: 9pt; font-weight: 700;}
-->
</style>
<script language=Javascript>
<!--
function postanswer(jopa)
{
 window.opener.document.newticket.problem.value += jopa;
 return false;
}
// -->
</script>

(%INITANSWERS%)

<script language=Javascript>
<!--
function showanswer(id) {
  for (i = 0; i < ANSWERS.length; i++) {
    if (ANSWERS[i][0] == id) {
      document.ansform.ananswer.value = ANSWERS[i][1];
                        document.ctrl.aid.value = id;
      return false;
    }
  }
  ananswer.value = ' ';
  return false;
}
// -->
</script>
<script language=Javascript>
<!--
function showcat(id) {
  location.href='(%ENV_SCRIPT_NAME%)?cmd=answerlib&sid=(%INPUT_sid%)&style=(%INPUT_style%)&cat='+escape(id);
  return false;
}
// -->
</script>

</head>
<body onload="initanswers()">
<center>
(%ANSWERLIBERROR%)
(%ANSWERLIBMSG%)
<table cellpadding=0 cellspacing=0>
        <tr>
                <td valign=top align=left>
                        <span class=lbl>1. [%Select%]</span><br><br class=tiny>

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
                </td>
                <td><nobr>&nbsp;&nbsp;&nbsp;&nbsp;</nobr></td>
                <form name=ansform>
                <td valign=top align=left>
                        <span class=lbl>2. [%Preview%]</span><br><br class=tiny>
                        <textarea readonly name=ananswer cols=50 rows=(%ROWS%)></textarea></td>
                </form>
        </tr>
        <form action="(%ENV_SCRIPT_NAME%)" name=ctrl method=post>
        <input type=hidden name=cmd value=answerlib>
        <input type=hidden name=style value="(%INPUT_style%)">
        <input type=hidden name=do value=1>
        <input type=hidden name=aid value="">
        <input type=hidden name=sid value="(%INPUT_sid%)">
        <tr>
                <td colspan align=left><span class=lbl><nobr>3. [%Copy%] =></nobr></span><td>
                <td colspan align=left>
                        <br class=tiny>
                        <input type=submit value="[%Use%]" OnClick="return postanswer(document.ansform.ananswer.value)">
                        (%ALIBBUTTONS%)
                        &nbsp;&nbsp;<input type=submit value="[%Close%]" OnClick="window.close(); return false;">
                <td>
        </tr>
        </form>
</table>
</center>
</body>
</html>
EOT

my $ttnewanswer =<<EOT;
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.0 Transitional//EN"
"http://www.w3.org/TR/REC-html40/loose.dtd">
<html>
<head>
<meta http-equiv="Content-Type" content="text/html; charset=[%CHARSET%]">
<title>[%Answer editor%]</title>
<style type="text/css">
<!--
body, td, p { font-family: Verdana, Helvetica, sans-serif; font-size: 10pt;}
.lbl { font-size: 9pt; font-weight: 700;}
-->
</style>
</head>
<body>
<center>
(%ANSWERLIBERROR%)
(%ANSWERLIBMSG%)
<table cellpadding=3 cellspacing=0>
        <form action="(%ENV_SCRIPT_NAME%)" method=post>
        <input type=hidden name=cmd value="(%INPUT_cmd%)">
        <input type=hidden name=do value=1>
        <input type=hidden name=style value="(%INPUT_style%)">
        <input type=hidden name=aid value="(%INPUT_aid%)">
        <input type=hidden name=sid value="(%INPUT_sid%)">
        <tr>
                <td align=left class=lbl>[%Title%]</td>
                <td align=left><input type=text size=30 name=title value="(%TITLE%)"></td>
        </tr>
        <tr>
                <td colspan=2></td>
        </tr>
        <tr>
                <td colspan=2></td>
        </tr>
        <tr>
          <td align=left class=lbl>[%Select existing category%]</td>
          <td align=left>
			<select name=cat OnChange="if (this[this.selectedIndex].value) {document.editor.catnew.value = ''}; return false;">
		  	(%CATSELECTOR%)
		  	</select>
		  </td>
        </tr>
        <tr>
                <td align=left class=lbl>[%or define new one%]: </td>
                <td align=left><input type=text size=30 name=catnew value="(%INPUT_catnew%)"></td>
        </tr>
        <tr>
                <td colspan=2 valign=top class=lbl>[%Answer%]</td>
        </tr>
        <tr>
                <td colspan=2><textarea name=answer cols=50 rows=9 wrap=virtual>(%ANSWER%)</textarea>
        </tr>
        <tr>
                <td colspan=2>
                        <table width="100%" cellpadding=0 cellspacing=0>
                                <tr>
                                        <td align=left>
            (%COMMONCHECKBOX%)
                                        </td>
                                        <td align=right>
                                                <input type=submit value="[%Update%]">
                                                <input type=submit name=cancel value="[%Done%]">
                                        </td>
                                </tr>
                        </table>
                </td>
        </tr>
        </form>
</table>
</center>
</body>
</html>
EOT

my $ttdelanswer =<<EOT;
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.0 Transitional//EN"
"http://www.w3.org/TR/REC-html40/loose.dtd">
<html>
<head>
<meta http-equiv="Content-Type" content="text/html; charset=[%CHARSET%]">
<title>[%Deleting answer%]</title>
<style type="text/css">
<!--
body, td, p { font-family: Verdana, Helvetica, sans-serif; font-size: 10pt;}
.lbl { font-size: 9pt; font-weight: 700;}
-->
</style>
</head>
<body>
<br><br>
<center>
(%ANSWERLIBERROR%)
(%ANSWERLIBMSG%)
<form action="(%ENV_SCRIPT_NAME%)" method=post>
<input type=hidden name=cmd value=delanswer>
<input type=hidden name=style value="(%INPUT_style%)">
<input type=hidden name=do value=1>
<input type=hidden name=aid value="(%INPUT_aid%)">
<input type=hidden name=sid value="(%INPUT_sid%)">
<b><font color=red>[%Deleting answer%]</font></b>
<br><br>
<b>(%ANSWERTITLE%)</b>
<br><br>
[%Are you sure?%]
<br><br>
<input type=submit value="[%Yes%]">
<input type=submit name=cancel value="[%No%]">
</form>
</center>
</body>
</html>
EOT

my $ttkeyform =<<EOT;
<table width=(%HTMLBASEWIDTH%) cellspacing=0 cellpadding=0 bgcolor="#CFDCE8">
<form method=post action="(%ENV_SCRIPT_NAME%)">
<input type=hidden name=cmd value=keyform>
<input type=hidden name=style value="(%INPUT_style%)">
<input type=hidden name=sid value=(%INPUT_sid%)>
<input type=hidden name=do value=1>
<input type=hidden name=qsort value="(%INPUT_qsort%)">
<input type=hidden name=qsortorder value="(%INPUT_qsortorder%)">
<input type=hidden name=qoffset value=(%INPUT_qoffset%)>
<input type=hidden name=qwindow value=(%INPUT_qwindow%)>
        <tr>
                <td align=center>
                        <table cellpadding=3>
                                <tr>
                                        <td>
                                                <br class=tiny><br class=tiny>
                                                <span class=lbl>[%Access Key%]</span>
                                                <input type=text name=key size=35 value="(%INPUT_key%)">
                                        </td>
                                </tr>
                                <tr>
                                        <td align=right>
                                                <input type=submit value="[%Enter%]"> <input type=submit name=cancel value="[%Cancel%]">
                                                </form>
                                                <br><br class=tiny><br class=tiny>
                                        </td>
                                </tr>
                        </table>
                </td>
        </tr>
        <tr>
                <td align=center>
                        (%MESSAGE%)
                </td>
        </tr>
<form method=post action="(%ENV_SCRIPT_NAME%)">
<input type=hidden name=cmd value=keyfinder>
<input type=hidden name=style value="(%INPUT_style%)">
<input type=hidden name=sid value=(%INPUT_sid%)>
<input type=hidden name=do value=1>
<input type=hidden name=qsort value="(%INPUT_qsort%)">
<input type=hidden name=qsortorder value="(%INPUT_qsortorder%)">
<input type=hidden name=qoffset value=(%INPUT_qoffset%)>
<input type=hidden name=qwindow value=(%INPUT_qwindow%)>
        <tr>
                <td align=center>
                        <table cellpadding=3>
                                <tr>
                                        <td>
                                                <br class=tiny><br class=tiny>
                                                <span class=lbl>[%Email address%]</span>
                                                <input type=text name=email size=34 value="(%INPUT_email%)">
                                        </td>
                                </tr>
                                <tr>
                                        <td align=right>
                                                <input type=submit value="[%Enter%]"> <input type=submit name=cancel value="[%Cancel%]">
                                                <br><br class=tiny><br class=tiny>
                                        </td>
                                </tr>
                        </table>
                </td>
        </tr>
        </form>
</table>
EOT

my $ttnewmessage =<<EOT;
[b]Re:[/b] Ticket (%TICKETID%), (%TICKETSTATE%)

Dear (%UNAME%)

A new message has been added to the service request #(%TICKETID%).

(%MESSAGE%)

You can view and update your inquiry here:
(%TICKETURL%)

(%OPERATORNAME%)
(%COMPANYNAME%) Help Desk
EOT

my $ttnewticketeml =<<EOT;
Dear (%UNAME%)

Thank you for contacting (%COMPANYNAME%) Help Desk. This message is to confirm that we received a service request with tracking # (%TICKETID%) from you.

(%MESSAGE%)

You can view and update your service request here:
(%TICKETURL%)

Sincerely,

(%COMPANYNAME%) Help Desk
EOT

my $ttonewmessage =<<EOT;
[b]Re:[/b] Ticket (%TICKETID%), (%TICKETSTATE%)
[b]Customer:[/b] (%UNAME%) ((%UEMAIL%))

Followup message:

(%MESSAGE%)

(%TICKETURL%)
EOT

my $ttonewticket =<<EOT;
New ticket #(%TICKETID%) from (%UNAME%) ((%UEMAIL%)),

(%ITEMLINE%)
(%MESSAGE%)

(%TICKETURL%)
EOT

my $ttticketed =<<EOT;
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.0 Transitional//EN"
"http://www.w3.org/TR/REC-html40/loose.dtd">
<html>
<head>
<meta http-equiv="Content-Type" content="text/html; charset=[%CHARSET%]">
<title>[%Ticket Editor%]</title>
<style type="text/css">
<!--
body, td, p { font-family: Verdana, Helvetica, sans-serif; font-size: 10pt;}
-->
</style>
(%CFLOOKUP%)
<script language=Javascript>
<!--
function closeme()
{
 parentisticket = (%INPUT_isticket%);
 if (parentisticket) {
   msg = window.opener.document.newticket.problem.value;
   opener.location.href = "(%ENV_SCRIPT_NAME%)?cmd=ticket&sid=(%INPUT_sid%)&key=(%TICKET_key%)&problem="+escape(msg);
 } else {
   opener.update();
 }
 window.close();
 return false;
}
//-->
</script>
</head>
<body>
<center>
<font color=red><b>(%ERROR_MESSAGE%)</b></font><font color=blue><b>(%MESSAGE%)</b></font>
<table cellspacing=0 cellpadding=4>
<form action="(%ENV_SCRIPT_NAME%)" method=post name=ticked id=ticked>
<input type=hidden name=sid value="(%INPUT_sid%)">
<input type=hidden name=isticket value="(%INPUT_isticket%)">
<input type=hidden name=cmd value=ticketed>
<input type=hidden name=style value="(%INPUT_style%)">
<input type=hidden name=tid value="(%INPUT_tid%)">
<input type=hidden name=do value=1>
		<tr>
				<td align=right><b>[%Ticket ID%]</b></td>
				<td align=left><b>(%INPUT_tid%)</b></td>
		</tr>
		<tr>
				<td align=right><b>[%Email%]</b></td>
				<td align=left><input type=text name=email size=30 value="(%TICKET_email%)"></td>
		</tr>
		<tr>
				<td align=right><b>[%Name%]</b></td>
				<td align=left><input type=text name=name size=30 value="(%TICKET_name%)"></td>
		</tr>
		<tr>
				<td align=right><b>[%Subject%]</b></td>
				<td align=left><input type=text name=subject size=30 value="(%TICKET_subject%)"></td>
		</tr>
		(%CUSTOMFIELDS%)
    <tr>
		    <td colspan=2>
 			    <table width="100%">
    				<tr>
    					<td width="50%" align=center>
    						<input type=submit class=boldcontent value="[%Update Ticket%]">
    					</td>
    					</form>
    					<td width="50%" align=center>
    						<input type=submit class=button onClick="return closeme()" value="[%Close Window%]">
    					</td>
    				</tr>
    		  </table>
			 </td>
		</tr>
</table>
</body>
</html>

EOT

my $ttmsgedit =<<EOT;
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.0 Transitional//EN"
"http://www.w3.org/TR/REC-html40/loose.dtd">
<html>
<head>
<meta http-equiv="Content-Type" content="text/html; charset=[%CHARSET%]">
<title>[%Message Editor%]</title>
<style type="text/css">
<!--
body, td, p { font-family: Verdana, Helvetica, sans-serif; font-size: 10pt;}
-->
</style>
<script language=Javascript>
<!--
function closeme()
{
 msg = window.opener.document.newticket.problem.value;
 window.opener.location.href = "(%ENV_SCRIPT_NAME%)?cmd=ticket&sid=(%INPUT_sid%)&key=(%KEY%)&style=(%INPUT_style%)&problem="+escape(msg);
 window.close();
 return false;
}
//-->
</script>
</head>
<body>
<center>
<font color=red><b>(%ERROR_MESSAGE%)</b></font><font color=blue><b>(%MESSAGE%)</b></font>
<form action="(%ENV_SCRIPT_NAME%)" method=post>
<input type=hidden name=sid value="(%INPUT_sid%)">
<input type=hidden name=cmd value=msgedit>
<input type=hidden name=style value="(%INPUT_style%)">
<input type=hidden name=mid value="(%INPUT_mid%)">
<input type=hidden name=tid value="(%INPUT_tid%)">
<input type=hidden name=do value=1>
<br>
<textarea name=msg wrap=virtual cols=60 rows=20>(%MSG%)</textarea>
<br><br>
<b>[%Reason for edit%]</b>
<input type=text name=reason size=45 value="(%INPUT_reason%)">
<br><br>
<table cellpadding=5>
<tr>
<td width="50%" align=right>
<input type=submit class=boldcontent value="[%Update Message%]">
</td>
</form>
<td width="50%" align=left>
<input type=submit class=button onClick="return closeme()" value="[%Close Window%]">
</td>
</tr>
</table>
</center>
</body>
</html>

EOT

my @templates = (
  {name => 'login.html', data => $ttlogin},
  {name => 'header.shtml', data => $ttheader},
  {name => 'footer.shtml', data => $ttfooter},
  {name => 'helpdesk.html', data => $tthelpdesk},
  {name => 'ticket.html', data => $ttticket},
  {name => 'roticket.html', data => $ttroticket},
  {name => 'newticket.html', data => $ttnewticket},
  {name => 'confirmnew.html', data => $ttconfirmnew},
  {name => 'claim.html', data => $ttclaim},
  {name => 'keyform.html', data => $ttkeyform},
  {name => 'newmessage.txt', data => $ttnewmessage},
  {name => 'newticket.txt', data => $ttnewticketeml},
  {name => 'onewmessage.txt', data => $ttonewmessage},
  {name => 'onewticket.txt', data => $ttonewticket},
  {name => 'orderalib.html', data => $ttorderalib},
  {name => 'markuphelp.html', data => $ttmarkuphelp},
  {name => 'answerlib.html', data => $ttanswerlib},
  {name => 'delanswer.html', data => $ttdelanswer},
  {name => 'newanswer.html', data => $ttnewanswer},
  {name => 'ticketed.html', data => $ttticketed},
  {name => 'reports.html', data => $ttreports},
  {name => 'preview.html', data => $ttpreview},
  {name => 'showitem.html', data => $ttshowitem},
  {name => 'dashboard.html', data => $ttdashboard},
  {name => 'msgedit.html', data => $ttmsgedit},
  {name => 'annotate.html', data => $ttannotate},
  {name => 'print.html', data => $ttprint},
);
# ======================================================================= setup1

sub setup1 {
  $cfg = $_[0];
  $query = $_[1];
  my $msg = $_[2];
  my $error = "<br><b><font color=red>Error: $msg</font></b><br><br>" if $msg ne undef;
  my $sd = scriptdir();
  my $pwd = $query->param('pwd');
  my $basedir = $query->param('basedir');
  print <<EOT;
<center>
<h3>Welcome to Trouble Ticket Express Setup Wizard</h3>
</center>
<b>Step 1. Setting Data Directory</b>
<br><br>
Trouble Ticket Express requires read/write access to some directory in order to
store its data files. The directory must exist and be writeable to Trouble
Ticket Express scripts. Default settings assume usage of the directory you have
uploaded the script to, that is<br>
<br><b>$sd</b><br>
<br>
EOT
  if (! -w $sd) {
    print <<EOT;
Unfortunately this directory is not writeable at the moment and may not be used
to store data files. You may try to change directory permissions (775 or 777
on Unix) and click Retry button below. <b>Please be advised</b> that some
hosting providers do not allow setting 775 and/or 777 access rights for scripts
directory, in such a case you will see Internal Server Error page after clicking
Retry button. You will need to restore access rights for the directory to 755
and run setup again.<br>
<center><form action=$ENV{SCRIPT_NAME} method=post>
<input type=hidden name=pwd value=$pwd>
<input type=hidden name=cmd value=setup2>
<input type=submit value=Retry>
</form></center>
EOT
  } else {
    print <<EOT;
To use the directory above click "Use Default Data Directory" button. <b>Please
be advised</b> that some hosting providers do not allow scripts to write data
into scripts directory, in such a case you will see Internal Server Error page
after clicking on "Use Default Data Directory" button. You will need to restart
Setup Wizard and specify alternate data directory.<br>
<center><form action=$ENV{SCRIPT_NAME} method=post>
<input type=hidden name=cmd value=setup2>
<input type=hidden name=pwd value=pwd>
<input type=hidden name=basedir value="$sd">
<input type=submit value="Use Default Data Directory">
</form></center>
EOT
  }
  print <<EOT;
To setup <b>alternate Data Directory</b> please enter absolute filesystem
pathname of the directory. The directory must exist and be writeable to Trouble
Ticket Express scripts (set access rights to 777 on Unix). <b>Please be advised</b>
that filesystem pathname is not an URL, that is<br>
<br>
<b>/home/www.mysite.com/htdocs/datadir</b> is a filesystem path, while<br><br>
<b>/datadir</b> and <b>http://www.mysite.com/datadir</b> - are URLs<br>
<center>$error<form action=$ENV{SCRIPT_NAME} method=post>
<input type=hidden name=cmd value=setup2>
<b>Data Directory:</b> <input type=text size=60 name=basedir value="$basedir" class=textinput>
<br><br><input type=submit value="Use Alternate Data Directory">
</form></center>
EOT
}
# ======================================================================= setup2

sub setup2 {
  my $microsoft = $^O eq 'MSWin32';
  $cfg = $_[0];
  $query = $_[1];
  my $dir = $query->param('basedir');
  $dir =~ s/\/$//;
  if ($dir eq undef) {
    setup1($_[0], $_[1], "No directory provided");
    return;
  }
  if (!$microsoft && $dir !~ /^\//) {
    setup1($_[0], $_[1], "The directory is not absolute (must begin with '/')");
    return;
  }
  if (! -e $dir) {
    setup1($_[0], $_[1], "Directory $dir does not exist");
    return;
  }
  if (! -d $dir) {
    setup1($_[0], $_[1], "The $dir is a FILE");
    return;
  }
  if (! -w $dir) {
    setup1($_[0], $_[1], "The $dir is not writeable");
    return;
  }
  my $cf = "$dir/ttxcfg.cgi";
  if ( -e $cf && ! -w $cf) {
    setup1($_[0], $_[1], "The $dir already contains congif file, which is not writeable");
    return;
  }
  $cfg->set('basedir', $dir);
  $cfg->set('ttx.version', $TTXSetup::VERSION);
#  $cfg->set('usecache', 1);
  $cfg->file($cf);
  if (!$cfg->save()) {
    setup1($_[0], $_[1], "Error saving config file");
    return;
  }
  build($_[0]);
  my $scrdir = scriptdir();
  if ($dir eq $scrdir) {
    print "<center><br><b>Congratulations! Initial setup completed</b><br><br>".
          "<form action=$ENV{SCRIPT_NAME} method=post><input type=submit value=Continue></form>";
  } else {
    my $dirinfo = 'ttxcfg.cgi';
    print <<EOT;
<center><br>
<b>Configuration file was recorded to<br><br>$dir</b></center>
<br><br>
To complete setup please<br><br>
<b>1.</b> Create text file <b>$dirinfo</b>
<br><br>
<b>2.</b> Copy and paste this text into the <b>$dirinfo</b> file.
<br><br>
<form action=# method=post>
<textarea cols=40 rows=2>
cfgref=$dir/ttxcfg.cgi
</textarea>
</form>
<br><br>
<b>3.</b> Upload <b>$dirinfo</b> file into <nobr><b>$scrdir</b></nobr> directory.
<br><br>
<form action=$ENV{SCRIPT_NAME} method=post>
<b>4.</b>
<input type=submit value="Continue"> <b>Warning:</b> Skipping steps 1-3 will
restart Setup Wizard.
</form>
EOT
  }
}
# ======================================================================= setup3

sub setup3 {
  $cfg = $_[0];
  $query = $_[1];
  my $error;
  if ($query->param('do')) {
    if ($query->param('admpwd') eq undef) {
      $error = 'Missing admin password';
    } elsif ($query->param('admpwd') ne $query->param('admpwd1')) {
      $error = 'Passwords do not match';
    } else {
      $cfg->set('admpwd', $query->param('admpwd'));
      $cfg->save();
      $query->param(-name => 'pwd', -value => $query->param('admpwd'));
      $query->param(-name => 'do', -value => '');
      setup4($cfg, $query);
      return;
    }
  }
  $error = "<br><font color=red><b>Error: $error</b></font><br><br>" if $error ne undef;
  print <<EOT;
<center><b>Administrator Password</b>
<br><br><table width=60%><tr><td align=left>This password is valid for Setup utility only.
Assigning an administrator password will not create any operator accounts.
You will be provided user management menu later during setup.
</td></tr></table><br>
$error

<table cellpadding=3>
<form action=$ENV{SCRIPT_NAME} method=post>
<input type=hidden name=cmd value=setup3>
<input type=hidden name=do value=1>
<tr>
<td align=left class=lbl>Enter password</td>
<td align=left><input type=password name=admpwd></td>
</tr>
<tr>
<td align=left class=lbl>Repeat password</td>
<td align=left><input type=password name=admpwd1></td>
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
# ======================================================================= setup4

sub setup4 {
  $cfg = $_[0];
  $query = $_[1];
  my $pwd = $query->param('pwd');
  my ($mailer, $smtp, $home, $company, $email, $imgurl, $emailfix, $smtptrace,
      $smtplogin, $smtppwd, $hideold, $useaccesscode, $nomsgcfrm, $notikcfrm, $forcecharset,
      $sfcustomer, $sfoper, $stickycf, $rememberme, $useopersel);
  if (!$query->param('do')) {
    $mailer = $query->param('mailer') || $cfg->get('mailer');
    $smtp = $query->param('smtp') || $cfg->get('smtp');
    $home = $query->param('home') || $cfg->get('home');
    $company = $query->param('company') || $cfg->get('company');
    $email = $query->param('email') || $cfg->get('email');
    $imgurl = $query->param('imgurl') || $cfg->get('imgurl');
    $emailfix = $query->param('emailfix') || $cfg->get('emailfix');
    $smtptrace = $query->param('smtptrace') || $cfg->get('smtptrace');
    $nomsgcfrm = $query->param('nomsgcfrm') || $cfg->get('nomsgcfrm');
    $notikcfrm = $query->param('notikcfrm') || $cfg->get('notikcfrm');
    $smtplogin = $query->param('smtplogin') || $cfg->get('smtplogin');
    $rememberme = $query->param('rememberme') || $cfg->get('rememberme');
    $smtppwd = $query->param('smtppwd') || $cfg->get('smtppwd');
    $hideold = $query->param('hideold') || $cfg->get('hideoldsolved');
    $stickycf = $query->param('stickycf') || $cfg->get('stickycf');
    $useopersel = $query->param('useopersel') || $cfg->get('useopersel');
    $useaccesscode = $query->param('useaccesscode') || $cfg->get('useaccesscode');
    $forcecharset = $query->param('forcecharset') || $cfg->get('forcecharset');
    $sfcustomer = $query->param('sfcustomer') || $cfg->get('sendfiles.customer');
    $sfoper = $query->param('sfoper') || $cfg->get('sendfiles.operator');
    if ($cfg->get('blockautoresponder')) {
      $notikcfrm = 1;
      $nomsgcfrm = 1;
    }
  } else {
    $mailer = $query->param('mailer');
    $smtp = $query->param('smtp');
    $home = $query->param('home');
    $company = $query->param('company');
    $email = $query->param('email');
    $imgurl = $query->param('imgurl');
    $emailfix = $query->param('emailfix');
    $smtptrace = $query->param('smtptrace');
    $useopersel = $query->param('useopersel');
    $nomsgcfrm = $query->param('nomsgcfrm');
    $notikcfrm = $query->param('notikcfrm');
    $smtplogin = $query->param('smtplogin');
    $smtppwd = $query->param('smtppwd');
    $hideold = $query->param('hideold');
    $rememberme = $query->param('rememberme');
    $stickycf = $query->param('stickycf');
    $forcecharset = $query->param('forcecharset');
    $useaccesscode = $query->param('useaccesscode');
    $sfcustomer = $query->param('sfcustomer');
    $sfoper = $query->param('sfoper');
  }
  if ($mailer =~ /\s-t\b/) {
    $mailer =~ s/\s-t\b/ /;
    $query->param(-name => 'mailer', -value => $mailer);
  }
  my $error;
  if ($mailer ne undef) {
    my $m = $mailer;
    $m =~ s/^\s+//;
    $m =~ s/\s.*$//;
    if (! -f $m) {
      $error = "The $m program does not exist";
    } elsif (! -x $m) {
      $error = "The $m is not executable";
    }
  }
  if ($hideold =~ /\D/) {
    $hideold = undef;
  }
  $home =~ s/^\s*//;
  $home =~ s/\s*$//;
  if ($home ne undef && $home !~ /^https?:\/\//) {
    $home = 'http://'.$home;
  }
  my $useoperselchecked = ' checked' if $useopersel;
  my $remembermechecked = ' checked' if $rememberme;
  my $stickycfchecked = ' checked' if $stickycf;
  my $sfcustomerchecked = ' checked' if $sfcustomer;
  my $sfoperchecked = ' checked' if $sfoper;
  my $emailfixchecked = 'checked' if $emailfix;
  my $smtptracechecked = 'checked' if $smtptrace;
  my $nmcchecked = 'checked' if $nomsgcfrm;
  my $ntcchecked = 'checked' if $notikcfrm;
  my $datadir = $cfg->get('basedir');
  my $smtptracecmd;
  if ($smtptrace) {
    $smtptracecmd = "&nbsp;&nbsp;&nbsp;<span class=sm>".
                    "<a href=\"$ENV{SCRIPT_NAME}?cmd=smtplog&pwd=$pwd\">View log</a></span>\n";
  }
  $home =~ s/"/&quot;/g;
  $company =~ s/"/&quot;/g;

  my $tz = $query->param('timezone');
  $tz = $cfg->get('timezone') if $tz eq undef;
  $tz = int $tz;
  my $layout = 0;
  my $layouthtml;
  eval "use TTXLayout";
  if ($@ eq undef) { $layout = 1; }
  if ($query->param('do')) {
    $cfg->set('mailer', $mailer);
    $cfg->set('smtp', $smtp);
    $cfg->set('home', $home);
    $cfg->set('company', $company);
    $cfg->set('email', $email);
    $cfg->set('imgurl', $imgurl);
    $cfg->set('timezone', $tz);
    $cfg->set('smtplogin', $smtplogin);
    $cfg->set('smtppwd', $smtppwd);
    $cfg->set('emailfix', $emailfix ? 1:0);
    $cfg->set('smtptrace', $smtptrace ? 1:0);
    $cfg->set('nomsgcfrm', $nomsgcfrm ? 1:0);
    $cfg->set('notikcfrm', $notikcfrm ? 1:0);
    $cfg->set('rememberme', $rememberme ? 1:0);
    $cfg->set('useopersel', $useopersel ? 1:0);
    $cfg->set('stickycf', $stickycf ? 1:0);
    $cfg->set('hideoldsolved', $hideold);
    $cfg->set('useaccesscode', $useaccesscode);
    $cfg->set('forcecharset', $forcecharset);
    $cfg->set('sendfiles.customer', $sfcustomer ? 1:0);
    $cfg->set('sendfiles.operator', $sfoper ? 1:0);
    $cfg->set('blockautoresponder', '') if $cfg->get('blockautoresponder');
    if ($layout) {
      TTXLayout::set($cfg, $query);
    }
    my $savecnt = $cfg->get('savecnt');
    $cfg->set('savecnt', $savecnt + 1);
    $cfg->save();
    build($cfg) if $query->param('tmpreset');
    my $smtplog = $cfg->get('basedir').'/smtptrace.txt';
    if (!$smtptrace) {
      if (-f $smtplog) {
        unlink $smtplog;
      }
    }
    if (!$savecnt) {
      $query->param(-name => 'do', -value => '');
      setup5($cfg, $query);
      return;
    }
  }
  if ($layout) {
    $layouthtml = TTXLayout::html($cfg, $query);
  } else {
    $layouthtml =<<EOT;
<tr><td colspan=2 align=left>
<table cellspasing=2 cellpadding=2>
<tr><td colspan=4 align=center><b><br>Ticket Browser Layout</br></b></td></tr>
<tr><td colspan=4 align=left><span class=sm><br>
<b><font color=red>Important:</font></b>
Your Trouble Ticket Express system does not have an optional Layout Designer module.
This module is required in order to activate the Ticket Browser Layout section of setup form.
Now this section is inactive, any changes to column and filter fields will be ignored.
You may <a href="http://www.troubleticketexpress.com/layout-designer.html"><b>order the optional Layout Designer module</b></a>
at any time. Installation of the module is as simple as uploading a single file to your
Trouble Ticket Express scripts directory, no existing data will be affected.</span>
</br></td></tr>
<tr><td align=left valign=middle><b>Column</b></td>
<td align=left valign=middle><b>Show in browser</b></td>
<td align=left valign=middle><b>Show in filter</b></td>
<td align=left valign=middle><b>Allow editing</b></td></tr>
<tr><td align=left>Text</td>
<td align=left>NA</td>
<td align=left><input type=checkbox value=1 name=fltrtext checked></td>
<td align=left>no</td></tr>
<tr><td align=left>Ticket #</td>
<td align=left><input type=checkbox value=1 name=brid checked></td>
<td align=left><input type=checkbox value=1 name=fltrid checked></td>
<td align=left>no</td></tr>
<tr><td align=left>Name</td>
<td align=left><input type=checkbox value=1 name=brname checked></td>
<td align=left><input type=checkbox value=1 name=fltrname></td>
<td align=left>yes</td></tr>
<tr><td align=left>Email</td>
<td align=left><input type=checkbox value=1 name=bremail checked></td>
<td align=left><input type=checkbox value=1 name=fltremail></td>
<td align=left>yes</td></tr>
<tr><td align=left>Subject</td>
<td align=left>yes<input type=hidden name=brsubject value=1></td>
<td align=left><input type=checkbox value=1 name=fltrsubject checked></td>
<td align=left>yes</td></tr>
<tr><td align=left>Operator</td>
<td align=left><input type=checkbox value=1 name=broper checked></td>
<td align=left><input type=checkbox value=1 name=fltroper checked></td>
<td align=left>no</td></tr>
<tr><td align=left>Status</td>
<td align=left><input type=checkbox value=1 name=brstatus checked></td>
<td align=left><input type=checkbox value=1 name=fltrstatus checked></td>
<td align=left>no</td></tr>
<tr><td align=left>Created</td>
<td align=left><input type=checkbox value=1 name=bropen checked></td>
<td align=left>no<input type=hidden name=fltropen value=0></td>
<td align=left>no</td></tr>
<tr><td align=left>Updated</td>
<td align=left><input type=checkbox value=1 name=brupdated checked></td>
<td align=left>no<input type=hidden name=fltrupdated value=0></td>
<td align=left>no</td></tr>
<tr><td align=left>Group</td>
<td align=left><input type=checkbox value=1 name=brgrp></td>
<td align=left><input type=checkbox value=1 name=fltrgrp></td>
<td align=left>no</td></tr>
<tr><td align=left>Date Range</td>
<td align=left>NA</td>
<td align=left><input type=checkbox value=1 name=fltrdrange></td>
<td align=left>no</td></tr>
<tr><td colspan=4 align=left><span class=sm><br><b>Custom fields.</b>
Each ticket record has 10 custom fields (c0-c9). These fields may contain information, what is
specific to your application.
The intended usage is to hold values of contact form
<a href="http://www.troubleticketexpress.com/mail-form.html"><b>custom fields</b></a>.
This section allows you to define mapping of form fields to ticket fields.
Your custom field titles must match input names
as per your customized html template <b>without leading 'x' character</b>. <i>Example:
Enter 'Phone' to the box next to the c0 label if you want your custom contact form 'xPhone' values
to be stored in custom field #0.</i><br><font color=red><b>Note:</b></font>
This section is inactive now.
Please <a href="http://www.troubleticketexpress.com/layout-designer.html"><b>order the optional Layout Designer module</b></a>
to activate the form.</span>
</td></tr>
<tr><td align=left>c0:<input type=text size=12 name=ctitle0 value=""></td>
<td align=left><input type=checkbox name=brc0></td>
<td align=left><input type=checkbox value=1 name=fltrc0></td>
<td align=left><input type=checkbox value=1 name=editc0></td></tr>
<tr><td align=left>c1:<input type=text size=12 name=ctitle1 value=""></td>
<td align=left><input type=checkbox name=brc1></td>
<td align=left><input type=checkbox value=1 name=fltrc1></td>
<td align=left><input type=checkbox value=1 name=editc1></td></tr>
<tr><td align=left>c2:<input type=text size=12 name=ctitle2 value=""></td>
<td align=left><input type=checkbox name=brc2></td>
<td align=left><input type=checkbox value=1 name=fltrc2></td>
<td align=left><input type=checkbox value=1 name=editc2></td></tr>
<tr><td align=left>c3:<input type=text size=12 name=ctitle3 value=""></td>
<td align=left><input type=checkbox name=brc3></td>
<td align=left><input type=checkbox value=1 name=fltrc3></td>
<td align=left><input type=checkbox value=1 name=editc3></td></tr>
<tr><td align=left>c4:<input type=text size=12 name=ctitle4 value=""></td>
<td align=left><input type=checkbox name=brc4></td>
<td align=left><input type=checkbox value=1 name=fltrc4></td>
<td align=left><input type=checkbox value=1 name=editc4></td></tr>
<tr><td align=left>c5:<input type=text size=12 name=ctitle5 value=""></td>
<td align=left><input type=checkbox name=brc5></td>
<td align=left><input type=checkbox value=1 name=fltrc5></td>
<td align=left><input type=checkbox value=1 name=editc5></td></tr>
<tr><td align=left>c6:<input type=text size=12 name=ctitle6 value=""></td>
<td align=left><input type=checkbox name=brc6></td>
<td align=left><input type=checkbox value=1 name=fltrc6></td>
<td align=left><input type=checkbox value=1 name=editc6></td></tr>
<tr><td align=left>c7:<input type=text size=12 name=ctitle7 value=""></td>
<td align=left><input type=checkbox name=brc7></td>
<td align=left><input type=checkbox value=1 name=fltrc7></td>
<td align=left><input type=checkbox value=1 name=editc7></td></tr>
<tr><td align=left>c8:<input type=text size=12 name=ctitle8 value=""></td>
<td align=left><input type=checkbox name=brc8></td>
<td align=left><input type=checkbox value=1 name=fltrc8></td>
<td align=left><input type=checkbox value=1 name=editc8></td></tr>
<tr><td align=left>c9:<input type=text size=12 name=ctitle9 value=""></td>
<td align=left><input type=checkbox name=brc9></td>
<td align=left><input type=checkbox value=1 name=fltrc9></td>
<td align=left><input type=checkbox value=1 name=editc9></td></tr>
</table></td></tr>
EOT
  }
  $error = "<br><b><font color=red>Error: $error</font></b><br><br>" if $error ne undef;
  print <<EOT;
<span class=sm><b><a href="$ENV{SCRIPT_NAME}?cmd=sysinfo&pwd=$pwd">System Info</a> |
<a href="$ENV{SCRIPT_NAME}?cmd=setup5&pwd=$pwd">Users</a> |
<a href="$ENV{SCRIPT_NAME}?cmd=grps&pwd=$pwd">Groups</a> |
<a href="$ENV{SCRIPT_NAME}?cmd=inventory&pwd=$pwd">Inventory</a>
</b></span>
<br>
<center><h3>System Setup</h3>
$error
<form action=$ENV{SCRIPT_NAME} method=post>
<input type=hidden name=cmd value=setup4>
<input type=hidden name=do value=1>
<input type=hidden name=pwd value=$pwd>
<table border=0 cellpadding=0 cellspacing=0>
<tr><td align=right><b>Data Directory:</b></td><td align=left>&nbsp;&nbsp;<b>$datadir</b></td></tr>
<tr><td align=right><b>Templates Directory:</b></td><td align=left>&nbsp;&nbsp;<b>$datadir/templates</b></td></tr>
<tr><td align=right><b>Reset templates:</b></td><td align=left>&nbsp;&nbsp;<input type=checkbox name=tmpreset value=1> (this will restore default templates)</td></tr>
<tr><td colspan=2 align=center>&nbsp;</td></tr>
<tr height=1><td colspan=2 align=center height=1 bgcolor="#9b9b9b"><img
src="$imgurl/dot.gif" height=1></td></tr>
<tr><td colspan=2 align=left><br>
By default all *.gif and *.css files will be uploaded to Trouble Ticket Express
scripts directory. Not all hosting providers allow serving image files
from scripts directory. You may upload *.gif and *.css files to another
directory, please adjust value for "Image Directory URL" field in such a case
- it must contain absolute URL of image directory.<br><br>
</td></tr>
<tr><td align=right><b>Image Directory URL:</b></td><td align=left>&nbsp;&nbsp;
<input type=text size=40 name=imgurl value="$imgurl"></td></tr>
<tr><td colspan=2 align=center>&nbsp;</td></tr>
<tr height=1><td colspan=2 align=center height=1 bgcolor="#9b9b9b"><img
src="$imgurl/dot.gif" height=1></td></tr>
<tr><td colspan=2><br>
<b>Email settings</b><br><br>
</td></tr>
EOT
  if ($^O =~ /mswin/i) {
  print <<EOT;
<tr><td align=right><b>SMTP host:</b></td><td align=left>&nbsp;&nbsp;
<input type=text size=40 name=smtp value="$smtp">
<small>examples: 127.0.0.1, smtp.mysite.com</small></td></tr>
<tr><td colspan=2 align=left><br>
Your SMTP server may (or may not) require authentication (user id & password)
in order to allow relaying email to other servers. Please contact the SMTP
server admin regarding your SMTP server access policies.
</td></tr>
EOT
    eval 'use Authen::SASL';
    if ($@ ne undef) {
    print <<EOT;
<tr><td colspan=2 align=left><br>
Unfortunately your server does not have a Perl library, which is required to
use SMTP authentication. The name of the library is <i>Authen::SASL</i>. In
order to install the library use the following commands at the DOS prompt
<small>(in order to access DOS prompt click
on Windows Start button, select <i>Run...</i>, type <i>command</i> and hit
Enter)</small>
<br><br>
<code>
C:\><b>ppm</b><br>
ppm> <b>install Authen::SASL</b><br>
</code>
<br>
If you are unable to install the Authen::SASL module, the Trouble Ticket
Express will try using old fashioned POP3 auth mode: old versions of SMTP
servers did not have authorization feature and they were accepting outgoing
email only from users, which have recently checked their mail boxes using POP3
protocol. If you provide POP3 user id and password info below,
the Trouble Ticket Express will try to login via POP3 protocol to the host
running your SMTP server prior to sending email. Please remember, this is just
a workaround and it is not guaranteed to work.<br><br>
</td></tr>
<tr><td align=right><b>POP3 user id:</b></td><td align=left>&nbsp;&nbsp;
<input type=text size=40 name=smtplogin value="$smtplogin"></td></tr>
<tr><td align=right><b>POP3 password:</b></td><td align=left>&nbsp;&nbsp;
<input type=password size=20 name=smtppwd value="$smtppwd"></td></tr>
EOT
    } else {
  print <<EOT;
<tr><td colspan=2 align=left>
<br class=tiny>If you are required to use the SMTP authentication, please provide SMTP user id
and password here:
<br><br>
</td></tr>
<tr><td align=right><b>SMTP user id:</b></td><td align=left>&nbsp;&nbsp;
<input type=text size=40 name=smtplogin value="$smtplogin"></td></tr>
<tr><td align=right><b>SMTP password:</b></td><td align=left>&nbsp;&nbsp;
<input type=password size=20 name=smtppwd value="$smtppwd"></td></tr>
EOT
    }
    print <<EOT;
<tr><td colspan=2 align center><br>
<b>Miscellaneous email settings</b><br><br>
</td></tr>
<tr><td align=right><b>Fix MTA:</b></td><td align=left>&nbsp;&nbsp;
<input type=checkbox value=1 name=emailfix $emailfixchecked> <small>Check this if email messages have clobbered lines.</small></td></tr>
<tr><td align=right><b>SMTP Trace:</b></td><td align=left>&nbsp;&nbsp;
<input type=checkbox value=1 name=smtptrace $smtptracechecked> <small>Check if you do not receive email.</small>$smtptracecmd</td></tr>
<tr><td align=right><b>No ticket confirmations:</b></td><td align=left>&nbsp;&nbsp;
<input type=checkbox value=1 name=notikcfrm $ntcchecked> <small>Customers will not receive new ticket confirmations.</small></td></tr>
<tr><td align=right><b>No message confirmations:</b></td><td align=left>&nbsp;&nbsp;
<input type=checkbox value=1 name=nomsgcfrm $nmcchecked> <small>Customers will not receive copies of their own messages.</small></td></tr>
<tr><td colspan=2 align=left><br>
<br>If your Windows server have a sendmail or sendmail compatible software
installed, you may provide an absolute pathname of the sendmail program instead
of specifying SMTP server info.<br><br>
</td></tr>
<tr><td align=right><b>Sendmail path:</b></td><td align=left>&nbsp;&nbsp;
<input type=text size=40 name=mailer value="$mailer"></td></tr>
EOT
  } else {
  print <<EOT;
<tr><td colspan=2 align=left>
Trouble Ticket Express uses <i>sendmail</i> program in order to send email messages.
You need to provide absolute path to the <i>sendmail</i> program.
EOT
  my @smp = listsendmail();
  if (@smp > 0) {
    my $s = (@smp > 1 ? 's':'');
    my $are = (@smp > 1 ? 'are':'is');
   print <<EOT;
The following program$s located on your local hard disk $are possibly the
sendmail executable$s.<br><br class=tiny>
EOT
    foreach my $sm (@smp) {
      print "<b>$sm</b><br>\n";
    }
    print "<br class=tiny>\n";
  }
   print <<EOT;
Please contact your system administrator or hosting provider for more info
regarding location of <i>sendmail</i> or substitute program on your server.
<br><br class=tiny>
</td></tr>
EOT
  print <<EOT;
<tr><td align=right><b>Sendmail path:</b></td><td align=left>&nbsp;&nbsp;
<input type=text size=40 name=mailer value="$mailer"></td></tr>
<tr><td colspan=2 align=left>
<br>If you do not know location of the <i>sendmail</i> on your server you may
try using SMTP server instead.<br>
<i>Hint:</i> The first thing to try is 127.0.0.1. This way you will eventually
access the local <i>sendmail</i> program, provided it was configured to accept
network connections.<br><br class=tiny>
<b>Remember:</b> There is no need to provide SMTP server info if you already
provided absolute path to <i>sendmail</i> program on your server.
</td></tr>
<tr><td align=right><b>SMTP host:</b></td><td align=left>&nbsp;&nbsp;
<input type=text size=40 name=smtp value="$smtp"> <small>examples: 127.0.0.1, smtp.mysite.com</small></td></tr>
<tr><td colspan=2 align=left><br>
Your SMTP server may (or may not) require authentication (user id & password)
in order to allow relaying email to other servers. Please contact the SMTP
server admin regarding your SMTP server access policies.
</td></tr>
EOT
    eval "use Authen::SASL";
    if ($@ ne undef) {
    print <<EOT;
<tr><td colspan=2 align=left><br>
Unfortunately your server does not have a Perl library, which is required to
use SMTP authentication. The name of the library is <i>Authen::SASL</i>. In
order to install the library use the following commands at the shell prompt
<br><br>
<code>
# <b>perl -MCPAN -e shell</b><br>
<u>cpan></u>> <b>install Authen::SASL</b><br>
</code>
<br>
If you are unable to install the Authen::SASL module, the Trouble Ticket
Express will try using old fashioned POP3 auth mode: old versions of SMTP
servers did not have authorization feature and they were accepting outgoing
email only from users, which have recently checked their mail boxes using POP3
protocol. If you provide POP3 user id and password info below,
the Trouble Ticket Express will try to login via POP3 protocol to the host
running your SMTP server prior to sending email. Please remember, this is just
a workaround and it is not guaranteed to work.<br><br>
</td></tr>
<tr><td align=right><b>POP3 user id:</b></td><td align=left>&nbsp;&nbsp;
<input type=text size=40 name=smtplogin value="$smtplogin"></td></tr>
<tr><td align=right><b>POP3 password:</b></td><td align=left>&nbsp;&nbsp;
<input type=password size=20 name=smtppwd value="$smtppwd"></td></tr>
EOT
    } else {
  print <<EOT;
<tr><td colspan=2 align=left>
<br class=tiny>If you are required to use the SMTP authentication, please provide SMTP user id
and password here:
<br><br>
</td></tr>
<tr><td align=right><b>SMTP user id:</b></td><td align=left>&nbsp;&nbsp;
<input type=text size=40 name=smtplogin value="$smtplogin"></td></tr>
<tr><td align=right><b>SMTP password:</b></td><td align=left>&nbsp;&nbsp;
<input type=password size=20 name=smtppwd value="$smtppwd"></td></tr>
EOT
    }
    print <<EOT;
<tr><td colspan=2 align center><br>
<b>Miscellaneous email settings</b><br><br>
</td></tr>
<tr><td align=right><b>Fix MTA:</b></td><td align=left>&nbsp;&nbsp;
<input type=checkbox value=1 name=emailfix $emailfixchecked> <small>Check this if email messages have clobbered lines.</small></td></tr>
<tr><td align=right><b>SMTP Trace:</b></td><td align=left>&nbsp;&nbsp;
<input type=checkbox value=1 name=smtptrace $smtptracechecked> <small>Check if you do not receive email.</small>$smtptracecmd</td></tr>
<tr><td align=right><b>No ticket confirmations:</b></td><td align=left>&nbsp;&nbsp;
<input type=checkbox value=1 name=notikcfrm $ntcchecked> <small>Customers will not receive new ticket confirmations.</small></td></tr>
<tr><td align=right><b>No message confirmations:</b></td><td align=left>&nbsp;&nbsp;
<input type=checkbox value=1 name=nomsgcfrm $nmcchecked> <small>Customers will not receive copies of their own messages.</small></td></tr>
EOT
  }
  my $checkuseaccesscode = ' checked' if $useaccesscode;
  print <<EOT;
<tr><td colspan=2 align=center>&nbsp;</td></tr>
<tr height=1><td colspan=2 align=center height=1 bgcolor="#9b9b9b"><img
src="$imgurl/dot.gif" height=1></td></tr>
<tr><td colspan=2><br>
<b>Your company name and email address</b><br><br class=tiny>
</td></tr>
<tr><td align=right><b>Company name:<br><br></b></td><td align=left>&nbsp;&nbsp;
<input type=text name=company size=35 value="$company"><br><br></td></tr>
<tr><td align=right><b>Company email address:</b></td><td align=left>&nbsp;&nbsp;
<input type=text name=email size=35 value="$email"></td></tr>
<tr><td align=right><b>Company home page:</b></td><td align=left>&nbsp;&nbsp;
<input type=text name=home size=35 value="$home"></td></tr>
<tr><td align=right><b>Time Zone:</b></td><td align=left>&nbsp;&nbsp;
<input type=text name=timezone size=7 value="$tz"> GMT offset in minutes <span class=sm>(EST=-300, PST=-480 CET=60)</span></td></tr>
<tr><td colspan=2 align=center>&nbsp;</td></tr>
<tr height=1><td colspan=2 align=center height=1 bgcolor="#9b9b9b"><img
src="$imgurl/dot.gif" height=1></td></tr>
<tr><td colspan=2 align=center>&nbsp;</td></tr>
<tr><td align=right><b>Hide solved tickets after</b></td><td align=left>&nbsp;&nbsp;
<input type=text name=hideold size=3 value="$hideold"> <b>days.</b></td></tr>
<tr><td colspan=2 align=center>&nbsp;</td></tr>
<tr><td align=right><b>Use access code image</b></td><td align=left>&nbsp;&nbsp;
<input type=checkbox name=useaccesscode value=1$checkuseaccesscode></td></tr>
<tr><td colspan=2 align=center>&nbsp;</td></tr>
<tr><td align=right><b>Character encoding</b></td><td align=left>&nbsp;&nbsp;
<select name=forcecharset>
<option value="">Auto</option>
EOT
  my $versionwarn;
  if ($] < 5.006002) {
    $versionwarn =<<EOT;
<tr><td colspan=2 align=left>
<b>Note:</b> Unicode support requires Perl version 5.6.2 or newer. You have only $].
Selecting UTF-8 may result in erratic behavior.
</td></tr>;
EOT
  }
  for my $o ('UTF-8', 'windows-1252') {
    print "<option value=\"$o\"";
    print ' selected' if $forcecharset eq $o;
    print ">$o</option>\n";
  }
  print <<EOT;
</select></td></tr>$versionwarn
<tr><td colspan=2 align=center>&nbsp;</td></tr>
<tr><td align=right><b>Attach files (customer email messages)</b></td><td align=left>&nbsp;&nbsp;
<input type=checkbox name=sfcustomer value=1$sfcustomerchecked></td></tr>
<tr><td colspan=2 align=center>&nbsp;</td></tr>
<tr><td align=right><b>Attach files (operator email messages)</b></td><td align=left>&nbsp;&nbsp;
<input type=checkbox name=sfoper value=1$sfoperchecked></td></tr>
<tr><td colspan=2 align=center>&nbsp;</td></tr>
<tr><td align=right><b>Keep custom field values in cookie (new ticket form)</b></td><td align=left>&nbsp;&nbsp;
<input type=checkbox name=stickycf value=1$stickycfchecked></td></tr>
<tr><td colspan=2 align=center>&nbsp;</td></tr>
<tr><td align=right><b>Keep operators logged in (keep session id in cookie)</b></td><td align=left>&nbsp;&nbsp;
<input type=checkbox name=rememberme value=1$remembermechecked></td></tr>
<tr><td colspan=2 align=center>&nbsp;</td></tr>
<tr><td align=right><b>Show operator selector (new ticket form)</b></td><td align=left>&nbsp;&nbsp;
<input type=checkbox name=useopersel value=1$useoperselchecked></td></tr>
<tr><td colspan=2 align=center>&nbsp;</td></tr>
<tr height=1><td colspan=2 align=center height=1 bgcolor="#9b9b9b"><img
src="$imgurl/dot.gif" height=1></td></tr>$layouthtml
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
# ======================================================================= setup5

sub setup5 {
  $cfg = $_[0];
  $query = $_[1];
  if (TTXCommon::dodec()) {
    if ($] >= 5.008) {
      binmode STDOUT, ":utf8";
    } else {
      binmode STDOUT;
    }
  }
  my $newlogin = $query->param('newlogin');
  my $newpasswd = $query->param('newpasswd');
  my $newemail = $query->param('newemail');
  my $newfname = $query->param('newfname');
  my $newlname = $query->param('newlname');
  my $newimage = $query->param('newimage');
  my $newusemail = $query->param('newusemail');
  my $newsla = $query->param('newsla');
  my $newrw = $query->param('newrw');
  my $newdt = $query->param('newdt');
  my $newtr = $query->param('newtr');
  my $newme = $query->param('newme');
  my $usewrkh = 0;
  eval "use TTXWorkHours";
  my ($newwrkhweek, $newwrkhsat, $newwrkhsun, $newwrkhvac);
  if ($@ eq undef) {
    $usewrkh = 1;
    $newwrkhweek = $query->param('newwrkhweek');
    $newwrkhsat = $query->param('newwrkhsat');
    $newwrkhsun = $query->param('newwrkhsun');
    $newwrkhvac = $query->param('newwrkhvac');
    if (!$cfg->get('userdb.wrkh')) {
      my @users = TTXUser::list();
      foreach (@users) {
        my $user = TTXUser->new($_);
        next if $user eq undef || $user->{passwd} eq undef;
        my ($wrkhweek, $wrkhsat, $wrkhsun, $wrkhvac) = TTXWorkHours::unpackwrkh($user->{wrkh});
        $user->{wrkh} = TTXWorkHours::packwrkh($wrkhweek, $wrkhsat, $wrkhsun, $wrkhvac);
        $user->save();
      }
      $cfg->set('userdb.wrkh', 1);
      $cfg->save();
    }
  }
  my $pwd = $query->param('pwd');
  my $error;
  my %k2T = (
    passwd => 'Password',
    fname => 'Name',
    lname => 'Surname',
    email => 'Email'
  );
  if ($query->param('do')) {
    my $maxserial = 10;
    for (my $i = 0; $query->param("u$i"."login") ne undef; ++$i) {
      my $uid = $query->param("u$i"."login");
      my $user = TTXUser->new($uid);
      if ($user ne undef) {
        $maxserial = $user->{snum} if $user->{snum} > $maxserial;
      }
    }
    for (my $i = 0; $query->param("u$i"."login") ne undef; ++$i) {
      my $uid = $query->param("u$i"."login");
      my $user = TTXUser->new($uid);
      if ($user ne undef) {
        if ($query->param("u$i"."del")) {
          $user->delete();
          my @list = grep(/^group\d+$/, $cfg->vars());
          my $savecfg;
          foreach my $gid (@list) {
            my $mbrlist = $cfg->get("mbr-$gid");
            if ($mbrlist =~ /\b$uid\b/) {
              $mbrlist =~ s/\b$uid\b//g;
              $mbrlist =~ s/;;/;/g;
              $mbrlist =~ s/^;//;
              $cfg->set("mbr-$gid", $mbrlist);
              $savecfg = 1;
            }
          }
          $cfg->save() if $savecfg;
          next;
        }
        my $dosave = 0;
        foreach my $key ('image', 'usemail', 'sla', 'dt', 'tr', 'me') {
          $user->{$key} = TTXCommon::decodeit($query->param("u$i$key"));
        }
        $user->{ro} = (TTXCommon::decodeit($query->param("u$i".'rw')) ? '':'1');
        if ($usewrkh) {
          my $wrkh = TTXCommon::decodeit(TTXWorkHours::packwrkh($query->param("u$i".'wrkhweek'), $query->param("u$i".'wrkhsat'),
                                                $query->param("u$i".'wrkhsun'), $query->param("u$i".'wrkhvac')));
          if ($wrkh eq undef) {
            $error .= TTXWorkHours::errormsg()." for ".$query->param("u$i"."login")."<br>\n";
            --$dosave;
          } else {
            $user->{wrkh} = $wrkh;
          }
        }
        foreach my $key ('passwd', 'fname', 'lname', 'email') {
          if ($query->param("u$i$key") eq undef) {
            $error .= "Missing $k2T{$key} for ".$query->param("u$i"."login")."<br>\n";
            next;
          }
          $user->{$key} = TTXCommon::decodeit($query->param("u$i$key"));
          if (!$user->{snum}) {
            $maxserial += 1 + int(rand(10));
            $user->{snum} = $maxserial;
          }
          $dosave++;
        }
        if ($dosave > 3) {
          $user->save();
          my $savecfg;
          foreach my $operation ('delete', 'assign', 'edit') {
            if ($cfg->get("grant.$operation") ne undef) {
              $cfg->set("grant.$operation", '');
              $savecfg = 1;
            }
          }
          $cfg->save() if $savecfg;
        }
      }
    }
    if ($newlogin ne undef) {
      my $user = TTXUser->new($newlogin);
      if ($user->{passwd} ne undef) {
        $error .= "User [$newlogin] already exists<br>\n";
      } else {
        my $addnew = 1;
        foreach my $key ('image', 'usemail', 'sla', 'dt', 'tr', 'me') {
          $user->{$key} = TTXCommon::decodeit($query->param("new$key"));
        }
        $user->{ro} = (TTXCommon::decodeit($query->param("newrw")) ? '':'1');
        if ($newlogin =~ /\s/) {
          $addnew = 0;
          $error .= "User Login may not contain spaces<br>\n";
        }
        foreach my $key ('passwd', 'email') {
          if ($query->param("new$key") eq undef || $query->param("new$key") =~ /[^a-zA-Z0-9\@_=.-]/) {
            $addnew = 0;
            $error .= "Invalid or missing $k2T{$key} in the new user record<br>\n";
          } else {
            $user->{$key} = TTXCommon::decodeit($query->param("new$key"));
          }
        }
        foreach my $key ('fname', 'lname') {
          if ($query->param("new$key") eq undef) {
            $addnew = 0;
            $error .= "Missing $k2T{$key} in the new user record<br>\n";
          } else {
            $user->{$key} = TTXCommon::decodeit($query->param("new$key"));
          }
        }
        if ($usewrkh) {
          my $wrkh = TTXCommon::decodeit(TTXWorkHours::packwrkh($newwrkhweek, $newwrkhsat, $newwrkhsun, $newwrkhvac));
          if ($wrkh eq undef) {
            $error .= TTXWorkHours::errormsg()." in the new user record<br>\n";
            $addnew = 0;
          } else {
            $user->{wrkh} = $wrkh;
          }
        }
        if ($addnew) {
          $maxserial += 1 + int(rand(10));
          $user->{snum} = $maxserial;
          $user->{login} = TTXCommon::decodeit($newlogin);
          if (!$user->save()) {
            $error .= $user->errortext();
          } else {
            $newlogin = undef; $newpasswd = undef; $newemail = undef;
            $newfname = undef; $newlname=undef; $newimage=undef;
            $newusemail = undef; $newsla=undef;
            $newwrkhweek = $newwrkhsat = $newwrkhsun = $newwrkhvac = undef;
          }
        }
      }
    }
  }
  print <<EOT;
<span class=sm><b><a href="$ENV{SCRIPT_NAME}?cmd=setup4&pwd=$pwd">System Setup</a> |
<a href="$ENV{SCRIPT_NAME}?cmd=setup5&pwd=$pwd">Users</a> |
<a href="$ENV{SCRIPT_NAME}?cmd=grps&pwd=$pwd">Groups</a> |
<a href="$ENV{SCRIPT_NAME}?cmd=inventory&pwd=$pwd">Inventory</a>
</b></span>
<br>
<center><h3>Operator Management</h3>
<font color=red><b>$error</b></font>
<br>
<table cellpadding=3>
<form action=$ENV{SCRIPT_NAME} method=post>
<input type=hidden name=cmd value=setup5>
<input type=hidden name=pwd value=$pwd>
<input type=hidden name=do value=1>
<tr>
<td class=lbl>Del</td>
<td class=lbl>Login</td><td class=lbl>Pass</td><td class=lbl>Email</td>
<td class=lbl>Name</td><td class=lbl>Surname</td><td><span class=lbl>Image URL</span> (optional)</td>
<td class=lbl>ML</td>
<td class=lbl>RW</td>
<td class=lbl>DT</td>
<td class=lbl>TR</td>
<td class=lbl>ME</td>
EOT
  if ($cfg->get('opersla')) {
  print <<EOT;
<td class=lbl>SLA<br><span class=sm>(hours)</span></td>
EOT
  }
  if ($usewrkh) {
  print <<EOT;
<td class=lbl>Weekdays</td>
<td class=lbl>Sat</td>
<td class=lbl>Sun</td>
<td class=lbl>Vac</td>
EOT
  }
  print <<EOT;
</tr>
EOT
  my @users = TTXUser::list();
  my $i = 0;
  foreach (@users) {
    my $user = TTXUser->new($_);
    next if $user eq undef || $user->{passwd} eq undef;
    my ($wrkhweek, $wrkhsat, $wrkhsun, $wrkhvac);
    if ($usewrkh) {
      ($wrkhweek, $wrkhsat, $wrkhsun, $wrkhvac) = TTXWorkHours::unpackwrkh($user->{wrkh});
    }
    print "<tr><td><input type=checkbox value=1 name=u$i"."del></td>\n".
          "<td align=left>".$user->{login}."<input type=hidden name=u$i"."login value=".$user->{login}."></td>\n".
          "<td align=left><input type=password size=3 name=u$i"."passwd value=\"".$user->{passwd}."\"></td>\n".
          "<td align=left><input type=text size=19 name=u$i"."email value=\"".$user->{email}."\"></td>\n".
          "<td align=left><input type=text size=8 name=u$i"."fname value=\"".$user->{fname}."\"></td>\n".
          "<td align=left><input type=text size=8 name=u$i"."lname value=\"".$user->{lname}."\"></td>\n".
          "<td align=left><input type=text size=10 name=u$i"."image value=\"".$user->{image}."\"></td>\n".
          "<td align=right><input type=checkbox name=u$i"."usemail value=1".($user->{usemail}? ' checked':'')."></td>\n".
          "<td align=right><input type=checkbox name=u$i"."rw value=1".($user->{ro}? '':' checked')."></td>\n".
          "<td align=right><input type=checkbox name=u$i"."dt value=1".($user->{dt} ? ' checked':'')."></td>\n".
          "<td align=right><input type=checkbox name=u$i"."tr value=1".($user->{tr} ? ' checked':'')."></td>\n".
          "<td align=right><input type=checkbox name=u$i"."me value=1".($user->{me} ? ' checked':'')."></td>\n".
          ($cfg->get('opersla') ?
            "<td align=left><input type=text size=4 name=u$i"."sla value=\"".$user->{sla}."\"></td>\n":'').
          ($usewrkh ? "<td align=left><input type=text size=8 name=u$i"."wrkhweek value=\"$wrkhweek\"></td>\n".
                      "<td align=left><input type=text size=8 name=u$i"."wrkhsat value=\"$wrkhsat\"></td>\n".
                      "<td align=left><input type=text size=8 name=u$i"."wrkhsun value=\"$wrkhsun\"></td>\n".
                      "<td align=right><input type=checkbox name=u$i"."wrkhvac value=1".($wrkhvac ? ' checked':'')."></td>\n"
                      :'').
          "</tr>\n";
    ++$i;
  }
  my $loginlink;
  if ($i) {
    $loginlink = "<br>Login to <a href=\"ttx.cgi?cmd=login\"><b>Trouble Ticket Express</b></a><br>\n";
  } else {
    $loginlink = "<br>You must create at least one operator record<br>\n";
  }
  $loginlink .=  "<br><b>Note:</b> An operator with login <b>admin</b> is considered as a <i>superuser</i><br>\n".
                 "and may be allowed to execute certain privileged commands.\n";
  print <<EOT;
<tr><td>&nbsp;</td>
<td align=left><input type=text size=8 name=newlogin value="$newlogin"></td>
<td align=left><input type=password size=3 name=newpasswd value="$newpasswd"></td>
<td align=left><input type=text size=19 name=newemail value="$newemail"></td>
<td align=left><input type=text size=8 name=newfname value="$newfname"></td>
<td align=left><input type=text size=8 name=newlname value="$newlname"></td>
<td align=left><input type=text size=10 name=newimage value="$newimage"></td>
<td align=right><input type=checkbox name=newusemail value=1></td>
<td align=right><input type=checkbox name=newrw value=1 checked></td>
<td align=right><input type=checkbox name=newdt value=1></td>
<td align=right><input type=checkbox name=newtr value=1></td>
<td align=right><input type=checkbox name=newme value=1></td>
EOT
  my $colspan = 12;
  if ($cfg->get('opersla')) {
    ++$colspan;
  print <<EOT;
<td align=left><input type=text size=4 name=newsla value="$newsla"></td>
EOT
  }
  if ($usewrkh) {
    $colspan += 4;
    my $checked = ' checked' if $newwrkhvac;
  print <<EOT;
<td align=left><input type=text size=8 name=newwrkhweek value="$newwrkhweek"></td>
<td align=left><input type=text size=8 name=newwrkhsat value="$newwrkhsat"></td>
<td align=left><input type=text size=8 name=newwrkhsun value="$newwrkhsun"></td>
<td align=right><input type=checkbox name=newwrkhvac value=1$checked></td>
EOT
  }
  print <<EOT;
</tr>
<tr>
<td colspan=$colspan align=left>
<input type=submit value="Update All">
</td>
</tr>
<tr>
<td colspan=$colspan align=left>
<br>
<b>ML</b> - Accept Email. If enabled the operator may submit responses using email. The feature
requires <a href="http://www.troubleticketexpress.com/email-piping.html"><b>Mail Module</b></a><br>
<b>RW</b> - Read/Write. If checked the operator may claim tickets and post answers.<br>
<b>DT</b> - Delete Tickets. If checked the operator may delete tickets.<br>
<b>TR</b> - Transfer Tickets. If checked the operator may transfer (assign) any tickets. If unchecked,
the operator may transfer only tickets he or she owns.<br>
<b>ME</b> - Message Edit. If checked the operator may edit (and delete) ticket messages. The feature
requires <a href="http://www.troubleticketexpress.com/messageeditor.html"><b>Message Editor Module</b></a><br>
</td>
</tr>
</form>
</table>
<br>$loginlink
</center>
EOT
}
# ======================================================================== grpid

sub grpid {
  my @list = grep(/^group\d+$/, $cfg->vars());
  foreach my $key (@list) {
    if ($cfg->get($key) eq $_[0]) {
      $key =~ s/^\D+//;
      return $key;
    }
  }
  return undef;
}
# ======================================================================== newid

sub newid {
  my @list = grep(/^group\d+$/, $cfg->vars());
  my $id;
  my @ids;
  foreach my $key (@list) {
    my $n = $key;
    $n =~ s/^\D+//;
    if ($cfg->get($key) eq '') {
      return $n;
    } else {
      $ids[$n] = 1;
    }
  }
  for ($id = 1; $ids[$id]; ++$id){};
  return $id;
}
# ========================================================================= grps

sub grps {
  $cfg = $_[0];
  $query = $_[1];
  eval "use TTXGroups";
  my $grpmodule = 1 if !$@;
  my $disabled = 'disabled=disabled' if !$grpmodule;
  my $newgrp = $query->param('newgrp');
  $newgrp =~ s/^\s+//; $newgrp =~ s/\s+$//;
  $newgrp =~ s/<//g;
  $newgrp =~ s/"/''/g;
  my $pwd = $query->param('pwd');
  my $error;
  my $grpsellbl = $cfg->get('grpsellbl');
  my @users = TTXUser::list();
  if ($query->param('do')) {
    my $dosave = 0;
    my @list = grep(/^group\d+$/, $cfg->vars());
    foreach my $grid (@list) {
      my $grp = $cfg->get($query->param($grid));
      my $i = $grid; $i =~ s/^\D+//;
      if ($query->param("g$i"."del")) {
        $cfg->set($grid, '');
        $cfg->set("mbr-$grid", '');
        $cfg->set('defaultgrp', '') if $cfg->get('defaultgrp') eq $grid;
        $dosave = 1;
        next;
      }
      my $name = $query->param("g$i".'name');
      $name =~ s/^\s+//; $name =~ s/\s+$//;
      if ($name eq undef) {
          $error .= "Missing Group name for Group $i<br>\n";
          next;
      } elsif ($grp ne $name) {
        $cfg->set($grid, $name);
        $dosave = 1;
      }
    }
    if ($newgrp ne undef) {
      if (grpid($newgrp) ne undef) {
        $error .= "Group [$newgrp] already exists<br>\n";
      } else {
        $cfg->set("group".newid(), $newgrp);
        $newgrp = undef;
        $dosave = 1;
      }
    }
    foreach my $uid (@users) {
      my @glist = grep(/^group\d+$/, $cfg->vars());
      foreach my $gid (@glist) {
        next if $cfg->get($gid) eq '' || $cfg->get($gid) eq undef; # skip deleted groups
        my $mbrlist = $cfg->get("mbr-$gid");
        if ($mbrlist =~ /\b$uid\b/) {
          if (!$query->param("mbr-$uid-$gid")) {
            $mbrlist =~ s/\b$uid\b//g;
            $mbrlist =~ s/;;/;/g;
            $mbrlist =~ s/^;//;
            $cfg->set("mbr-$gid", $mbrlist);
            $dosave = 1;
          }
        } else {
          if ($query->param("mbr-$uid-$gid")) {
            $mbrlist .= ';' if $mbrlist ne undef;
            $mbrlist .= $uid;
            $cfg->set("mbr-$gid", $mbrlist);
            $dosave = 1;
          }
        }
      }
    }
    if ($query->param('usegrpsel') && !$cfg->get('usegrpsel') && $grpmodule) {
      $cfg->set('usegrpsel', 1);
      $dosave = 1;
    } elsif ($cfg->get('usegrpsel') && (!$query->param('usegrpsel') || !$grpmodule)) {
      $cfg->set('usegrpsel', 0);
      $dosave = 1;
    }
    if ($query->param('accessctrl') && !$cfg->get('accessctrl') && $grpmodule) {
      $cfg->set('accessctrl', 1);
      $dosave = 1;
    } elsif ($cfg->get('accessctrl') && (!$query->param('accessctrl') || !$grpmodule)) {
      $cfg->set('accessctrl', 0);
      $dosave = 1;
    }
    TTXCommon::cleanit($query, 'grpsellbl');
    if ($query->param('grpsellbl') ne $cfg->get('grpsellbl')) {
      $cfg->set('grpsellbl', $query->param('grpsellbl'));
      $dosave = 1;
    }
    TTXCommon::cleanit($query, 'defaultgrp');
    if ($query->param('defaultgrp') ne $cfg->get('defaultgrp')) {
      $cfg->set('defaultgrp', $query->param('defaultgrp'));
      $dosave = 1;
    }
    $cfg->save() if $dosave;
  }
  my $checkgrpsel = ' checked' if $cfg->get('usegrpsel');
  my $checkaccessctrl = ' checked' if $cfg->get('accessctrl');
  $grpsellbl = $cfg->get('grpsellbl');
  $grpsellbl =~ s/"/&quot;/g;
  $grpsellbl = 'Department' if $grpsellbl eq undef;
  print <<EOT;
<span class=sm><b><a href="$ENV{SCRIPT_NAME}?cmd=setup4&pwd=$pwd">System Setup</a> |
<a href="$ENV{SCRIPT_NAME}?cmd=setup5&pwd=$pwd">Users</a> |
<a href="$ENV{SCRIPT_NAME}?cmd=grps&pwd=$pwd">Groups</a> |
<a href="$ENV{SCRIPT_NAME}?cmd=inventory&pwd=$pwd">Inventory</a>
</b></span>
<br>
<center><h3>Group Management</h3>
<font color=red><b>$error</b></font>
<br>
<table width=700 cellpadding=3>
<form action=$ENV{SCRIPT_NAME} method=post>
<tr>
<td valign=top align=left colspan=3>
The Trouble Ticket Express allows assigning an operator to one or more groups. You
may define an unlimited number of groups to put together operators, who are responsible
for similar tasks. The division may be department based (e.g. <i>Billing, Sales,
Customer Service</i>), product centric (<i>Shared hosting, Dedicated Server, Collocation</i>),
skill related (<i>Tier1, Tier2, Supervisor</i>).<br><br>
</td>
</tr>
<tr>
<td valign=top align=left><span class=lbl><nobr>Enable Group Mode</nobr></span></td>
<td valign=top align=left><input type=checkbox name=usegrpsel $disabled value=1$checkgrpsel></td>
<td valign=top align=left><span class=sm>If checked, the Trouble Ticket Express will place a group
selector drop down menu on a standard ticket submission form. This will ensure that each
new ticket is being designated to appropriate group and only members of that group will
receive new ticket notifications. Furthermore, operators will be provided with an option to
transfer a ticket to a group, rather than to a particular employee.
EOT
if (!$grpmodule) {
  print <<EOT;
<br><br class=tiny><b><font color=red>Note</font>:</b> Group support requires <a href="http://www.troubleticketexpress.com/groups.html" target=_blank><b><nobr>Groups Module</nobr></b></a>.
The module is not installed on your server.
<a href="http://www.troubleticketexpress.com/groups.html" target=_blank><b><nobr>Click here</nobr></b></a>
for ordering and installation instructions.<br><br>
EOT
}
  print <<EOT;
</span></td>
</tr>
<tr>
<td valign=top align=left><span class=lbl><nobr>Access control</nobr></span></td>
<td valign=top align=left><input type=checkbox name=accessctrl $disabled value=1$checkaccessctrl></td>
<td valign=top align=left><span class=sm>If checked, the Trouble Ticket Express will restrict
access to tickets: an operator will only be allowed to access tickets of the group he or she
is a member of.</span>
</td>
</tr>
<tr>
<td valign=top align=left><span class=lbl><nobr>Group selector label</nobr></span></td>
<td valign=top align=left><input type=text size=20 name=grpsellbl value="$grpsellbl"></td>
<td valign=top align=left><span class=sm>e.g. Department, Product, Category, Skill</span></td>
</tr>
</table>
<br>
<table cellpadding=3>
<input type=hidden name=cmd value=grps>
<input type=hidden name=pwd value=$pwd>
<input type=hidden name=do value=1>
<tr>
<td class=lbl>Del</td>
<td class=lbl>Group ID</td>
<td class=lbl>Group Name</td>
<td class=lbl>Default<sup><small>*</small></sup></td>
</tr>
EOT
  my @grplist = sort grep(/^group\d+$/, $cfg->vars());
  @grplist = sort {$cfg->get($a) cmp $cfg->get($b)} @grplist if $cfg->get('groupalphasort');
  foreach my $id (@grplist) {
    my $grpname = $cfg->get($id);
    next if $grpname eq undef || $grpname eq '';
    my $i = $id;
    $i =~ s/^\D+//;
    my $checkradio = ' checked' if $cfg->get('defaultgrp') eq $id;
    print "<tr><td><input type=checkbox value=1 name=g$i"."del></td>\n".
          "<td align=left>group$i</td>\n".
          "<td align=left><input type=text size=20 name=g$i"."name value=\"$grpname\"></td>\n".
          "<td align=center><input type=radio name=defaultgrp value=$id$checkradio></td>\n".
          "</tr>\n";
  }
  print <<EOT;
<tr><td colspan=2>&nbsp;</td>
<td align=left><input type=text size=20 name=newgrp value="$newgrp"></td>
<td>&nbsp;</td>
</tr>
<tr>
<td colspan=4 align=left class=sm>
<sup>*</sup>All tickets submitted via email will be assigned the default group id.<br>
Email based submissions require optional
<a href="http://www.troubleticketexpress.com/email-piping.html" target=_blank><b><nobr>Email Module</nobr></b></a>.
</td>
</tr>
<tr>
<td colspan=4 align=right>
<input type=submit value="Update All">
</td>
</tr>
</table>
<br><br><center><b>Membership Matrix</b></center>
<table cellpadding=5>
<tr>
<td class=lbl>Operator</td>
EOT
  my $colcnt = 1;
  foreach my $id (sort @grplist) {
    my $grpname = $cfg->get($id);
    next if $grpname eq undef || $grpname eq '';
    print "<td class=lbl>$grpname</td>\n";
    ++$colcnt;
  }
  print "</tr>\n";
  foreach my $login (sort @users) {
    my $user = TTXUser->new($login);
    next if $user eq undef || $user->{passwd} eq undef;
    print "<tr><td align=left><nobr>".$user->{fname}.' '.$user->{lname}." ($login)</nobr></td>\n";
    foreach my $id (sort @grplist) {
      my $grpname = $cfg->get($id);
      next if $grpname eq undef || $grpname eq '';
      my $checked = ' checked' if $cfg->get("mbr-$id") =~ /\b$login\b/;
      print "<td align=center><input type=checkbox value=1 name=\"mbr-$login-$id\"$checked></td>\n";
    }
    print "</tr>\n";
  }

  print <<EOT;
<tr>
<td colspan=$colcnt align=right>
<input type=submit value="Update All">
</td>
</tr>
</form>
</table>
</center>
EOT
}
# ==================================================================== tmplreset

sub tmplreset {
  my ($cfg, $tmplname) = @_;
  my $basedir = $cfg->get('basedir');
  $basedir =~ /(.*)/; $basedir = $1;
  if ($tmplname ne undef) {
    mkdir("$basedir/templates", 0777) if ! -d "$basedir/templates";
    foreach my $tmpl (@templates) {
      next if $tmpl->{name} ne $tmplname;
      if (open(TMPL, ">$basedir/templates/".$tmpl->{name})) {
        print TMPL $tmpl->{data};
        close TMPL;
        chmod(0777, "$basedir/templates/".$tmpl->{name});
        return undef;
      }
    }
    return "Unknown template $tmplname";
  }
  return undef;
}
# ======================================================================== build

sub build {
  my $cfg = $_[0];
  umask(0);
  my $basedir = $cfg->get('basedir');
  $basedir =~ /(.*)/; $basedir = $1;
  foreach my $d ('templates', 'tickets', 'sid', 'tmp') {
    mkdir("$basedir/$d", 0777) if ! -d "$basedir/$d";
  }
  foreach my $tmpl (@templates) {
    if (open(TMPL, ">$basedir/templates/".$tmpl->{name})) {
      print TMPL $tmpl->{data};
      close TMPL;
      chmod(0777, "$basedir/templates/".$tmpl->{name});
    }
  }
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
# ================================================================= listsendmail

sub listsendmail {
  my @list;
  if ($^O ne 'MSWin32') {
    my @options = ('/usr/bin/sendmail', '/usr/sbin/sendmail', '/usr/lib/sendmail');
    foreach my $option (@options) {
      if (-x $option) { push @list, $option; }
    }
  }
  return @list;
}
# ================================================================ whichsendmail

sub whichsendmail {
  if ($^O ne 'MSWin32') {
    my @options = ('/usr/bin/sendmail', '/usr/sbin/sendmail', '/usr/lib/sendmail');
    foreach my $option (@options) {
      if (-f $option) { print "$option<br>\n"; }
    }
  }
}
# ====================================================================== sysinfo

sub sysinfo {
  $cfg = $_[0];
  $query = $_[1];
  my $pwd = $query->param('pwd');
  print <<EOT;
<form action=$ENV{SCRIPT_NAME} method=post>
<input type=hidden name=cmd value=setup4>
<input type=hidden name=pwd value=$pwd>
<input type=submit value="Back to System Setup Form">
</form>
EOT
  print "<br>OS: $^O<br><br>\n";
  print "Perl: $]<br><br>\n";
  whichsendmail();
  eval "use DBI";
  if ($@ ne undef) {
    print "No DBI module found.<br>\n";
  } else {
    my $dbiversion;
    eval "$DBI::VERSION;";
    if ($@ eq undef) { $dbiversion = $DBI::VERSION; }
    print "DBI module ";
    if ($dbiversion ne undef) { print " version $dbiversion "; }
    else                      { print " of unknown version "; }
    print "found<br>\n";
    my @drivers = DBI->available_drivers(1);
    if (@drivers > 0) {
      print "<br class=tiny>DBD Drivers found:<br>\n";
      foreach my $driver (@drivers) {
        print "$driver ";
        if ($driver eq 'mysql') {
          print eval 'use DBD::mysql; $DBD::mysql::VERSION;';
        }
        print "<br>\n";
      }
    }
  }
  eval "use Net::SMTP";
  if ($@ ne undef) {
    print "No Net::SMTP module found.<br>\n";
  } else {
    eval "$Net::SMTP::VERSION;";
    if ($@ eq undef) { print 'Net:'.":SMTP module version $Net::SMTP::VERSION found<br>\n"; }
  }
  eval "use Authen::SASL";
  if ($@ ne undef) {
    print "No Authen::SASL module found.<br>\n";
  } else {
    eval "$Authen::SASL::VERSION;";
    if ($@ eq undef) { print 'Authen:'.":SASL module version $Authen::SASL::VERSION found<br>\n"; }
  }
  eval "use MIME::Parser";
  if ($@ ne undef) {
    print "No MIME::Parser module found.<br>\n";
  } else {
    eval "$MIME::Parser::VERSION;";
    if ($@ eq undef) { print 'MIME:'.":Parser module version $MIME::Parser::VERSION found<br>\n"; }
  }
  eval "use Time::Local";
  if ($@ ne undef) {
    print "No Time::Local module found.<br>\n";
  } else {
    eval "$Time::Local::VERSION;";
    if ($@ eq undef) { print 'Time:'.":Local module version $Time::Local::VERSION found<br>\n"; }
    else             { print 'Time:'.":Local module unknown version found<br>\n";}
  }
  eval "use GD";
  if ($@ ne undef) {
    print "No GD module found.<br>\n";
  } else {
    eval "$GD::VERSION;";
    if ($@ eq undef) { print "GD module version $GD::VERSION found<br>\n"; }
  }
  eval "use Encode";
  if ($@ ne undef) {
    print "No Encode module found.<br>\n";
  } else {
    eval "$Encode::VERSION;";
    if ($@ eq undef) { print "Encode module version $Encode::VERSION found<br>\n"; }
  }
  my $dir = scriptdir();
  if (-d $dir && opendir(CGIDIR, $dir)) {
    my @files = grep { /\.pm$/ && -f "$dir/$_" } readdir(CGIDIR);
    closedir CGIDIR;
    print <<EOT;
<br>
<table border=0 cellpadding=1>
<tr>
<td align=center colspan=3><b>Trouble Ticket Express modules available</b></td>
</tr>
<tr>
<td align=left><b>Module</b></td>
<td align=right><b>Version</b></td>
<td align=right><b>Revision</b></td>
</tr>
EOT
    my %minver = (
      TTXAnswerLib => 2.23,
      TTXFile => 2.23,
      TTXGroups => 2.23,
      TTXLayout => 2.23,
      TTXDashBoard => 2.23,
      TTXInvMod => 2.23,
      TTXMSSQLTickets => 2.23,
      TTXMySQLTickets => 2.23,
      TTXWorkHours => 2.23,
      TTXConfirmTicket => 2.23,
      TTXEReport => 2.23,
      TTXImage => 2.23,
      TTXLookup => 2.23,
      TTXMailMap => 2.23,
      TTXOrder4436 => 2.23,
      TTXPrint => 2.23,
      TTXSurvey => 2.23
    );
    foreach my $f (sort @files) {
      my $m = $f;
      $m =~ s/\.pm$//;
      next if $m !~ /^TTX/;
      print "<tr><td align=left>$m</td>\n";
      eval "use $m";
      if ($@ ne undef) {
        print "<td colspan=2 align=left><font color=red> <small><b>Error:</b> $@</small></font></td>\n";
      } else {
        print "<td align=right>";
        my $v;
        eval "\$v= \$$m:".":VERSION";
        if ($@ eq undef && $v ne undef) {
          if ($v < $TTXSetup::VERSION && ($minver{$m} eq undef || $minver{$m} > $v)) {
            print "<font color=red>$v, please upgrade</font>"
          } else {
            print "$v";
          }
        } else {
          print "-";
        }
        print "</td>\n<td align=right>";
        eval "\$v= \$$m:".":REVISION";
        if ($@ eq undef && $v ne undef) {
          print "$v";
        } else {
          print '-'
        }
        print "</td>\n";
      }
      print "</tr>\n";
    }
  }
  print "</table><br>\n";
  print <<EOT;
<form action=$ENV{SCRIPT_NAME} method=post>
<input type=hidden name=cmd value=setup4>
<input type=hidden name=pwd value=$pwd>
<input type=submit value="Back to System Setup Form">
</form>
EOT
}
# =================================================================== invenabled

my $_invenabled = undef;

sub invenabled {
  if ($_invenabled eq undef) {
    eval 'use TTXInvMod';
    if ($@ eq undef) {
      $_invenabled = 1;
    } else {
      $_invenabled = 0;
    }
  }
  return $_invenabled;
}
# ==================================================================== inventory

sub inventory {
  $cfg = $_[0];
  $query = $_[1];
  my $pwd = $query->param('pwd');
  my $noinvmod;
  if (!invenabled()) {
    $noinvmod = <<EOT;
<font color="red">Note:</font> The Inventory Module is not installed on your server.
Although you may manage your inventory, the inventory functionality will not be available
through user interface. For ordering information please refer to the
<a href="http://www.troubleticketexpress.com/inventorytracking.html"><nobr><b>Inventory Module Page</b></nobr></a>.
<br><br>
EOT
  }
  print <<EOT;
<span class=sm><b><a href="$ENV{SCRIPT_NAME}?cmd=setup4&pwd=$pwd">System Setup</a> |
<a href="$ENV{SCRIPT_NAME}?cmd=setup5&pwd=$pwd">Users</a> |
<a href="$ENV{SCRIPT_NAME}?cmd=grps&pwd=$pwd">Groups</a> |
<a href="$ENV{SCRIPT_NAME}?cmd=inventory&pwd=$pwd">Inventory</a>
</b></span>
<br>
<center><h3>Inventory Tracking</h3></center>
$noinvmod
The Inventory Tracking subsystem allows defining a list of items such as servers,
workstations, projects, premises, cars - anything you need to develop or provide a service for.
<br><br>
To track status of an item you may use notes and status indicator. The note is a
plain next (markup available) attached to an item. An operator may append messages
to the notes and you may edit notes using administrator interface.
<br><br>
You may assign any predefined state to the status field. You may define as many
status values (such as <i>OK</i>, <i>Maintenance</i>, <i>Repair</i>, <i>Occupied</i> etc) as you need.
<br><br>
You may associate an image with each state and item.
<br>
EOT
  eval "use TTXInventory";
  if ($@ ne undef) {
    print "<center><br><b>No TTXInventory.pm module available\n</b><br><br></center><b>Error:</b> $@<br>\n";
    return;
  }
  my %inputs;
  my %inputs_quot;
  my %inputs_lt;
  my @inputlist = ('dbrdtitle', 'label', 'show');
  foreach my $key (@inputlist) {
    if ($query->param('do') ne 'gen') {
      $inputs{$key} = $cfg->get("inventory.$key");
    } else {
      $inputs{$key} = TTXCommon::cleanit($query, $key);
    }
    $inputs_quot{$key} = $inputs{$key};
    $inputs_quot{$key} =~ s/"/&quot;/g;
    $inputs_lt{$key} = $inputs{$key};
    $inputs_lt{$key} =~ s/</&lt;/g;
  }
#
# Generic ========================================
#
  if ($query->param('do') eq 'gen') {
    foreach my $key ('dbrdtitle', 'label', 'show') {
      $cfg->set("inventory.$key", $inputs{$key});
    }
    $cfg->save();
  }
#
# Items ===========================================
#
  my $newtitle = TTXCommon::cleanit($query, 'newtitle');
  my $newimg = TTXCommon::cleanit($query, 'newimg');
  my $newnotes = TTXCommon::cleanit($query, 'newnotes');
  if ($query->param('do') eq 'items') {
    my $newid;
    TTXInventory::lockdb();
    if ($newtitle ne undef) {
      my %item;
      $item{title} = TTXCommon::decodeit($newtitle);
      $item{img} = TTXCommon::decodeit($newimg);
      $item{notes} = TTXCommon::decodeit($newnotes);
      $newid = TTXInventory::add(\%item);
      if ($newid eq undef) {
        my $err = TTXInventory::error();
        print <<EOT;
<center>
<b><font color=red>Error: $err</red></b>
</center>
EOT
      } else {
        $newtitle = $newimg = $newnotes = undef;
      }
    }
#
# Process item deletions & updates
#
    my @ilist = sort {$a <=> $b}TTXInventory::list();
    my $dflt = $newid;
    foreach my $id (@ilist) {
      next if $id eq $newid;
      if ($query->param("del$id")) {
        TTXInventory::del($id);
        next;
      }
      my $item = TTXInventory::getitem($id);
      next if $item eq undef;
      $dflt = $id if ($query->param('dflt') eq $id || $dflt eq undef);
      $item->{title} = TTXCommon::cleanit($query, "title$id", 1);
      $item->{img} = TTXCommon::cleanit($query, "img$id", 1);
      $item->{notes} = TTXCommon::cleanit($query, "notes$id", 1);
    }
    TTXInventory::savedb();
    TTXInventory::unlockdb();
    if ($dflt ne $cfg->get('inventory.defaultitem')) {
      $cfg->set('inventory.defaultitem', $dflt);
      $cfg->save();
    }
  }
#
# Status ===========================================
#
  my $newstitle = TTXCommon::cleanit($query, 'newstitle');
  my $newsimg = TTXCommon::cleanit($query, 'newsimg');
  if ($query->param('do') eq 'status') {
    my $newid;
    TTXInventory::lockdb();
    my $states = TTXInventory::loadstates();
    if ($newstitle ne undef) {
      my %state;
      $state{title} = TTXCommon::decodeit($newstitle);
      $state{img} = TTXCommon::decodeit($newsimg);
      $newid = TTXInventory::addstate(\%state);
      if ($newid eq undef) {
        my $err = TTXInventory::error();
        print <<EOT;
<center>
<b><font color=red>Error: $err</red></b>
</center>
EOT
      } else {
        $newstitle = $newsimg = undef;
      }
    }
#
# Process state deletions & updates
#
    my @slist = sort {$a <=> $b} keys %{$states};
    my $dflt = $newid;
    foreach my $id (@slist) {
      next if $id eq $newid;
      if ($query->param("del$id")) {
        delete $states->{$id};
        next;
      }
      my $state = $states->{$id};
      next if $state eq undef;
      $dflt = $id if ($query->param('dflt') eq $id || $dflt eq undef);
      $state->{title} = TTXCommon::cleanit($query, "title$id", 1);
      $state->{img} = TTXCommon::cleanit($query, "img$id", 1);
    }
    TTXInventory::savestates();
    TTXInventory::unlockdb();
    if ($dflt ne $cfg->get('inventory.defaultstate')) {
      $cfg->set('inventory.defaultstate', $dflt);
      $cfg->save();
    }
  }
  my $showsel = ' checked' if $cfg->get('inventory.show');
  print <<EOT;
<br>
<form action=$ENV{SCRIPT_NAME} method=post>
<input type=hidden name=cmd value=inventory>
<input type=hidden name=do value=gen>
<input type=hidden name=pwd value=$pwd>
<table cellpadding=5>
<tr>
<td>
<hr>
</td>
<td align=center>
<b>General Settings</b>
</td>
<td>
<hr>
</td>
</tr>
<tr>
<td align=left>
<b><nobr>DashBoard Title</nobr></b>
</td>
<td align=left>
<input type=text size=25 name=dbrdtitle value="$inputs_quot{dbrdtitle}">
</td>
<td align=left>
The DashBoard page provides a review of all inventory items.
</td>
</tr>
<tr>
<td align=left>
<b><nobr>Item Label</nobr></b>
</td>
<td align=left>
<input type=text size=25 name=label value="$inputs_quot{label}">
</td>
<td align=left>
E.g. System, Server, Project etc.
</td>
</tr>
<tr>
<td align=left>
<b><nobr>Show Selector</nobr></b>
</td>
<td align=left>
<input type=checkbox name=show value=1$showsel>
</td>
<td align=left>
Show item selector on contact form
</td>
</tr>
<tr>
<td colspan=3 align=right>
<input type=submit value="Update General Settings">
</td>
</tr>
</table>
</form>
EOT
my $label_lt = $inputs_lt{label};
$label_lt = 'Item' if $label_lt eq undef;
my $label_quot = $inputs_quot{label};
$label_quot = 'Item' if $label_quot eq undef;
  print <<EOT;
<br>
<form action=$ENV{SCRIPT_NAME} method=post>
<input type=hidden name=cmd value=inventory>
<input type=hidden name=do value=items>
<input type=hidden name=pwd value=$pwd>
<table width="100%" cellpadding=6>
<tr>
<td colspan=2>
<hr>
</td>
<td align=center>
<b><nobr>$label_lt List</nobr></b>
</td>
<td colspan=3 width="100%">
<hr>
</td>
</tr>
<tr>
<td align=center>
Del
</td>
<td align=center>
Id
</td>
<td align=left>
Title
</td>
<td align=center>
Default
</td>
<td align=left width="100%" colspan=2>
Image URL
</td>
</tr>
EOT
  my @ilist = sort {$a <=> $b}TTXInventory::list();
  foreach my $id (@ilist) {
    my $item = TTXInventory::getitem($id);
    next if $item eq undef;
    my $title = TTXCommon::encodeit($item->{title});
    $title =~ s/"/&quot;/g;
    my $img = TTXCommon::encodeit($item->{img});
    $img =~ s/"/&quot;/g;
    my $simg = $img || $cfg->get('imgurl').'/dot.gif';
    my $isdefault = ' checked' if $cfg->get('inventory.defaultitem') eq $id;
    my $notes = TTXCommon::encodeit($item->{notes});
    $notes =~ s/</&lt;/g;
    print <<EOT;
<tr>
<td align=center>
<input type=checkbox name=del$id value=1>
</td>
<td align=center>
$id
</td>
<td align=left>
<input type=text name=title$id size=25 value="$title">
</td>
<td align=center>
<input type=radio name=dflt value=$id$isdefault>
</td>
<td align=left>
<input type=text name=img$id size=40 value="$img">
</td>
<td align=center rowspan=2>
<img src="$simg">
</td>
</tr>
<tr>
<td colspan=2>&nbsp;</td>
<td align=left colspan=3>
<b><small>Notes</small></b><br>
<textarea wrap=virtual rows=3 cols=55 name=notes$id>$notes</textarea>
</td>
</tr>
<tr>
<td colspan=6><hr></td>
</tr>
EOT
  }
  my $newtitle_quot = $newtitle;
  $newtitle_quot =~ s/"/%quot;/g;
  my $newimg_quot = $newimg;
  $newimg_quot =~ s/"/%quot;/g;
  my $newnotes_lt = $newnotes;
  $newnotes_lt =~ s/"/%quot;/g;
print <<EOT;
<tr>
<td colspan=2 align=center><b>New</b></td>
<td align=center>
<input type=text name=newtitle size=25 value="$newtitle_quot">
</td>
<td>&nbsp;</td>
<td align=left colspan=2>
<input type=text name=newimg size=40 value="$newimg_quot">
</td>
</tr>
<tr>
<td colspan=2>&nbsp;</td>
<td align=left colspan=3>
<b><small>Notes</small></b><br>
<textarea rows=3 cols=55 wrap=virtual name=newnotes>$newnotes_lt</textarea>
</td>
</tr>
<tr>
<td colspan=6 align=right>
<input type=submit value="Update $label_quot List">
</td>
</tr>
</table>
</form>
EOT


  print <<EOT;
<br>
<form action=$ENV{SCRIPT_NAME} method=post>
<input type=hidden name=cmd value=inventory>
<input type=hidden name=do value=status>
<input type=hidden name=pwd value=$pwd>
<table width="100%" cellpadding=6>
<tr>
<td colspan=2>
<hr>
</td>
<td align=center>
<b><nobr>States</nobr></b>
</td>
<td colspan=3 width="100%">
<hr>
</td>
</tr>
<tr>
<td align=center>
Del
</td>
<td align=center>
Id
</td>
<td align=left>
Title
</td>
<td align=center>
Default
</td>
<td align=left width="100%" colspan=2>
Image URL
</td>
</tr>
EOT
  my $states = TTXInventory::loadstates();
  if ($states ne undef) {
    my @slist = sort {$a <=> $b} keys %{$states};
    foreach my $id (@slist) {
      my $state = $states->{$id};
      next if $state eq undef;
      my $title = TTXCommon::encodeit($state->{title});
      $title =~ s/"/&quot;/g;
      my $img = TTXCommon::encodeit($state->{img});
      $img =~ s/"/&quot;/g;
      my $simg = $img || $cfg->get('imgurl').'/dot.gif';
      my $isdefault = ' checked' if $cfg->get('inventory.defaultstate') eq $id;
      print <<EOT;
<tr>
<td align=center>
<input type=checkbox name=del$id value=1>
</td>
<td align=center>
$id
</td>
<td align=left>
<input type=text name=title$id size=25 value="$title">
</td>
<td align=center>
<input type=radio name=dflt value=$id$isdefault>
</td>
<td align=left>
<input type=text name=img$id size=40 value="$img">
</td>
<td align=center>
<img src="$simg">
</td>
</tr>
EOT
    }
  } else {
    my $err = TTXInventory::error();
    print <<EOT;
<tr>
<td colspan=6 align=left>
<b><font color=red>Error: $err</red></b>
</td>
</tr>
EOT
  }
  my $newstitle_quot = $newstitle;
  $newstitle_quot =~ s/"/%quot;/g;
  my $newsimg_quot = $newsimg;
  $newsimg_quot =~ s/"/%quot;/g;
print <<EOT;
<tr>
<td colspan=2 align=center><b>New</b></td>
<td align=center>
<input type=text name=newstitle size=25 value="$newstitle_quot">
</td>
<td>&nbsp;</td>
<td align=left colspan=2>
<input type=text name=newsimg size=40 value="$newsimg_quot">
</td>
</tr>
<tr>
<td colspan=6 align=right>
<input type=submit value="Update States">
</td>
</tr>
</table>
</form>
EOT

}

1;
=cut
