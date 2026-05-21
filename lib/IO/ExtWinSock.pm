package IO::ExtWinSock;
use strict;
use Exporter;
use Socket;
use IO::Handle;

use vars  qw(@ISA @EXPORT);

@ISA = qw ( Exporter); 
@EXPORT= qw();

sub new 
{
    my $class = shift;
    my $cmd   = \@_;
    my $port;
    $port = $main::win_port;
  
    my $parent = new IO::Handle;

    my $iaddr = gethostbyname('localhost');
    my $proto = getprotobyname('tcp');
    my $paddr = sockaddr_in($main::win_port, $iaddr);
    my($host);

    $main::win_port += 1;
use isql;
    if ($main::win_port > 60000)
    {
       $main::win_port = $main::cfg->{PORT_NO}+10001;
    }

    socket($parent, PF_INET, SOCK_STREAM, $proto) 
        || die "socket parent: $!";
    setsockopt($parent, SOL_SOCKET, SO_REUSEADDR, pack("l", 1)) 
        || die "setsockopt: $!";
    bind($parent, $paddr) || die "bind   parent: $!";
    listen($parent, 1) || die "bind   listen: $!";

    ${*$parent}{pid} = fork;
    my $pid=${*$parent}{pid};

    unless (defined ($pid)) 
    {
        warn "Cannot fork: $!";
        return undef
    }

    unless ($pid)
    {
        exec(@$cmd) || warn "Cannot do it: $!\n";
        print "Cannot Get PID \n";
        kill 'KILL',$$;
        shutdown($parent,2);
        waitpid ($$,0);
    };  

    accept ($parent, $parent) || die "accept parent: $!";
    return $parent;
}

1;
