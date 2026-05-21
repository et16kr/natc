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
  
    my $parent = new IO::Handle;

    my $iaddr = gethostbyname('localhost');
    my $proto = getprotobyname('tcp');
    my $paddr = sockaddr_in(8888, $iaddr);
    my($host);


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
        kill 'KILL',$$;
        shutdown($parent,2);
        waitpid ($$,0);
    };  


    accept ($parent, $parent) || die "accept parent: $!";

=tcut
my $data = "select * from t1; \n";
my $blksize = length($data);
my $rv   = syswrite($parent,$data,$blksize);

$data = '';
STDOUT->flush();
$rv   = sysread($parent,$data,1024);
print ">>> Response is : $data\n";
STDOUT->flush();

$data = "select * from t2; \n";
$blksize = length($data);
$rv   = syswrite($parent,$data,$blksize);

$data = '';
STDOUT->flush();
$rv   = sysread($parent,$data,1024);
print ">>> Response is : $data\n";
STDOUT->flush();


print ">>>> FLUSH BEFORE <<<<\n";   
    $parent->autoflush(1);
    
print ">>>> OPEN BEFORE <<<<\n";        

    STDIN->autoflush(1);
    STDOUT->autoflush(1);
    STDERR->autoflush(1);    
=cut
    return $parent;
}

1;
