package IO::ExtSock;

use strict;
use Exporter;


use Socket;
use IO::Handle;
# We say AF_UNIX because although *_LOCAL is the
# POSIX 1003.1g form of the constant, many machines
# still don't have it.

#use POSIX qw( setsid);
#use Fcntl qw( F_SETFL F_GETFL O_NONBLOCK);

use vars  qw(@ISA @EXPORT);

@ISA = qw ( Exporter);
@EXPORT= qw();

sub new 
{
    my $class = shift;
    my $cmd   = \@_;
  
    # Create the Parent IO::Handle  which we will use to pass process info.
    my $parent  = new IO::Handle;
    my $child   = new IO::Handle;

    socketpair($parent,$child, AF_UNIX, SOCK_STREAM, PF_UNSPEC) or do  
        {
            warn "I cannot make sockpair:$!"; 
            return undef;
        };

    # This is defined here since the default is different for
    # initialized handles as opposed to spawned processes.
    ${*$parent}{pid} = fork;
    my $pid=${*$parent}{pid};

    unless (defined ($pid)) 
    {
        warn "Cannot fork: $!";
        return undef
    }

    unless ($pid)
    {
        #####################
        # Parent Process
        #####################

        # Create a new 'session', lose controlling terminal.
        # POSIX::setsid() || warn "Couldn't perform setsid. Strange behavior may result.\r\n Problem: $!\r\n";

        $parent->close;
        $child->blocking(1);

        # Close all descriptor
        close STDIN; 
        close STDOUT;

        open(STDIN, "<&" . $child->fileno())  
            || die "Couldn't reopen socks for reading, $!\r\n";

        open(STDOUT,">&" . $child->fileno())  
            || die "Couldn't reopen socks for writing, $!\r\n";

        close STDERR; # put that here or we would never see those die's above...

        open(STDERR,">&" . $child->fileno())  
            || die "Couldn't redirect STDERR, $!\r\n";

        $child->autoflush(1);

        #  -*- kill myself becouse DIE dosn't work well ,-( -*- # 
        #    $SIG{PIPE} = sub {
        #    kill 'KILL',$pid;
        #    waitpid ($pid,0);
        #    };
        #!system(@$cmd) || warn "Cannot do it: $!\n";
        #print ">>> $cmd->[0]\n";

        exec(@$cmd) || warn "Cannot do it: $!\n";

        #!wait;
        #  -*- kill myself becouse DIE dosn't work well ,-( -*- # 

        kill 'KILL',$$;
        waitpid ($$,0);

    };  # End Child.

    #####################
    # Parent Process
    #####################

    $child->close;

    #    sleep 0;
    $parent->autoflush(1);   

    return $parent;
}



1;
