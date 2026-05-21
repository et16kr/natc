#!/usr/local/bin/perl

package main;

$^W=1;
# -*- Find module in local library -*- #

use lib $ENV{ATC_HOME} . '/lib' ;

# load modules
use strict;
use IO::File;
use IO::Tee;
use Cwd;
=remove because not used
use IO::ExtSock;
=cut

use Event;

use ExecSQL;
use TestPlan;
use Context;
use TSmap;

# -* clean output Directory
#eval   
#{
#	system('rm -rf '.$ENV{ATC_HOME}.'/DF/*.out');
#   system('rm -rf '.$ENV{ATC_HOME}.'/DF/TDX/*');
#   mkdir  $ENV{ATC_HOME}.'/DF/'    unless ( -d $ENV{ATC_HOME}.'/DF/'    );
#   mkdir  $ENV{ATC_HOME}.'/DF/TDX' unless ( -d $ENV{ATC_HOME}.'/DF/TDX' );
#};

# -* Global varable Test Frame  Control *- #
 
use vars qw(    $IN $OUT $ERR 
		        $LOG
                $REP $EXCEPTION
		        $NULL 
		        $DIS 
		        $DBG
	            $DEBUG $A    $Expect $TC_ERRORS $VERSION
	            $tsh   $cfg  $ex     $tb  $tp   $Elapse	$tsmap
	            $LST   $Lst_Suffix
                $DIFF  $Out_Suffix
                $TCASE $TCASE_Suffix
                $ager_sock
                $server_tmpl $client_tmpl
                $server_list $client_list
                $win_port
	        );
	    
$win_port = 0;
## See Debug info ##
$DEBUG    =0;
$TC_ERRORS=0;
$Elapse   =0;

#!open(NULL,'>>/dev/null');
#!$NULL   = \*NULL;



# -* Get configure file *- #
use CfgRead2 qw( new );  
$cfg = CfgRead2->new();

$tsmap = new TSmap;
 

# -* Set comon Global Vars
*LST  			= \$cfg->{DirLst};  
*Lst_Suffix  	= \$cfg->{Lst_Suffix}; 
*OUT 			= \$cfg->{Diff};    
*Out_Suffix	    = \$cfg->{Diff_Suffix};
#*DIFF 			= \$cfg->{Diff};    
#*Diff_Suffix	= \$cfg->{Diff_Suffix};
*TCASE 			= \$cfg->{TCASE};   
*TCASE_Suffix 	= \$cfg->{TCASE_Suffix};
###########
no  CfgRead2;



$NULL = new IO::File('/dev/null','w');

$IN	= \*STDIN; 
$IN = bless($IN,'IO::File');
$IN->blocking(1);
$IN->autoflush(1);

$OUT = \*STDOUT;
$OUT = bless($OUT,'IO::File');
$OUT->blocking(1);
$OUT->autoflush(1);

# ERROR tee chanal

$ERR = new IO::File($cfg->{ERROR_log_file},'w');
unless ($ERR)   { 
    $ERR  = \*STDERR;	
	$ERR->blocking(1);
	$ERR->autoflush(1);
    print $ERR  "WARN:I can't open log \""
        .$cfg->{SYSTEM_log_file}."\" File for SYSTEM command\n";
};

$ERR = new IO::Tee ($ERR,\*STDERR);
$LOG = new IO::File($cfg->{SYSTEM_log_file},'w');
unless ($LOG)   {
	print $ERR  "WARN:I can't open log \""
        .$cfg->{SYSTEM_log_file}
        ."\"File for SYSTEM command\n";
};
			 

$REP = new IO::File($cfg->{REPORT_log_file},'w');
unless ($REP)   {
    print $ERR  "WARN:I can't open log \""
        .$cfg->{REPORT_log_file}
        ."\"File for REPORT\n";
}; 

$EXCEPTION = new IO::File($cfg->{EXCEPTION_log_file},'w');
unless ($EXCEPTION)   {
    print $ERR  "WARN:I can't open log \""
        .$cfg->{EXCEPTION_log_file}
        ."\"File for EXCEPTION\n";
}; 

#$REP    = new IO::Tee ($REP,$OUT);
$DBG    = $OUT;
$DIS    = $OUT;

$EXCEPTION->autoflush(1);
$REP->autoflush(1);
$DIS->autoflush(1);
$DBG->autoflush(1);

#### Part for load plugins ######

my $current_work_dir = cwd;
do 
 {
  my $dir = $ENV{ATC_HOME}.$cfg->{PLUGIN_DIR};
     opendir D, $dir or warn "Cannot open $dir: $!" and last;
  my @plugins=grep {(/^\w+.pl$/) && -x "$dir/$_"}   readdir D;
     closedir D;
  foreach my $plugin (sort @plugins)
   {
	$plugin = $dir.$plugin;   
    do $plugin;
   }
 };
chdir $current_work_dir;


# -* Start TestFrameWork Shell *- #
$tsh = &init_test_shell()  if $cfg->{'Shell'};

# -* Use Dumper if in Shell and DEBUG *- #
eval 'use Data::Dumper' if defined ($tsh);


######################################
# Read atc.server.ctx
######################################
use Context qw(readContext);
$server_tmpl = Context->readContext($cfg->{SERVER_CTX});
#$client_tmpl = Context->readContext($cfg->{CLIENT_CTX});
no Context;

if ( defined $cfg->{DB_SERVER} )
{
    $server_tmpl->{DEFAULT}->{HOST_IP}          = $cfg->{DB_SERVER};
    $server_tmpl->{DEFAULT}->{ALTIBASE_PORT_NO} = $cfg->{PORT_NO};
}

$client_tmpl->{DEFAULT}->{HOST_IP}  = '127.0.0.1';
$client_tmpl->{DEFAULT}->{SERVER}   = 'DEFAULT';
$client_tmpl->{DEFAULT}->{DB_USER}  = 'SYS';
$client_tmpl->{DEFAULT}->{DB_PASSWD}= 'MANAGER';
$client_tmpl->{DEFAULT}->{OPTIONS}  = '-silent';
$client_tmpl->{DEFAULT}->{DRIVER}   = 'isql';
$client_tmpl->{DEFAULT}->{PORT_NO}  = $cfg->{PORT_NO};

#use Data::Dumper;
#print Dumper $server_tmpl;
#print Dumper $client_tmpl;
#no Data::Dumper;



######################################
# Put from ARGV all TestCase 
######################################
$tp = new TestPlan;
if ($cfg->{plan_only} > 0)
{
    &_exit(0);
}

######################################
# Test Builder Initialize 
######################################
use RepTL;
$tb = RepTL->new (
	DirLst 		=> $cfg->{DirLst},
    Lst_Suffix	=> $cfg->{Lst_Suffix},
	#DIFF		=> $cfg->{Diff},
	#Diff_Suffix => $cfg->{Diff_Suffix},
    OUT		    => $cfg->{Diff},
    Out_Suffix  => $cfg->{Diff_Suffix},
	Verbose 	=> $cfg->{Verbose},
);

# -* set filure output File Handle *-  #
$tb->failure_output($NULL);
# -* Output result to $REP File Handler *-#

# Set report Output	 
$tb->output ($REP);

# Set report Display
$tb->display($DIS);

# Start a tisql for ager control
my $tisql_cmd;

=remove because not used
#### for tisql connection to the specified server ####
$_ = $cfg->{iSQL};
s/isql/tisql/ ;

$ager_sock = new IO::ExtSock( $_ )  || do 
        {
		  #print $main::ERR "I cant start process @_\n" ;
		  print "I cant start process @_\n" ;
		  return undef;
		};
my $my_buf = "";

if ($ager_sock)
{
    $ager_sock->printflush("set ager=disable;\n") ;
    #sysread($ager_sock, $my_buf, 1024);
    #print $ERR "$my_buf\n";
}
=cut

$tp->report_TEST_ALL;
$tp->report_TSERROR_open;

# Start Test Cases
    $ex = new ExecSQL;
    # -*- do test case -*- #
    $ex->run_tc;

Event::loop();

$tp->report_TSERROR_close;

&_exit($TC_ERRORS);

########## Some Additional ##############
#					#
#######################################################################################


sub init_test_shell 
 {
 package main;
 use vars qw ($AUTOLOAD);
 require TFSh;
    my $tsh=new TFSh (
    	HistSize    => 100,		      # History Size 256 by default
    	HistFile    => $ENV{ATC_HOME}.'conf/.perlsh_history',# History File
    	Strict      => 0,                 # No Strict Access to All varables
    	InputStream => $IN ,		      # Input stream 
        OutputStream=> $OUT,		      # Output Stream
    	ErrorStream =>$ERR,
    	PerlRC      => $ENV{ATC_HOME}.'conf/.perlshrc',       # Resurce file Start and do after Load Module !!
        # Your Cane Overload any Parametr from thea   !!
     );

## -*- Find any function not from package in shell  -*- ## 
## -*- Now your can start any program like function -*- ##

    sub AUTOLOAD 
    {
        my 	$program = $AUTOLOAD;
        $program =~ s/.*:://;  # trim package name
        my 	$pid = system($program, @_);
    } 

    # -*- Do some RC file
    if ( -f 'rc/.perlshrc') 
    {
        do "conf/.perlshrc"; print $ERR $@ 
    };
    return $tsh
}# -*- END INIT SUB -*- #

# -* Set AUTOFLASH for file HANDLE *- #
sub autoflush {my ($fh) = shift; my $save = select $fh; $|=1; select $save };


sub ping_db
{
    my ($host,$port) = split /[:]/,$_[0],2;
    my $sock = new IO::Socket::INET(PeerAddr    => $host,
                                    PeerPort    => $port,
                                    Proto   =>'tcp')
               || return 0 ;
 # -* Exactly check ALTIBASE port and protocol *- #      				
       $sock->printflush('IDC_INET_');
       $sock->sysread($_,9);
   return (/^IDC_READY/) ? 1 : 0;
};

sub _exit ($)
{ 
    my $e_code = shift || $TC_ERRORS || 0;
  
=remove because not used
    if ($ager_sock) {
        $ager_sock->printflush("set ager=enable;\n") ;
        #sysread($ager_sock, $my_buf, 2048);
        #print $ERR "$my_buf\n";

        $ager_sock->close;  
    }
=cut

    # -* if use Test Shell mode for debug call exit of TSH *- #
    if ( defined($tsh) )    {
        &TFSh::cmd_exit($e_code);  
    } else {
        $_->cancel for Event::all_watchers;
    }; 

   exit $e_code;
}

sub print_mess
{  
    my $mess =shift;
	 
};

sub clear_mess
{
}; 


