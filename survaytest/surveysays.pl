#!/usr/bin/perl

# SurveySays                           Version 2.0 
# Copyright 1998-2002 by Matt Riffle   All Rights Reserved.            
# Initial Full Release: 7/4/98         This Release: 6/21/02 
# pingPackets                          http://www.pingpackets.com/     

# This program is free software; you can redistribute it and/or       
# modify it under the terms of the GNU General Public License         
# as published by the Free Software Foundation; either version 2      
# of the License, or (at your option) any later version.              
#                                                                     
# This program is distributed in the hope that it will be useful,     
# but WITHOUT ANY WARRANTY; without even the implied warranty of      
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the       
# GNU General Public License for more details.  It is included in     
# this distribution in the file "LICENSE".                        
#                                                                     
# You should have received a copy of the GNU General Public License   
# along with this program; if not, write to the Free Software         
# Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA           
# 02111-1307, USA.                                                    

# Some standard modules -- don't edit these
use strict;
use CGI qw/header param/;
require "./Fcntl_flock.pm";
use Fcntl ':flock';

# This is the path to the data file the script will use to store results.
# The script must either have permissions to write to the directory the
# file will be stored in (and it will create the file itself on first run),
# or you can create the file yourself (as a 0-byte file), and just give
# the script permission to write to the file.

my $DATAFILE = "/home/sites/lowtek.co.uk/public_html/survaytest/data.txt";

# This is the path to another file that the web server can open.  This will
# be used as a "semaphore" for file-locking to ensure the integrity of the
# data file.

my $SEMAPHORE = "/home/sites/lowtek.co.uk/public_html/survaytest/semaphore.txt";

# This is the path to a temporary directory the script can use to write out
# results first.  You can set it to "" if you'd like, but using the
# temporary directory increases the safety of your data.

my $TMP_DIR = "/tmp";

# This is the URL needed to call the script directly.

my $SCRIPT_URL = "surveysays.pl";

# This is a code that is unique among all your SurveySays scripts.  It is
# used as the name of the optional voting cookie, as well as for telling
# which poll is being voted on.  It should be short, alphanumeric, and
# unique from other instances of this script.

my $POLL_CODE = "UNIQUECODEHERE";

# This is the "name" of your poll.  It should only be a few words long.

my $POLL_NAME = "SurveySays v2.0";

# These variables control the look of your poll.  $TOP_COLOR is the color
# at the top of the poll, where the $POLL_NAME will be.  $BOT_COLOR is the
# color of the bottom of the poll.  $FONT_COLOR is the color the text will
# be, and $FONT_SIZE is how big it will be. $FONT_FACE controls the font
# that is used by the poll. $TABLE_WIDTH controls how wide your poll will
# be (I recommend keeping the default values as given for $FONT_SIZE and
# $TABLE_WIDTH).

my $TOP_COLOR = "#33ccff";
my $FONT_FACE="Arial,Helvetica";
my $BOT_COLOR = "#ffffff";
my $FONT_COLOR = "#000000";
my $FONT_SIZE = "-2";
my $TABLE_WIDTH = "125";

# This variable is the question you are asking in your poll.

my $QUESTION = "What is your favorite color?";

# @CHOICES represents the possible answers people can give.  It should
# be formatted as shown.

my @CHOICES = ("Red","Green","Blue");

# If $GRAPHICAL is set to 1, a 'bar graph' of sorts will be printed along
# side percentages when the results are shown (set it to 0 to report only
# percentages).  If used, $GR_FILE is the URL to call the "dot" that is
# used to create the bars (feel free to replace the default purple one).
# $GR_HEIGHT is the height in pixels the bar should be, and $GR_SCALE helps
# control the width (when set to 1, an answer with 25% of the vote would
# have a bar 25 pixels wide;  if set to 2, 25% would yield a 50 pixel bar
# and so on).

my $GRAPHICAL = 1;
my $GR_FILE = "dot.gif";
my $GR_SCALE = 1; 
my $GR_HEIGHT = 10;

# There are several ordering options for displaying results.  If this
# variable is set to 'given' they will be ordered as they are in @CHOICES.
# If set to 'low' they will be ordered from low to high.  If set to 'high'
# they will be ordered from high to low (which is also the default).

my $SORT_RESULTS_BY = 'high';

# If you want the total number of votes received to be reported with the
# results, set this to 1.  Else, set it to 0.

my $REPORT_TOTAL_VOTES = 1;

# If you'd like to only display results after a certain number of votes are
# cast, set this variable that number.  Set it to 0 (zero) if you'd like to
# always display the results.

my $SHOW_VOTES_AFTER = 0;

# The script has two ways of checking for people who have already voted.  One 
# way is by setting a cookie.  The other is by keeping track of the IP 
# addresses votes are cast from.  To use both, set this variable to 'all'.  To 
# use cookies only, set it to 'cookie'.  To use IPs only, set it to 'ip'.  I 
# recommend setting it to 'all' -- neither method is 100% effective, but the 
# combination of them is pretty good.

my $CHECK_BY = 'all';

# This variable should be set to the number of IP addresses to remember, if
# using IP checking.  I recommend between 5 and 10. 

my $IPS_CACHED = 10;

# If you are using cookies, the following two variables must be set. 
# $COOKIE_REALM should likely be ".example.com" using your domain name.
# $COOKIE_DAYS should be set to the number of days to wait before the
# cookie expires.

my $COOKIE_REALM = ".lowtek.co.uk";
my $COOKIE_DAYS = 45;

# If the browser doesn't send the "HTTP_REFERER" variable, which is pretty
# common, the script won't know by default where to redirect to.  Setting
# this to the URL that the poll is viewed at allows the script to continue
# working.

my $PANIC_URL = "http://www.example.com/pollpage.shtml";

# This variable, if set to 1, may help alleviate problems with browsers and
# proxy servers caching your page and not displaying poll results.  

my $SUPPRESS_CACHE = 1;

# This variable, if set to 1, adds a text link to the poll, which
# allows the user to see the poll results without voting.

my $WITHOUT_VOTE = 1;

# Once you are done with a poll, you can set $ARCHIVE to 1 so that the poll
# only returns results when called, and cannot be voted on.  Note that this
# is ridiculously inefficient -- you should simply load the poll, save the
# HTML code, and use that.  However, people wanted it, so here it is.

my $ARCHIVE = 0;

# Do Not Edit Below This

surveysays();
exit;

sub surveysays {
  initialize_data();

  # Handle absence of HTTP_REFERER if possible
  if (!$ENV{HTTP_REFERER} && $PANIC_URL) { $ENV{HTTP_REFERER} = $PANIC_URL }

  # get form parameters
  my $f = get_params(); 

  # If person has already voted, return results
  check_for_vote();

  # Results only, if that's what was requested
  return_results('only') if $ENV{QUERY_STRING} =~ /show_results/;

  # Take Care of the Vote, if any
  register_vote($f) if $ENV{QUERY_STRING} eq $POLL_CODE; 

  # If none of the above, return quiz
  return_quiz();

}

sub initialize_data {
    lock_data(LOCK_EX) or error("Couldn't lock file");
    unless (-z $DATAFILE || !-e $DATAFILE) {
        unlock_data();
        return;
    }
    open(FILE,">$DATAFILE") or error('Error writing file');
    print FILE 'CHOICES|||';
    for (my $i = 1; $i <= scalar(@CHOICES); $i++) {
        print FILE '0';
        print FILE '|||' unless ($i == scalar(@CHOICES));
    }
    print FILE "\nIPS|||";
    for (my $i = 1; $i <= $IPS_CACHED; $i++) {
        print FILE '0.0.0.0';
        print FILE '|||' unless ($i == $IPS_CACHED);
    }
    close(FILE);
    unlock_data();
}

sub check_for_vote {

    return_results() if $ARCHIVE;

    lock_data(LOCK_SH) or error("Couldn't lock file");
    open(FILE,"<$DATAFILE") or error('Error opening file');
    chomp(my $totals = <FILE>);
    chomp(my $ips = <FILE>);
    close(FILE);
    unlock_data();

    my ($check1,@totals) = split(/\|\|\|/,$totals);
    my ($check2,@ips) = split(/\|\|\|/,$ips);

    # Error Checking
    error('Data file corrupted') 
        unless ($check1 eq 'CHOICES' && $check2 eq 'IPS');
  
    my $voted;

    # ip check
    if ($CHECK_BY =~ /(ip|all)/ && $IPS_CACHED > 0) {
        for my $ip (@ips) {
            $voted++ if $ip eq $ENV{REMOTE_ADDR};
        }
    }

    # cookie check
    if ($CHECK_BY =~ /(cookie|all)/) {
        my $cgi = new CGI;
        $voted++ if ($cgi->cookie($POLL_CODE) eq 'voted');
    }

    return_results() if $voted;
}

sub register_vote {
    my $f = shift;

    # get the lock
    lock_data(LOCK_EX) or error("Couldn't lock file");

    # get the current data
    open(FILE,"<$DATAFILE") or error('Error opening data file');
    chomp(my $totals = <FILE>);
    chomp(my $ips = <FILE>);
    close(FILE);

    my ($check,@totals) = split(/\|\|\|/,$totals);
    my ($check2,@ips) = split(/\|\|\|/,$ips); 
    shift @ips while scalar(@ips) >= $IPS_CACHED;

    # Error Checking
    error('Data file corrupted') unless $check eq 'CHOICES';
    error('Number of choices has changed') 
        unless scalar(@CHOICES) == scalar(@totals);

    # Count the vote
    $totals[$f->{quiz}-1]++ if defined($totals[$f->{quiz}-1]);

    # write the new data file
    my $write_file = ($TMP_DIR) ?  "$TMP_DIR/$$" . time . ".ss" : $DATAFILE;
    open(FILE,">$write_file") or error('Error writing file');
    print FILE 'CHOICES|||', join('|||',@totals), "\n";
    print FILE 'IPS|||', join('|||',@ips), "|||$ENV{REMOTE_ADDR}";
    close(FILE);

    # Copy file if we used a temp one
    if ($TMP_DIR) { system("/bin/mv","-f",$write_file,$DATAFILE) 
        and error('Error replacing data file') }

    # unlock file
    unlock_data();

    # Cache Supression Code
    my $add_on = ($SUPPRESS_CACHE) ? '?survey' . int(rand(99999)) : '';

    # Return to page
    print "Location: $ENV{HTTP_REFERER}$add_on\n";

    # Try to set cookie if desired
    if ($CHECK_BY =~ /^(cookie|all)$/) {
        my $cgi = new CGI;
        $COOKIE_DAYS = 60 if $COOKIE_DAYS =~ /\D/;
        my $cookie = $cgi->cookie(-name    => $POLL_CODE,
                                  -value   => 'voted',
                                  -expires => "+${COOKIE_DAYS}d",
                                  -path    => '/',
                                  -domain  => $COOKIE_REALM);
        print $cgi->header(-cookie=>$cookie);
    }

    print "\n";
    exit;
}

sub return_quiz {
    lock_data(LOCK_SH) or error("Couldn't lock file");
    open(FILE,"<$DATAFILE") or error('Error opening data file');
    chomp(my $totals = <FILE>);
    close(FILE);
    unlock_data();

    my ($check, @totals) = split (/\|\|\|/,$totals);

    # Error Checking
    error('Data file corrupted') unless $check eq 'CHOICES';
    error('Number of choices has changed') 
        unless scalar(@CHOICES) == scalar(@totals);

    # Return Table
    print header, table_top(), <<END; 
<form method=post action="$SCRIPT_URL?$POLL_CODE">
END
    for (my $i = 1; $i <= scalar(@CHOICES); $i++) {
        print "<input type=radio name=quiz value=\"$i\">$CHOICES[$i-1]<br>";
    }  
    print <<END;
<p><center><input type=submit value="Vote!"></center></form>
END
    if ($WITHOUT_VOTE) {
        print <<END;
<div align="center">[ <a href="$ENV{HTTP_REFERER}?show_results">
View Results</a> ]</div>
END
    }
    print table_bottom(); 
    exit;
}

sub return_results {
    my $arg = shift;

    lock_data(LOCK_SH) or error("Couldn't lock file");
    open(FILE,"<$DATAFILE") or error('Error opening data file');
    chomp(my $totals = <FILE>);
    close(FILE);
    unlock_data() or error('Error unlocking file');

    my ($check, @totals) = split (/\|\|\|/,$totals);

    # Error Checking
    error('Data file corrupted') unless $check eq 'CHOICES';
    error('Number of choices has changed') 
        unless scalar(@CHOICES) == scalar(@totals);

    my ($mastertotal,@processed);
    for (my $i = 0; $i < scalar(@CHOICES); $i++) {
        $mastertotal += $totals[$i];
        push(@processed,"$totals[$i]|||$CHOICES[$i]");
    }
    if ($SORT_RESULTS_BY eq 'low') {
        @processed = sort {$a <=> $b} (@processed);
    } elsif ($SORT_RESULTS_BY ne 'given') {
        @processed = sort {$b <=> $a} (@processed);
    }

    print header, <<END;
<table border=0 width=$TABLE_WIDTH cellspacing=0 cellpadding=2><tr>
<td valign=center align=middle bgcolor=\"$TOP_COLOR\">
<font face=\"$FONT_FACE\" color=\"$FONT_COLOR\" size=\"$FONT_SIZE\">
<b>$POLL_NAME</b></font></td></tr>
<tr><td valign=top align=left bgcolor=\"$BOT_COLOR\">
<font face=\"$FONT_FACE\" size=\"$FONT_SIZE\" color=\"$FONT_COLOR\">
$QUESTION<p>\n
END
    if ($mastertotal < $SHOW_VOTES_AFTER) {
        print <<END;
Please check back later for the results.
END
        print table_bottom();
        exit;
    }
    for (my $i = 0; $i < scalar(@CHOICES); $i++) {
        my ($num,$what) = split(/\|\|\|/,$processed[$i]);
        my $percent = sprintf("%3.2f",($num/($mastertotal || 1))*100);
        if ($GRAPHICAL) {
             my $width = int($percent * $GR_SCALE); 
             print <<END;
<img align=absmiddle src="$GR_FILE" height="$GR_HEIGHT" width="$width"><br>
END
        }
        print "$what: $percent\%<br>\n";
     }    

    if ($REPORT_TOTAL_VOTES) { 
        print "<p><div align=center>Total Votes: $mastertotal</div>\n";
    }
    if ($arg eq 'only') {
        print <<END;
<br><div align="center">[ <a href="$ENV{HTTP_REFERER}">Return To
Vote</a> ]</div>
END
    }
    print table_bottom();
    exit;
}

sub table_top {
    return <<END;
<table border="0" width="$TABLE_WIDTH" cellspacing="0" cellpadding="2">
<tr><td valign="center" align="middle" bgcolor="$TOP_COLOR">
<font face="$FONT_FACE" color="$FONT_COLOR" size="$FONT_SIZE">
<b>$POLL_NAME</b>
</font></td></tr>
<tr><td valign="top" align=left bgcolor="$BOT_COLOR">
<font face="$FONT_FACE" size="$FONT_SIZE" color="$FONT_COLOR">
$QUESTION<p>
END
}

sub table_bottom {
    # The GPL says you can do what you want, so comment the credit out if you
    # must.  It's not much of a "customization" though.
    return <<END;
<br>
<div align=center>
<a href="http://www.pingpackets.com/apps/perl/surveysays/"
  target="_top">by MPR</a>
</font></td></tr></table>
END
}

sub error {
    print header, table_top(), "[Error: ", shift, "]<p>",
          table_bottom();
    exit; 
}

sub get_params {
    my $f; 
    for my $key (param()) { $f->{$key} = join (' ',param($key)) }
    return $f;
}

{
 
    local *SEM;

    sub lock_data {
        my $type = shift;
        open(SEM,">$SEMAPHORE") or return undef;
        flock(SEM,$type) or return undef;
        return 1;
    }

    sub unlock_data {
        close(SEM);
    }

}

