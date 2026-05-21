#!/usr/local/bin/perl
use strict;
use less;

use POSIX   qw( BUFSIZ EWOULDBLOCK);
use Fcntl   qw( F_SETFL F_GETFL O_NONBLOCK);


use Event ;
use Event::Watcher qw(R W);
use Symbol;

use Data::Dumper;

use Socket;
use IO::Handle;



my $noticed_bogus_fd=0;
my $bogus_timeout=0;


# jast unix socet 15600 per second in linux
     my $c =  new IO::Handle;
	 my $p =  new IO::Handle;
     socketpair($c,$p, AF_UNIX, SOCK_STREAM, PF_UNSPEC);
        $c->autoflush(1);
	    $p->autoflush(1);

 my $pid = fork;

 unless ($pid){ #  children process
        $p->close();   
          
     #########rsh####################

  # -*- Close all descriptor -*-
  close STDIN;
  close STDOUT;
  print STDERR "$$ child pid\n";
  open(STDIN, "<&" . $c->fileno())  || die "Couldn't reopen socks for reading, $!\r\n";
  open(STDOUT,">&" . $c->fileno())  || die "Couldn't reopen socks for writing, $!\r\n";
  if ($ARGV[0] !~ /l/ )
  {
  exec("rsh rtserver tisql -s 192.168.1.11 -u sys -p MANAGER ");
  }
  else
  {
  exec("tisql -s 192.168.1.11 -u sys -p MANAGER ");
  }
  #exec("rsh localhost ");
# #  while (<STDIN>)
# #  {
# #	 print STDOUT  $_;   
# #  }	   
  exit;
 };
       $c->close();
my $t_int =  $ARGV[1] || 1;
my $timer =  Event->timer(
	 parked  => 1, 
     interval=> $t_int, 
     cb=>sub  {
		 Event::unloop();
	 }
   );



my $cntw = 0;
my $cntr = 0;
my $ready = 0;

new_pipe(\$cntr,\$cntw,\$ready,$p);
$timer->start();
Event::loop();

print STDERR  "ready>$ready write>$cntw>",int( ($cntr+$cntw)/$t_int )," per second > $cntr<reads\n";
exit(0);



sub new_pipe {
    my ($cntr,$cntw,$ready,$p,$c) = @_;
	
# jast PIPE 28825 per second in linux	
#    my ($p,$c) = (gensym, gensym);
#    pipe($p,$c);

	 
    Event->io(
        desc => "r", 
        poll => 'r', 
        fd => $p, 
        cb => sub {
		  my $e = shift;
		  my $w=$e->w;
		  if ($e->got & R) {
		      my $buf;
		      my $got = sysread $w->fd, $buf,POSIX::BUFSIZ ;
#print STDERR $w->cbtime,"\t>$buf<";
# print STDERR ">$buf<"; 
		      die "sysread: $!"
			  if !defined $got;
		      die "sysread: pipe closed?"
			  if $got == 0;
			  ++$$cntr;
			   ++$$ready if  $buf =~ /iSQL> /;
			  #++$$ready if $buf =~/\$/;
		  }
	      });

    Event->
	      var(
	#	  io (
          desc => 'w',
          poll => 'w', 
	#     fd => $c,
	      var  => $ready,
          cb => sub {
		  my $e = shift;
		  my $w=$e->w;
		  if ($e->got & W) {
			  #my $got = syswrite $p, "insert into foo values($$cntw);\n",POSIX::BUFSIZ;
			  my $got = syswrite $p, "select * from zipcode;\n",POSIX::BUFSIZ;
			  # my $got = syswrite $p,"echo $$cntw\n";
			  #  print STDERR "insert into foo values($$cntw);\n"; 
		      die "syswrite: $!"     	  if !defined $got;
		      die "syswrite: pipe closed?"  if $got == 0;
			   ++$$cntw;
		  }
	      });
}
