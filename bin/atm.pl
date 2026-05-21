#!/usr/local/bin/perl
$^W=1;
$|=1;
use less;
use strict;
use POSIX;
use Event;
use Event::Watcher qw(R W E);
use Socket;
use Data::Dumper;
use IO::Handle;

# Name of servers MAP for name constant  
use constant rtserver => 'rtserver' ;
use constant rtserver2=> 'rtserver2';
use constant e450     => 'e450'     ;

use constant hp       => 'hp'       ;

use constant aix      => 'aix'      ;

use constant dec      => 'dec'      ;
use constant dec4     => 'dec4'     ;
use constant dec5     => 'dec5'     ;

use constant itanium  => 'itanium'  ;
use constant itanium2 => 'itanium2' ;

use constant qnx      => 'qnx'      ;


# Global varables declears #

use vars qw( 
    &rsh
    $expect
    $process 
    $DEBUG
    $verbose
    @mail
    @SERVER_LIST
    @ENV_LIST
    @TEST_LIST
    @PRE_TASK
    @POST_TASK
    $RETURN_CODE
    $atc_env
    $atc_cmd
);

$DEBUG = 1;
#  Global HASH for accumulate information about progress in processing
$process = {};
$expect  = 'SHELL_READY';    #This is special prompt from shell (sh,bash e.c.t) this is signal

my $return_code = ' $?';     # RETURN code after each command   

$RETURN_CODE = 0;            # Varable contein RETURN CODE
$verbose =  0;               # rsh/rlogin READY for take next command for execution
@mail    = ();

######################
@PRE_TASK  = ();
@POST_TASK = ();
$atc_cmd   = 'atc.pl  -q -v 2 -atm';

## Handle PIPE by Event subsystem not die if some PIPE broke
$SIG{PIPE} = 'IGNORE';

 
 
my $exit   = 0;
my ($atTime) = (0,0);

my $servers= undef;   # 
my @servers= ();
my $mail   = undef;   # mail address for report of test
my $fName  = undef;   # fileName for report of test
my $command= undef;   # Command mode for atm
my @rep    = ();      # Report Accumulators  

 

use Getopt::Long qw( GetOptions );  GetOptions(
    "at:s"           =>  \$atTime,   # at Time to start process
    "d|debug:i"      =>  \$DEBUG,    # DEBUG mode        
    "v|verbose:s"    =>  \$verbose,  # Verbouse  mode 1/2/3
    "m|mail:s"       =>  \$mail,     # Mail address;
    "o|output:s"     =>  \$fName,    # File Name for reportting
    "c|command"      =>  \$command,  # Command mode for STDIN
    "s|server:s"     =>  \$servers,  # ist of server for test 
)||die "
use: atm  [-at 00:25 ] [ -v [1,2,1+2,]] [-o filename] [ -m mail\@domain.com[,mail2\@domain.com]] atmscript
 -at          time for start 
 -v|verbose   1 - Common report 
              2 - Report progress multiplex out
 -m|mail      list of mail addres for report ( mode 1 only used )
 -c|command   Command mode for cancel/stop/continue etc command
 -s|servers   Servers for test by atc          
 -o|output    file name for reporting\n
";

die "Shold be parametr with script !\n"  unless (@ARGV);

@servers = split /[\s\t,]+/,$servers  if (defined $servers);
 
# Start COMAND PROCESSOR 
if (defined $command ){ 
    _startCommandProcessor();
  
}# end if

# Make MAIL LIST


@mail = split /,/,$mail if $mail;

if ($atTime =~/^(\d{1,2})\:(\d{1,2})\:?(\d{1,2})?$/ ){
    my $time  = time();    
    my ($sec,$min,$hour,undef,undef,undef,undef,undef) =  localtime($time);
    $time  = $time - $hour*3600 - $min*60 - $sec; # Take base Time
    $min  = $2||0;
    $hour = $1||0; 
    $sec  = $3||0;
    $atTime = $time + $hour*3600 +$min*60 + $sec ;
    $atTime += 86400 if ($atTime < time); 
}elsif ($atTime == 0 ){
        
    $atTime=time; 
}else{ 
    die "ERROR Wrong Time format $atTime  shold be 00:01!"; 
}    

# At any Case start by timer - but time your can set -at ......   
my $timer =  Event->timer( at => $atTime || time(),  cb => \&start); 

# Report TERM signal

$SIG{TERM} = sub {
    ts_KILL(); 
    ts_EXIT(1);
 };

$SIG{INT} = sub {
    ts_KILL();
    ts_EXIT(1);
 };

 
# ALARM Signal for wakeup by for timer
$SIG{ALRM} = sub {
    if ( $atTime > time ) {
        $timer->cancel();
        start();
        print "ALARM\n";
    }else{
        die "No AT Time now";
    }      
 };

Event::loop;
#print Dumper \$process;
report(@mail);
exit($exit);

##############################################################################################

# -* functon for execute on remote host script - set of command
sub rsh  {
	my ($host,$number, @script) = @_;
    my $shell_command = '' ;   # Contain current execute command      
  
    # STDIN/STDOUT sock pair
    my $c =  new IO::Handle;   # STDIN/STDOUT sock pair
    my $p =  new IO::Handle;
    socketpair($c,$p, AF_UNIX, SOCK_STREAM, PF_UNSPEC); 
    $p->autoflush(1);

    # STDERROR sock pair
    #  my $c_err =  new IO::Handle;
    #  my $p_err =  new IO::Handle;
    #  socketpair($c_err,$p_err, AF_UNIX, SOCK_STREAM, PF_UNSPEC);
    #  $c_err->autoflush(1);

    my $pid = fork;
	my $host_alias = $host . "_$number";
    $process->{$host_alias}{ pid} = $pid;

########### Child process ##########
    unless ($pid){ #  children process
        $p->close();
        $c->autoflush(1);
        #$p_err->close();
        close STDIN;
        close STDOUT; 
        close STDERR;
        open(STDIN, "<&" . $c->fileno())      
            || die "Couldn't reopen socks for reading, $!\r\n";
        open(STDOUT,">&" . $c->fileno())      
            || die "Couldn't reopen socks for writing, $!\r\n";
        open(STDERR,">&" . $c->fileno())      
            || die "Couldn't redirect STDERR, $!\r\n";
        my $rc = exec("rsh",$host);
		print ">>> return code = $rc\n";
        waitpid $pid,0;
    };
####################################

    $c->close();
    #$c_err->close();
    $process->{$host_alias}{sock}=$p;
 

    #  Set ready counter/semaphore 
    my $ready = 0;  
    my $data  ='';
    my $buffer='';  
 
  
  
    #my $out =   
    $process->{$host_alias}{e_R} = 
        Event->io(
            desc => "$host_alias r_out",
            poll => 'r',
            fd => $p,
            cb => sub {
            my $w=$_[0]->w;
            my $fd = $w->fd;
            my $tmp_buf='';
            my $got = sysread $w->fd,$tmp_buf,POSIX::BUFSIZ ;
            $_ = $tmp_buf;
			#print ">>>>$got<$tmp_buf<<<####\n";
            if (!$got || $!) {       # -* Some exception *- # 
                print  $host_alias.'|E|'. "ERROR PIPE unexpected broke on $host!\n";     
                $w->cancel;
                _kill($host_alias); 
                delete $process->{$host_alias};
                return;
            }
            if (/$expect\s*(\d+)?$/) {
                $RETURN_CODE= $1;
                if (  $RETURN_CODE )    {
                    my $err = "ERROR $host take retval $RETURN_CODE in cmd:" . $shell_command;
                    push @{ $process->{$host_alias}{sFAIL}},$err; 
                    print  $host_alias.'|E|'.$err;
                    ts_KILL($host_alias);
                }
                if (/[\n\r]/) {
                    ++$ready;
					#print $host_alias,"|X|$_ ::: $ready\n"; 
					$buffer='';
					$data='';
                }
				#return;
            }#end if
            
            #print "1$host====> $buffer<===\n";
            $buffer.=$_;         
            if (!/[\n\r]/) {
                return;
            }
			#print "2$host====> $buffer<===\n";
            while ($buffer =~s/^(.*)[\n\r]+//){
				$_ = ($1) ? $1 : next;      
                # -* Tast Case Filter * - # 
                
                # |0| Output Test Case result
				#if (/[\s\t]+(TC\d+){1}(.*)?$/ ){                     
                if (/^[\s\t]*#/ ){                     
					#$data = $1 . $2 . "\n" ;
					$data = $_ . "\n" ;
                    print $host_alias,"|O|",$data             if $verbose & 2;
                    if ($data =~ /PASS/ ){
                        ++$process->{$host_alias}{PASS};
                    }elsif ($data =~ /FAIL/ )   {
                        ++$process->{$host_alias}{FAIL};
                        push @{ $process->{$host_alias}{sFAIL} },$data; 
                    }elsif ($data =~ /SKIP/ ) { 
                        ++$process->{$host_alias}{SKIP};
                    }    
                }
                # |T| Test Suite detection
				#elsif (/^\s(\S+.ts)\s+#\s*(.*)?$/){                    
			    elsif (/^\[X\]/)
				{
					s/^\[X\]//;
					print $host_alias,"|X|",$_."\n";
				}
                elsif (/^[\s\t]*\+/){                    
					#$data = $1;
                    $data = $_;
                    $data.= (defined $2) ? '#'.$2 : "";
                    print $host_alias,"|T|",$data."\n" if $verbose & 2;
                }
                elsif (/^ioctl/ or /^tcgetattr/ or /^Last login:/ or /SHELL_READY/) {
                    #do nothing
                }
                elsif (/^[\s\t]*-/){       #TL             
                    print $host_alias,"|O|",$_."\n"            if $verbose & 2;
				}
                elsif (/^[\s\t]*X/){                    
                    print $host_alias,"|O|",$_."\n"            if $verbose & 2;
				}
                elsif (/^[\s\t]*ATC TEST/){                    
                    print $host_alias,"|L|",$_."\n"            if $verbose & 2;
					if (s/^[\s\t]*ATC TEST REPORT//){    #START
						s/[\s\t]*\[//;                   #eliminate "["
						s/\][\s\t]*//;                   #eliminate "]"
						my @cnt_list = split /,/, $_;    #cnt_list[2] : tc total info
						$cnt_list[0] =~ s/.*:[\t\s]*//;
						$cnt_list[1] =~ s/.*:[\t\s]*//;
						$cnt_list[2] =~ s/.*:[\t\s]*//;
						print $host_alias, "|L|COUNT=$cnt_list[0]:$cnt_list[1]:$cnt_list[2]\n";
					}
				}
                elsif (($verbose & 4 ) and !/\r\s+\r?|\r?\s+\r/ ){
                    s/\r//g;        
                    print $host_alias,'|L|',$_."\n" if !/^\s+$/;
                }
				else {
					print $host_alias,"|L|",$_."\n";
				}
            }#end while
            #print $host_alias,'|A|',$buffer."********************\n";
        }); 


    # Synchronize write to remoute host 
    $process->{$host_alias}{e_V} = 
        Event->var(
            desc => '$host_alias write_shell',
            poll => 'w',
            var  =>  \$ready,
            cb   =>  sub {
                unless (@script){
                    print "$host_alias|O|PROCESSING FINISH\n"      if $verbose & 2;
                    _kill($host_alias);
                }else{
                    $shell_command = shift(@script);
					$shell_command .= "      " unless ($shell_command);
                    $shell_command .= "\n";
                    print "$host_alias|C|> $shell_command"           if $verbose & 2; 
                    my $rv   =  syswrite $p,$shell_command,length($shell_command);
                }
            }
        );

}#end of remoute

###############################################################################

sub start {
    # -* EVAL test script file for execution plan *- #
no strict;
    for my $perl_script (@ARGV){
        # if  PATH not absolute USE  ATC_HOME enviroument     
        $perl_script = $ENV{ATC_HOME}.'/conf/'.$perl_script 
                                    unless ($perl_script =~ /^\// );
        eval{
            do   $perl_script;
            sethosts();
            foreach (@TEST_LIST)
			{ 
				$atc_cmd.= ' '.$_;
			}; 
            for (my $i = 0 ; $i <= $#SERVER_LIST ; $i++)
			{ 
		        my ($t_server_name, @t_server_env) = @{@SERVER_LIST[$i]};
				my $t_home_env ='';
				if (defined @t_server_env)
				{
				    foreach (@t_server_env)
				    {
					    $t_home_env .= $_;
				    }
				}
				print ">>> $t_server_name :: " . $t_home_env . $atc_cmd . "\n";
				rsh ($t_server_name,$i, $t_home_env, @PRE_TASK,$atc_cmd,@POST_TASK)
			};
        };
        die "ERROR on script:$perl_script >>>> $@ $! $?\n" if ($@ );
    };#end for 
use strict;
    #while ( not $fd->opened() ) {sleep 1};
    sleep 1;
    foreach my $key (keys %{$process} ){
        my $fd = $process->{$key}{sock};
        # Set special prompt determinator 
        $fd->print("export PS1=\'$expect $return_code\'\n"); 
    }
    
} # end start 


sub report {
    my @user_to = @_ ;
    @rep;
    push @rep,"\n================= TEST CASE on HOSTS =====================\n";
    foreach my $key (keys %{$process} ){
        my $pass = $process->{$key}{PASS}||0;
        my $skip = $process->{$key}{SKIP}||0;
        my $fail = $process->{$key}{FAIL}||0;
        push @rep,     
            sprintf "%20s pass:%3d fail:%3d skip:%3d totall:%3d\n",
            $key,$pass,$fail,$skip,+($pass + $fail + $skip);
    }
    push @rep, "==========================================================\n\n";

    # -*   Detail FAIL list by HOSTs   *- #
    foreach my $host (keys %{$process}){  
        if (defined $process->{$host}{sFAIL} ){
            push @rep,"$host FAIL Tast Case list:\n";   
            push(@rep, @{  $process->{$host}{sFAIL}  });   
        }   
    }
    # -* End  Detail FAIL list by HOSTs *- #

    # -*  Send Mail by list  *- #
    if (@user_to){
        use Net::SMTP;
        my $smtp = Net::SMTP->new('mail', Timeout => 60);  
        $smtp->mail('alex@altibase.com');
        foreach (@user_to){$smtp->to($_)};
        $smtp->data();
        $smtp->datasend("Subject: Altibase Test Monitor\n");
        $smtp->datasend(@rep);
        $smtp->dataend();
        $smtp->quit;
    }#end if mail
  
    if ($verbose & 1){
        print @rep; 
    }
} 

sub _timeout_cb {
    my $host = shift;

}    

sub sethosts {
    @SERVER_LIST =  @servers if (@servers);
    my $str= ' |_|SERVERS LIST:'; 

	my $i = 0;
    for ($i = 0 ; $i < $#SERVER_LIST ; $i++){
		my $t_server_name = $SERVER_LIST[$i][0];
        $str.= $t_server_name . "_$i";
        $str.= ',' ;    
    }
	my $t_server_name = $SERVER_LIST[$i][0];
    $str.= $t_server_name . "_$i";
    print $str . "\n";
}
 
sub _kill {
    my $host = shift;
    my $pid  = delete $process->{$host}{ pid};
    my $sock = delete $process->{$host}{sock};
    my $ev   = delete $process->{$host}{e_R};    
    $ev->cancel;   
    $ev   = delete $process->{$host}{e_V};   
    $ev->cancel;
    $sock->printflush("exit\n");          # Try exit by normal
    $sock->close if $sock->opened;
    waitpid($pid,0);
}

sub _timeoutCB {
}

sub _startCommandProcessor () {
    my @_par ;
    Event->io(
        desc => "ATM Command processor",
        poll => 'r',
        fd => \*STDIN,
        cb => sub {
            my $w=$_[0]->w;
            my $got = sysread $w->fd,$_,POSIX::BUFSIZ ;

            if (!$got || $!){       # -* Some exception *- #
                print STDERR "ERROR PIPE unexpected broke \n";
                $w->cancel;
                Event::unloop; 
                return;
            }# end if check error
            chomp;  
            @_par = split /[\t\s\,]+/,$_;

            my  $cmd  = uc(shift @_par) || '';

            no  strict 'refs';
            if ($cmd &&   defined(*{'main::ts_'.$cmd}{CODE}) ){
                my $par = '';
                map {$par.= "\'". $_ . "\'" . ',' } @_par;
                eval 'ts_'.$cmd. '('. $par . ');' ;
            }else{ 
                print STDERR  "No such command $cmd;\n"
            };
            use strict; 
        }
    );    
}
 
sub ts_KILL {
    foreach my $key (@_) {
        _kill($key);
    }     
}

sub ts_DUMP { 
    print Dumper $process;
}

sub ts_PS {
         
}

sub ts_EXIT {
    Event::unloop;
    $exit = shift ||0;
}

