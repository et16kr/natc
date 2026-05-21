package IO::ExtTTY;

use strict;
use Exporter;
use IO::Pty;
use POSIX qw( setsid);
use Fcntl qw( F_SETFL F_GETFL O_NONBLOCK);
use vars  qw(@ISA @EXPORT);

@ISA = qw (IO::Pty Exporter);
@EXPORT= qw();

sub new {
  my $class = shift;
  my $cmd   = \@_;
  # Create the pty which we will use to pass process info.
  my $self  	  = new IO::Pty;
  my $name_of_tty = $self->IO::Pty::ttyname()|| die "$class: Could not assign a pty";
  ${*$self}{tty_name}  = $name_of_tty;
#  bless ($self, $class);

# 
   $self->autoflush;
  
  # This is defined here since the default is different for
  # initialized handles as opposed to spawned processes.
 ${*$self}{pid} = fork;
 my $pid=${*$self}{pid};
 unless (defined ($pid)) { warn "Cannot fork: $!"; return undef}
 unless ($pid){
  # Child
  # Create a new 'session', lose controlling terminal.
    POSIX::setsid() || warn "Couldn't perform setsid. Strange behavior may result.\r\n Problem: $!\r\n";
 
   my $tty = $self->IO::Pty::slave(); # Create slave handle.
    # We have to close everything and then reopen ttyname after to get
    # a controlling terminal.

    close($self);
  # -*- Close all descriptor -*- 
    close STDIN; close STDOUT;

    open(STDIN,"<&". $tty->fileno()) || die "Couldn't reopen ". $name_of_tty ." for reading, $!\r\n";
    open(STDOUT,">&". $tty->fileno()) || die "Couldn't reopen ". $name_of_tty ." for writing, $!\r\n";
    close STDERR; # put that here or we would never see those die's above...
    open(STDERR,">&". $tty->fileno()) || die "Couldn't redirect STDERR, $!\r\n";
    exec(@$cmd) || warn "Cannot do it: $!\n";

#  -*- kill myself becouse DIE dosn't work well ,-( -*- # 
    kill 'KILL',$$;
    waitpid ($$,0);
   }  # End Child.
 # -*- Parent -*- #  
    sleep 0;
   return $self;
 }


1;