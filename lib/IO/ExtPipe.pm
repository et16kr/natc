#!/usr/bin/perl -w -T
# -*- perl -*-

package IO::ExtPipe;


use strict;
use Exporter;

use POSIX qw( setsid);
use IO::Handle;
use Fcntl qw( F_SETFL F_GETFL O_NONBLOCK);
use vars  qw(@ISA @EXPORT);

@ISA = qw ( IO::Handle  Exporter);
@EXPORT= qw();

use Carp;

sub new
  {
    my $class = shift;
    my $cmd = shift;
    
    # Create the two pipes. # for parent to child

     my  $r_CP = new IO::Handle;
     my  $w_PC = new IO::Handle;
			      # for child  to parent	  
     my  $r_PC = new IO::Handle;
     my  $w_CP = new IO::Handle;
    # 
     pipe($r_PC,$w_PC);
     pipe($r_CP,$w_CP);

    # -*- Set   Autoflash  Mode -*- #
        $w_CP->autoflush(1);
	$r_CP->blocking (1);
	$w_PC->autoflush(1);
	$r_PC->blocking (1);

    # Fork once to get to the buffer process.

    my $self;
    $self->{pid}   = fork;
    $self->{r_sock}= $r_CP;
    $self->{w_sock}= $w_PC;
    
    my $pid = $self->{pid};

    unless (defined ($pid)) { warn "Cannot fork: $!"; return undef}

    if ($pid)			
      { # Parent.
	close($w_CP);
	close($r_PC);
	sleep 0;
	bless $self, $class;

   }else{ # Child pricess
    # Create a new 'session', lose controlling terminal.
    POSIX::setsid() || warn "Couldn't perform setsid. Strange behavior may result.\r\n Problem: $!\r\n";
    # -*- Close paret pipe -*- #
    close($w_PC);
    close($r_CP);
    # Make STDOUT same as $PC.
    open STDOUT, ">&" . $w_CP->fileno or die "dup failed: $!";

    # Make STDERR same as $PC.
    open STDERR, ">&" . $w_CP->fileno or die "dup failed: $!";

    # Make STDIN same as $PC.
    open STDIN, "<&" .  $r_PC->fileno or die "dup failed: $!";

    # Launch external command.
    exec $cmd, @_ or croak "exec: $cmd: $!";
                                              #   system  $cmd, @_ or croak "exec: $cmd: $!";
#  -*- kill myself becouse DIE dosn't work well ,-( -*- # 
    kill 'SIGTERM',$$;
    waitpid ($$,0);
   }  # End Child.

 # -*- Parent -*- #  
    sleep 0;
   return $self;

}

1;
