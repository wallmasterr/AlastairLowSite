package Fcntl_flock;
use strict;
use Fcntl qw(:DEFAULT :flock :seek);
use Symbol 'qualify_to_ref';
use Exporter;

our @ISA="Exporter";
our @EXPORT="flock";

# Linux struct flock
#   short l_type;
#   short l_whence;
#   off_t l_start;
#   off_t l_len;
#   pid_t l_pid;

my $FLOCK_STRUCT = 's s l l i';
# c2ph says: typedef='s2 l2 i', sizeof=16

sub struct_flock {
	if (wantarray) {
		my ($type, $whence, $start, $len, $pid) = unpack($FLOCK_STRUCT, $_[0]);
		return ($type, $whence, $start, $len, $pid);
	} else {
		my ($type, $whence, $start, $len, $pid) = @_;
		return pack($FLOCK_STRUCT, $type, $whence, $start, $len, $pid);
	}
}

sub flock(*$) {

	my ($fh, $op)=@_;
	$fh = qualify_to_ref($fh, caller);
	my $nonblock=0;
	if($op&(LOCK_NB)) {
		$op&=~(LOCK_NB);
		$nonblock=1;
	}
	my $lock;
	if($op==LOCK_SH) {
		# shared
		$lock = Fcntl_flock::struct_flock(F_RDLCK, SEEK_SET, 0, 0, 0);
	} elsif($op==LOCK_EX) {
		# exclusive
		$lock = Fcntl_flock::struct_flock(F_WRLCK, SEEK_SET, 0, 0, 0);
	} else {
		# unlock (LOCK_UN)
		$lock = Fcntl_flock::struct_flock(F_UNLCK, SEEK_SET, 0, 0, 0);
	}
	return ($nonblock?fcntl($fh, F_SETLK, $lock):fcntl($fh, F_SETLKW, $lock));
}

1;
