package TTXLogin;
#
# This module is a part of Trouble Ticket Express package
# http://www.troubleticketexpress.com
#
# COPYRIGHT: 2002-2007, United Web Coders
# http://www.unitedwebcoders.com
#
# $Revision: 436 $
# $Date: 2007-10-11 16:21:10 +0400 (Thu, 11 Oct 2007) $
#

$TTXLogin::VERSION='2.24';
BEGIN {
  $TTXLogin::REVISION = '$Revision: 436 $';
  if ($TTXLogin::REVISION =~ /(\d+)/) {
    $TTXLogin::REVISION = $1;
  }
};
use strict;
use TTXCommon;
require TTXUser;
require TTXSession;

# ======================================================================== login

sub login {
  my ($cfg, $query, $data) = @_;
  $data->{PAGEHEADING} = '[%Login%]';
  return undef if !$query->param('dologin');
  if (TTXCommon::cleanit($query, 'login') eq undef) {
    $data->{ERROR_MESSAGE} = '[%Missing User ID%]';
    return undef;
  }
  if (TTXCommon::cleanit($query, 'passwd') eq undef) {
    $data->{ERROR_MESSAGE} = '[%Missing Password%]';
    return undef;
  }
  my $user = TTXUser->new($query->param('login'));
  if ($user eq undef || ($user->get('passwd') eq undef) || ($user->get('passwd') ne $query->param('passwd'))) {
    $data->{ERROR_MESSAGE} = '[%Wrong User ID or Password%]';
    return undef;
  }
  $cfg->set('_USER', $user);
  my $session = TTXSession->new();
  $session->login($query->param('login'));
  $user->set('session', $session);
  $query->param(-name => 'checkupdate', -value => '1');
  if ($cfg->get('rememberme')) {
    $cfg->set('_GLOBAL_SID', $session->sid());
  } else {
    $query->param('sid', $session->sid());
  }
  if ($query->param('nextcmd') ne undef) {
    $query->param(-name => 'cmd', -value => $query->param('nextcmd'));
    return $query->param('nextcmd');
  }
  return 'helpdesk';
}

1;
#
