#!/usr/bin/perl
use strict;
use CGI;
#use GD;

my $query = new CGI;

if ($query->param('generateimage')) {
 generateImage();
} else {
 # We weren't asked for the image,
 # so let's return a simple web page
 # that contains the image
 my $gderror;
 eval 'use GD';
 if ($@ ne undef) {
   $gderror = "<br><br>The following error occured when trying to load GD.pm<br><br>\n<b>$@</b>\n";
 }
 print $query->header;
 print <<EOM
<html>
<body>
<br><br>
<center><b>GD Library Test
<br><br>
<table cellpadding="5" cellspacing="5">
<tr>
<td width="50%" align="center"><b><nobr>Remote image</nobr></b></td>
<td width="50%" align="center"><b><nobr>Local image</nobr></b></td>
</tr>
<tr>
<td align=center>
<img src="http://www.troubleticketexpress.com/testgd.gif">
</td>
<td align=center>
<img src="$ENV{SCRIPT_NAME}?generateimage=1">
</td>
</tr>
</table>
<br>
<table width="450">
<tr>
<td align=left>
If Local image is the same as (or similar to) the Remote image, both the GD Library
and GD.pm module are installed on your server.
<br><br>
If you do not see the Local image, either GD Library or GD.pm module are not available.
<a href="http://www.troubleticketexpress.com/gdlibrary.html"><nobr>Click here</nobr></a> for more info.
<br><br>
If you do not see the Remote image, either our web site is not available at the moment
or you have Internet connectivity problems. Anyway, make sure you see the Local image
(red square inside of black square).
$gderror
</td>
</tr>
</table>
</center>
<body>
</html>
EOM
;
}

sub generateImage {
 eval 'use GD';
 return if $@ ne undef;
 # We MUST do this on Windows or the
 # image will be garbled, and it
 # doesn't hurt on Unix/Linux/etc
 binmode STDOUT;
 # Output the right content type
 # for a PNG-format image
 print $query->header("image/gif");
 # Draw an image with a red rectangle
 # in the middle
 my $image = new GD::Image(100, 100);
 my $black = $image->colorAllocate(
  0, 0, 0);
 my $red = $image->colorAllocate(
  255, 0, 0);
 $image->filledRectangle(
  25, 25, 75, 75, $red);
 # Output the image to the browser
 print $image->gif;
}
