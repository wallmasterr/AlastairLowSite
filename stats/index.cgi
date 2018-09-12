#!/usr/bin/perl -w
use strict;
use BSD::Resource;
setrlimit(RLIMIT_AS, 128000000, 1280000000);
setrlimit(RLIMIT_CPU, 120, 120);
use CGI;
use Cwd 'getcwd';
use IO::Handle;
STDOUT->autoflush(1);
my $cwd=getcwd();
my $root_path;
if($cwd=~m#^(/home/(?:sites|cluster-sites/\d+)/[\w\.\-]+/)#) {
	$root_path=$1;
} else {
	die
}

my $cgi=new CGI;
%ENV=(PATH=>'/bin:/usr/bin:/usr/local/bin', HTTP_HOST=>$ENV{HTTP_HOST});
my $pid=open(CHILD, "-|");
die unless defined $pid;
if(!$pid) {
	# child
	
	# Get the mtime of webalizer.current for later...
	my $current_mtime;
	my @cstat=stat("webalizer.current");
	if(@cstat) {
		$current_mtime=$cstat[9];
	} else {
		$current_mtime=0;
	}
	#

	my %files;
	my @poss_files=<$root_path/logs/*-access_log{,.*}>;
	for my $poss_file (@poss_files) {

		my $sort_fn=join "", reverse split(//, $poss_file);
		$sort_fn=~s/^(zg|2zb)\.//; # Ignore compression stuff
		$sort_fn=~s/^(\D)/0.$1/; # Make sure all are numbered.

		# Use timestamp for emergency sort order
		my @stat=stat($poss_file);
		next unless @stat;
		$sort_fn.=".$stat[9]";

		# Don't bother looking at obviously-unchanged files
		next if $stat[9]<$current_mtime;

		$files{$sort_fn}=$poss_file;
	}
	# We want high-numbered ones first
	for(reverse sort keys %files) {
		system("webalizer","-D", "dns.cache","-n", $ENV{HTTP_HOST}, $files{$_});
	}
	exit 0;
}
local $/=undef;
my $data=<CHILD>;
close CHILD;
if($data) {
	print STDERR $data;
}
print $cgi->redirect("index.html");
