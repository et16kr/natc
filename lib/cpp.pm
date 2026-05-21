# -*- perl -w -*- #
package cpp;

$^W=1;
use strict;

use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);
use vars qw ($AUTOLOAD &close_process $exec_sql);
require Exporter;

eval {use Data::Dumper  } if $main::DEBUG;


@ISA 		= qw( Exporter );
@EXPORT 	= qw( );
@EXPORT_OK	= qw( $VERSION);



use Const qw ( QUEUE BLOCK WAIT);


use Event	qw( unloop);
use Time::HiRes qw(gettimeofday  tv_interval );

use IO::ExtTTY	qw( );
#use IO::ExtPIPE qw( );
#use IO::ExtSOCK qw();

use IO::Socket 	qw( AF_INET   SOMAXCONN
		    SOCK_STREAM AF_UNIX);

use POSIX  	qw( BUFSIZ EWOULDBLOCK);
use Fcntl	qw( F_SETFL F_GETFL O_NONBLOCK);


$VERSION = '0.01';

#use vars qw(@ErrLst  $termcap);


# Connect ID #
sub new  {
 my $class = shift;
 my $self = {
     Quiet  		=>  0,
     max_cb_tm  	=>  1,
     callback_cmd     	  => \&callback_cmd,
     callback_read_handle => \&callback_read_handle,
     callback_ready	  => \&callback_ready,
     ProgName => 'isql -s 127.0.0.1 -u sys -p MANAGER -silent',
     AutoDo   => int 1,
     Expect   => 'iSQL>\s$|^>\s$',
     pkg_call => caller(),  # Detect Name of pacage who is call !?
     ok_sector=> 1,
     STATE    => BLOCK+WAIT,
     _state   => 0,
     q_cmd    => 0,
     q_sct    => 1,
    @_,
  };

# -*-  Start new External process with /dev/pts/# IO (Some program wont that for example isql) -*- # 

 my $sock = new IO::ExtTTY($self->{ProgName})  || do { 
			print $main::ERR "I cant start process @_\n" if $main::DEBUG & 1; return undef;};
 my $pid  = ${*$sock}{pid};  
    $self->{sock}   = $sock;
   
# -*- Some Elapse Timer -*- #
$self->{TimeElapse} = 0 ;
$self->{TimeOP}	    =[gettimeofday()];
## -*- This Reader from Sockets -*- ##

 my $evr = Event->io( 
    	    pool => 'r', 		
    	    fd   => $sock,
    	    desc => "RP:$pid",
	    cb   => sub {
		    # -*- I take event and Elapse Time of Response -*- #	
#!                      $self->{TimeElapse}=tv_interval($self->{TimeOP});
			 my $sock = $_[0]->w->fd; # take the Sock handle
			 my $data = ''; 
#		    # -*- This two for clean call -*- #
 			my $rv   = sysread($sock,$data,POSIX::BUFSIZ);
			if (!$rv || $!){ close_process($self) };
			
		    &{$self->{callback_read_handle}}($self,$data); 
		 });

# -*-  Set sender to Client -*- ##

#    $self->{OUT}='';     ## Create output buffer if some thing put to -> tray out all

 my $evs = Event->var( 
	    pool   => 'w',
	    var	   => \$self->{STATE},
	    desc   => "WP:$pid",   # description;
	    repeat => 1,                         # keep alive after events;
	    cb     => sub { 
			# -*- detect vector of change state -*- 
			my $sem = $self->{_state} ^ $self->{STATE};
                	   $self->{_state} = $self->{STATE};

			# -* NoThing Change - I take only SIGNAL SYNCK            *- #
			# -* It's Happend when all finishid for global WAIT synck *- #
		return  $self->_do_synck unless ($sem);
			$self->_do_wait  if _is_wait ($sem);
			$self->_do_block if _is_block($sem);	
#  			# -*-   Change Queue state now   -*- #
			$self->_do_queue if _is_queue($sem);

		    # -*- save previose state of semaphore -*- # 

	});



    $self->{pid}  	= $pid;
    $self->{evs}  	= $evs;
    $self->{evr}    	= $evr;
    $self->{tty_name}  	= ${*$sock}{tty_name};   # Name of TTY device
 
 unless ($self->{Quiet}) { print  $main::LOG "$pid:Process  started...\n" };

 return bless $self,$class;
};


# -*-    test state   -*- #
sub  _is_block  { ($_[0]&BLOCK)? 1 : 0 };
sub  _is_wait   { ($_[0]&WAIT )? 1 : 0 };
sub  _is_queue  { ($_[0]&QUEUE)? 1 : 0 };

# -*- manipelate subs -*- #
sub  sw_block  {$_[0]->{STATE}^=BLOCK};
sub  sw_wait   {$_[0]->{STATE}^=WAIT };
sub  sw_queue  {$_[0]->{STATE}^=QUEUE};
sub  sw_synck  {$_[0]->{STATE}=$_[0]->{STATE}};



sub _do_synck ($) {
    my $self =shift;
    print $main::LOG "isql syn\n" if $main::DEBUG & 1;
  
}

sub _do_wait { 
    my $self = shift;
    if ( $main::DEBUG & 2) {
	    print $main::LOG  _is_wait($self->{STATE}) ? $_= "isql w+\n" : $_= "isql w-\n";
         };
};

sub do_next{$_[0]->_do_block(1)}

sub _do_block { 
    my $self =  shift;
    my $next =  shift;   

 print $main::LOG _is_block($self->{STATE})? "+":"- |$self->{'TimeElapse'}| \n" if ($main::DEBUG & 2) ;
 
if (
      ($self->{AutoDo} or $next ) 
      and ($self->{STATE} == 2 ) 
   )
  {
     $main::Elapse += $self->{'TimeElapse'}; 
     ++$self->{q_cmd}; 

 # Point for execute all '--+' statment
     while ( $self->{IN}[0]=~/^\--\+/)
        {  
	    # -* remove command from FIFO and set last_cmd (for Polish notation) *- #
	    $self->{last_cmd} = shift(@{$self->{IN}});
	    $self->_do_cmd($'); 
	    last unless defined $self->{IN}[0];
	};
 print $main::LOG "$self->{q_cmd}:$self->{IN}[0]"	if ($main::DEBUG & 4);
     $self->_send();
     
 }; 

# READY  
unless ($self->{STATE}) 
 {
### Make LST file - it not clean only prototype *- #
  if ( $main::cfg->{'LST'} )
   { # -* make lst
     $self->_lst_make_file ;
    }
    else
     {
      if (
          defined($self->{Sector_Key}) 
#	   and (
#	    $self->{Sector_Key}  == 0
#	    ) 
	  )
	  {
#	  $main::tb->ok_sector($self,$self->{Sector_Key}) if ( $self->{ok_sector}) 
	  $self->ts_SECTOR;
	  };
          $main::tb->report_TC if ($main::cfg->{Verbose} >= 2);
     }
 # -* Set unblock WAIT for PARENT (ExecSQL) *- #
     &{$self->{callback_ready}}($self);
 };# UNLESS READY
};

sub callback_ready {
    my $self= shift ;
    print $main::LOG "isql Queue of cmd iSQL empty I'am READY \n "
};


sub _send {
      my $self = shift;
      my $data = shift @{$self->{IN}};
      my $sem  = $self->{STATE};
      # -*- Filter Queue for internal command - return only command for pass to process -*- #

# ! $data=&{$self->{callback_filter}}($self,$data);

      # -*- sckip if nothing to send -*- #
       return undef  if (not defined($data) );

#  -* for Solaris OS *- #
  if ($^O eq 'solaris'){$_=$data;  chomp; push @{$self->{OUT}},$_};

      sw_block($self) unless _is_block($sem); # BLOCK when send
			    my $blksize = length($data);  
                            my $sock = $self->{sock};
	              	    my $rv   = syswrite($sock,$data,$blksize); 
     # -*- I push Data to Process and mark time ! -*- #
     $self->{TimeOP}=[gettimeofday()];
             unless (defined $rv) {print $main::ERR "I was told I could write, but I can't.\n"};
             &close_process($self) unless ( $rv == $blksize ||  $! == POSIX::EWOULDBLOCK );
  sw_queue($self) if ( $#{$self->{IN}}+1 xor _is_queue($self->{STATE}) );

}

sub _do_queue { 
 my $self = shift;
 if ($main::DEBUG){
	print $main::LOG ( _is_queue($self->{STATE})) ? "isql q+\n":"isql q-\n" ;
  }
};


# -*- Handle subroutine input stream from process -*- #

sub callback_read_handle ($$){
    my $self   = shift; 
    local ($_) = shift;
#    print "|$_|";

## Control point for do next command from queue ##

#  Very difficult code !!! isql utilite is craze !!!  it can make any sequence of output 

#  -*-  Send Event for Execute SQL STATMENT  -*- #		
  if (s/$self->{Expect}//){   
                      $self->{TimeElapse}=tv_interval($self->{TimeOP}); 
		      # -*- Loop back post Event decriment  -*- #
		      sw_block($self) if  _is_block($self->{STATE}); # switch trigger State to UNBLOCK
  $_ = delete($self->{BufferIN}).$_;
  return unless $_;
#  chomp; 
  # -* remove iSQL prompt prefix 
  s/\r//g;
  my @_data = split /[\r\n]/,$_;
#?  $_ = '';
  while ($_ = shift @_data){push @{$self->{OUT}},$_ if $_};
  } # END IF 'Then'  EXPECT
   else {
    $self->{BufferIN}.=$_;
   }; 
};

#sub DESTROY {close_process(shift);};

sub close_process {  
    my $self = shift;
    my $pid  = $self->{pid};
# --*-- Stop control Watcher --*-- #
        $self->{evs}->cancel if $self->{evs};
       $self->{evr}->cancel if $self->{evr};
# --*--       Some Info       --*--#
   unless ($self->{Quiet}) {print  $main::LOG "I tray kill process $pid ...\n"  };
  
# -*- Hm I can't Do my work becouse Cant connect to ALTIBASE -*- ##
   if ( $self->{BufferIN}=~/^\[ERR-00000*/){   
	 print $main::ERR $self->{BufferIN} . "\n";
	 $_->cancel foreach  Event::all_watchers; 
#         exit $main::TC_ERRORS;
      }
## -*- Close socket and Shutdown 2 too :-)) -*- ##

  kill 'TERM',$pid;
  sleep 0;
  waitpid($self->{pid},0);
    close($self->{sock}) if ($self->{sock});
  undef $self; 
}


################################################################################
# Filter Handler for separate command from SQL statmant #
# -*- by default it do nothing and return back stmt     #

sub get ($) {
   my $self = shift;
 if (wantarray){ my @ret;
    	    while ( $_=shift @{$self->{OUT}}) { push @ret,$_};
             return @ret;
      }else{ $_= shift @{$self->{OUT}}; return $_ };
};


# -*- Print to STDOUT isql output -*- #

sub Print ($$) {
 my     $self = shift;
 my     $fd   = shift ||\*STDOUT;
    while ($_= $self->get) {print $fd $_."\n"};               
}

#
sub do_stmt ($$) {
   my $self = shift;
      $_    = shift;
   push @{$self->{IN}},$_;
   my $q_len  = $#{$self->{IN}}+1; 
 if ( $q_len ){
    # -*- initialize q_cmd and generate Event for execute -*- #
      $self->{q_cmd} = $q_len   if ($self->{AutoDo}     );
    # -*- set off flag queue  -*- #
      $self->{STATE} |= QUEUE  unless ($self->{STATE}&QUEUE);    
     };
#

}

################################
# -*- Some useful function -*- #
################################

# -*- length of queue statment -*- #
sub q_len ($) {
 my $self = shift;
 # -*- Attention I don't know why but scalar dosn't work well -*- #
 return  $#{$self->{IN}}+1;
}

# -* This function start execute script from buffer *- #
sub start {
    my $self = shift;
    
# -* old finish   push @{$self->{IN}},"--+SECTOR  0;\n"; 

     $self->{Sector_Key} = 0; # Firs sector all 
    
# -* Clear OUTPUT BUFFER;
      delete $self->{OUT};
      
     $main::tb->plan( tests => $self->{q_sct},$self->{TestCase}) if (not $main::cfg->{LST}) ;
     $self->sw_queue ;
  $self->sw_wait if ( _is_wait($self->{STATE}));
 $self->do_next;
# -* Reset for next execution *- #
 $self->{q_sct} = 1;
}


# -*-       Set Auto execute mode for isql stmt            -*- #
sub do_auto ($$) {
 my $self = shift;
 my $mode = int shift;
    $self->{AutoDo}= $mode ? int 1 : int 0; 
#    sw_next($self) if $mode > 1;
}


#


sub callback_cmd  {
    my $self = shift;
    my $data = shift;
    return undef unless $data;
    $self->_do_cmd($') if ( $data=~/^\-\-\+*/);
  return $data; 
};



### Make LST file - it not clean only prototype *- #
sub  _lst_make_file ($) { 
  my $isql = shift;
     local (*LST);
     open  (LST,'> '.$main::LST.$isql->{TestCase}{No}.$main::Lst_Suffix)
				|| print $main::ERR "I can't make LST $!\n" ;
     $isql->Print(\*LST);
     close (LST);
     print $main::LOG "\:$isql->{TestCase}{No} - lst compled Elapse Time $main::Elapse \n";
};




########################################
#
# Command Handler for --+ 
#
########################################

sub _do_cmd  {
 my $self = shift;
 my $cmd  = shift;
    $cmd =~ /(^\w+)\s+(\'[\s\S]+\'|[\S\s]+)?\s*;/;    

 my $cmd = '$self->ts_'.$1.'($prm);';

 my $prm = 
       { 
        prm  => defined($2)? $2 : 0,
	desc => $' || '',
       };
	

    eval $cmd;  
    print $main::ERR "\nisql>",$@ if $@;
 
 sw_queue($self) if ( $#{$self->{IN}}+1 xor _is_queue($self->{STATE}) );
};




sub ts_SECTOR {
    my $self = shift;
    my $prm  = shift || { prm => ''} ;
# -* Change That in concurent control version *- #
    my ($sec,$mod)  = split /\s*[,]\s*/,$prm->{prm},2;           

    print  $main::OUT "isql do SECTOR $sec \n"  if $main::DEBUG > 1 ;
#        print ">>$sec,$self->{Sector_Key}<<\n";

    if (defined($mod) and $mod =~ /IGNORE/)
       {
        $main::tb->ignore_sector($sec);
	undef $sec;       
       };

       # -* excange var and Test SECTOR  *- #    
       ($sec,$self->{Sector_Key}) = ($self->{Sector_Key},$sec) ;



 if ($main::cfg->{LST})
    { 
	# -*   Push into lst command  *- #
        push @{$self->{OUT}},$self->{last_cmd};	
    }
    elsif ( defined($sec)) # not NULL (defined)
        { 
	$main::tb->ok_sector($self,$sec) if ( $self->{ok_sector});
#?!     $main::tb->report_TC              if ($sec == 0) ;
        }
        else
	   {
	    delete $self->{OUT};
	   };
};

sub ts_IGNORE 
 { my $self = shift;
   my $prm = shift;
      $main::tb->ignore_sector($self->{Sector_Key});
      $self->{Sector_Key} = undef;      
 }


sub ts_PRINT {  
   my $self =  shift;
   my $prm =  shift;
      print  $prm->{desc}."\n" if $prm->{prm} >= $main::cfg->{PrintLEvel};
 }

# -* Handler for isql error message analise jast todo *- #



sub ts_AUTO {
    my $self = shift;
    my $prm = shift;    
       $self->do_auto($prm->{prm});
    print $main::LOG "esql autodo $self->{AutoDo}" if $main::DEBUG ;
}



sub error_handler {
	my ($self,$error)  = @_;

};


1;


