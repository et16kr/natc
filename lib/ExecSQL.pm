## -*- perl -*- #
# That Execute Sql Test Script 
# 

package ExecSQL;
$^W=1;

eval { use Data::Dumper; } if $main::DEBUG;
#use Time::HiRes qw(gettimeofday  tv_interval );


require Exporter;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK $AUTOLOAD);

$VERSION   = '1.6';
@ISA       = qw (Event Exporter);
@EXPORT    = qw ($VERSION $POST);
@EXPORT_OK = qw( %ScriptCommand );

use strict;
use integer;
use Const qw ( QUEUE BLOCK WAIT);   # BLOCK: 1, QUEUE:2, WAIT: 4

use File::Basename;
use IO::File;
use IO::Socket;
use ParseSQL qw (  &parse_script_sql);
use isql;

# -* $post_list HOLD sting signal of post stmt *- #
# -* %wait_list Structure of process in WAIT   *- #
use vars qw ( %wait_list %post_list );

# -* Global vars for ExecSQL module *- #
use vars qw ( 
    $_stmt 
    $sem_w 
    $sem_s 
    $current_isql
    $in_do
);

# -*-    test state   -*- #
sub  _is_block  { ($_[0]&BLOCK)? 1 : 0 };
sub  _is_wait   { ($_[0]&WAIT )? 1 : 0 };
sub  _is_queue  { ($_[0]&QUEUE)? 1 : 0 };

# -*- manipelate subs -*- #
sub  sw_block  {$_[0]->{STATE}^=BLOCK};
sub  sw_wait   {$_[0]->{STATE}^=WAIT };
sub  sw_queue  {$_[0]->{STATE}^=QUEUE};
sub  sw_next   {$_[0]->{STATE}=$_[0]->{STATE}};

my $exec_line_no = 0;

sub new  {
    my ($class) = shift;
    my  $self    = 
    {
        warning     => '',
        is_parallel => 'N',
        in_do          =>  0,           # Count process in controll Do    
        _stmt         => '',            # Statment in parse/execute
        TestCaseList  => [],            # Current  List of Test Case
        iSQL_pool     => {},            # POOL OF iSQl Obj
        Queue      => [],               # Common input Queue Statment
        cb_get_script => \&parse_script_sql,    # Subroutine get script 
                                                # from file and parse
        @_,
    };

    bless ($self, $class);

    *_stmt = \$self->{_stmt};

    # -*- Make Event Wait Control point -*- #
    $self->{STATE}   = 0; # NO BLOCK,NO QUEUE, NO WAIT
    $self->{_state}  = $self->{STATE};
    *sem_w = \$self->{STATE};
    *sem_s = \$self->{_state};
    *in_do = \$self->{in_do};

    #!  $self->ts_PROCESS('P0');
    $self->_init_wait;
    $self->_init_sync_start;

    return $self;
};
sub abrupt_exit
{
    my $self = shift;

    my $offset = 0;

    #my $tl = $main::tp->get_cur_tl() || '';
    #my $ts = $main::tp->get_cur_ts() || '';
    print $main::ERR "\n< ABRUPT EXIT REPORT>\n";
    print $main::REP "\n< ABRUPT EXIT REPORT>\n";
    print $main::ERR "WARNING!!! $self->{warning}\n";
    print $main::REP "WARNING!!! $self->{warning}\n";
    #print $main::ERR "TEST LIST  : $tl\n";
    #print $main::ERR "TEST SUITE : $ts\n";
    print $main::ERR "TEST CASE  : ".$self->{TestCase}{file}."\n";
    print $main::ERR "LAST STMT  : \n";
    print $main::REP "TEST CASE  : ".$self->{TestCase}{file}."\n";
    print $main::REP "LAST STMT  : \n";
    foreach my $p_key ( sort keys %{ $self->{iSQL_pool}} )
    {

        $self->{iSQL_pool}{$p_key}->abrupt_exit('SIGINT');
        # -* Print Out LST file *- #    
        if ($main::cfg->{'LST'})
        {
            $self->{iSQL_pool}{$p_key}->_make_lst;
        }
        else
        {
            if ( $self->{is_parallel} eq 'Y' )
            {
                $self->{iSQL_pool}{$p_key}->_make_out;
            }
        }
        if ( $self->{is_parallel} eq 'Y' )
        {
            $offset = $self->{iSQL_pool}{$p_key}->_make_tdx($offset) 
        }
    }
    $main::REP->close;
    &main::_exit(255);
}

################## Local subs PRIVATE none Export #####################
# 
sub run_tc 
{
    my $self = shift;
    my $tc_file;

    # -* set auto sector No *- #
    $self->{q_sct} = 0;
    
    # -* set to ZERO count of work process   *- #
    $in_do = 0;

    # -* Set to ZERO counter of PWAIT commad *- #
    $self->{q_pwait}=0;    
    
    # -* Get Test Case  from TestDB *- #
    $self->{TestCase} = $main::tp->get_tc() || do 
        {
            print $main::DBG "esql Finish TastCase List\n" 
                    if $main::DEBUG ; 
            &main::_exit unless ( _is_wait($sem_w) 
                    or  $main::cfg->{Shell});
            return undef;
        };
                   
    $self->{TestCase}{NameLength} = length($self->{TestCase}{Name});
    $tc_file = ''; # $ENV{ATC_HOME} if $self->{TestCase}{ismap};
    $tc_file .= $self->{TestCase}{file};
    #print ">>> $self->{TestCase}{file}\n";

    $self->{is_parallel}  = 'N';
    $self->{Queue} = &parse_script_sql($tc_file);
    #print "######### num of process : $self->{is_parallel}\n";
    #print Dumper $self->{Queue};


    # -* Open FD for lst output file if in make lst mode * - #
    if( $main::cfg->{'LST'}) 
    {
        my $tc_lst = $main::tp->get_lst_name($main::ex->{TestCase}{file});
        $self->{lst_fd} = new IO::File($tc_lst,'w');

        unless ($self->{lst_fd}) 
        {  
            print $main::ERR "I can't Make LST file $tc_lst!\n";
            return undef
        };

                                
    };
    if ( $self->{is_parallel} eq 'Y' ) 
    { 
        if( !$main::cfg->{'LST'}) 
        {
            # For opening out file on the case of parallel process test case
            my $tc_out = $main::tp->get_out_name($main::ex->{TestCase}{file});
            $self->{out_fd} = new IO::File($tc_out,'w');
    
            unless ($self->{out_fd}) 
            {  
                print $main::ERR "I can't Make OUT file $tc_out!\n";
                return undef
            };
        }

        my $tc_tdx = $main::tp->get_tdx_name($main::ex->{TestCase}{file});
        $self->{tdx_fd} = new IO::File($tc_tdx,'w');      
        unless ( $self->{tdx_fd} ) 
        {  
            print $main::ERR "I can't Make TDX file $tc_tdx!\n"; 
        };
    };

    $self->sw_queue;
};


# -*- sub _wait use only on Event WAIT var handler -*- #
sub _init_wait ($) 
{
    my $self = shift;
    # -*- Event to change Sem VAR -*- #
    $self->{sem_st} = Event->var( 
        pool   => 'w',
        var    => \$sem_w,
        desc   => "ST Semophore",   # description;
        repeat => 1,                # keep alive after events;
        cb     => sub {
            # -*- detect vector of change state -*- 
            my $sem = $sem_s ^ $sem_w;

            # -*- save previose state of semaphore -*- # 
               $sem_s = $sem_w;    

            # -* NoThing Change - I take only SIGNAL DO_NEXT *- #
            return $self->_do unless ($sem);

            # Deactive Event var,now I can change STATE without event
            $self->_do_wait   if _is_wait ($sem);
            $self->_do_block  if _is_block($sem);    

            # -*-   Change Queue state now   -*- #
            $self->_do_queue  if _is_queue($sem);
            # Activate Event
        }
    );
};


#   We need make _sync_start  for synchronize  start process    between --+PWAIT
#    Because some test LOCK process and STOP by time out execution
#    This process should hungup (restart) for next steps of script
#   Time between stop->start->connect->ready soo different and can breack synchronize work
#   For solve this problem propose: implement unlock idle process (some thing like thread )

sub _init_sync_start ($)
{
   my $self = shift;
   $self->{_sync_start} 
           =  Event->idle
        #  =  Event->timer         
        (
            parked => 1,    # ready but not start 
            min    => 0.0025,
            #interval => 0.0002,
            desc   => "*IDLE*TEST*",
            cb     =>  sub  {
                my $ev = $_[0]->w;
                my $data = $ev->data;
                print $main::DBG ".\n" if ($main::DEBUG & 4);

                foreach ( @$data) 
                { 
                    return  if ( $$_ & BLOCK);
                };

                #!                       ${$data->[0]}^=WAIT;
                # start main thread and kill himself #
                $self->{iSQL_pool}{P0}->sw_wait 
                        if ($self->{iSQL_pool}{P0}{STATE} & WAIT) ;
                $ev->stop;
            }
        );
 };
 

# -*- execute on waite state -*- #

sub _do ($)  
{
    my $self = shift;
    # Detect whot is STATE now
    #            print "I am WAIT \n"     if _is_wait ($sem_w);
    #            print "I am BLOCK\n"     if _is_block($sem_w);

    my @cmd_list;
    if ( _is_queue($sem_w) and not  _is_wait($sem_w))
    {
        if (@cmd_list = shift @{$self->{Queue}})
        { 
            # post next Event 
            sw_next($self);

            ## -!- Control point for push data to queue -!- ##
            $exec_line_no = $cmd_list[0][0];
            $_ = $cmd_list[0][1];

            #print "\n$_\n";
            if (/^\s*\-\-\+\s*/)
            {
                $self->_do_cmd($');
            }
            else 
            {  
                # -*-   push to default isql   -*-  #
                push @{$current_isql->{IN}},@cmd_list;
            };
        }
        else
        { 
            sw_queue($self)
        };
    }
    else
    {
        print $main::DBG "esql w and !q\n" if ($main::DEBUG & 2 ) ;
        sw_queue($self) if( $#{$self->{Queue}}+1 xor _is_queue($sem_w) );
    };
};


sub _do_wait 
{ 
    my $self = shift;
    print $main::DBG "esql check  WAIT\n" if ($main::DEBUG & 2);

    # -* Call Report Procedure *- #
    $main::tb->report_TC if ( ($main::cfg->{Verbose} >= 2) 
                                and not  _is_wait($sem_w)  
                                and not  $main::cfg->{LST});
     
                        
     # -* Do next TC *- # 

    if ($self->{TestCaseList} and not _is_wait($sem_w))
    {

        # -* Generate ordered LST by PROCESS name *- # 
        my $p_key;
        my $offset = 0;

        # -* Check result for TC *- #
        my $tc   = $main::tb->{CurrentTestCase};
        $tc   = defined($tc->{plan}) ? +($tc->{plan} - $tc->{ok}) : 0; 

        foreach $p_key ( sort keys %{ $self->{iSQL_pool}} )
        {

            # -* Print Out LST file *- #    
            if ($main::cfg->{'LST'})
            {
                $self->{iSQL_pool}{$p_key}->_make_lst;
            }
            else
            {
                #make out file only if it is parallel test case
                if ( $self->{is_parallel} eq 'Y' )
                {
                    $self->{iSQL_pool}{$p_key}->_make_out;
                }
            }
            if ( $self->{is_parallel} eq 'Y' )
            {
                $offset = $self->{iSQL_pool}{$p_key}->_make_tdx($offset) 
            }

      
            # -* Remove Object except P0 *- #
            #unless ( $p_key eq 'P0' )
            {
                # -! Check for cance event     
                delete $self->{iSQL_pool}{$p_key};
            }
        };
          
        $self->{tdx_fd}->close 
            if ( $self->{is_parallel} eq 'Y' && 
                 defined( $self->{tdx_fd})  &&  
                 $self->{tdx_fd}->opened); 
        $self->run_tc;
    };
};

sub callback_unblock_wait 
{
    $sem_w ^= WAIT unless ( --$in_do);
    print $main::DBG "isql unblock esql:$in_do\n" if ($main::DEBUG & 2);
}

sub _do_block 
{
    my $self = shift;
    print $main::DBG "esql block\n" if ($main::DEBUG & 2 );
};

sub _do_queue
{ 
    my $self = shift;

    if( _is_queue($sem_w))
    {
        print $main::DBG "esql inqueue TC\n" if ($main::DEBUG & 2);

        #!       $current_isql->_hang_up; #  process create before Parsing 
        $self->ts_PROCESS('P0');    # statment ! if some server stop/start
                                    # Restart take 0,1 sec
        sw_next($self)
    }
    else
    {
        #   HUP
        print $main::DBG "esql unqueue TC\n" if ($main::DEBUG & 2);
        #!     $self->ts_PROCESS('P0'); # Process Start After parsing 
                                # But posible some problem timing sysnchronise 
                                # In multi process script;
    }#else { Event::unloop() }
};

sub _do_cmd  
{
    my $self = shift;
    my $cmd  =  shift;

    no strict 'refs';      
    #print ">>> in do_cmd :: $cmd\n";
    #s/^\s+//g;
    $cmd =~ /^(\w+).*/;
    if ( defined $1 && defined(*{'ExecSQL::ts_'.$1}{CODE}) )
    {
        eval '$self->ts_'.$cmd;
        print $main::ERR "\nExecSQL($exec_line_no)>$cmd<\n",$@ if $@;
    }
    else
    {
        $self->_pass_to_process_cmd($cmd);
    };    

    use strict;  
};

######################################################################################
#          -*             Sinchronize Control function        *-                             #
# -* Set data string to wait structure *- #


# Check matching on HASHS
# Any call chack wait check for all states

sub check_wait 
{
    my  $self = shift;  

    my ($w_key,$p_key); # key in HASH for wait & post
    my ($w_val,$p_val); # Value 
    my ($w_idx,$p_idx); # Index in structure

    #  print Dumper \%post_list;
    map  # POST have got top level for seach unblock
      {$p_key=$_;
      for  $p_idx(0..$#{$post_list{$p_key}})
       {
        $p_val = $post_list{$p_key}[$p_idx]||'';

        map
         {$w_key = $_;

         for $w_idx(0..$#{$wait_list{$w_key}})
          {
           $w_val = $wait_list{$w_key}[$w_idx]||'';
           if  ( !($p_key eq $w_key) and ($w_val eq $p_val) )
            {
             splice (@{$wait_list{$w_key}},$w_idx,1); # Cat state string
             unless (@{$wait_list{$w_key}})
              {
                $self->{iSQL_pool}{$w_key}->sw_wait() 
                       if ( $self->{iSQL_pool}{$w_key}{STATE} & WAIT) ;
                print $main::DBG "WAIT CATH! for $w_key \n" if $main::DEBUG & 8;
               };
            }
          }#@{$wait_list{$p_key}};
      } keys %wait_list;

    }# @{$post_list{$w_key}};
  } keys %post_list;
};

sub is_P0_in_pwait
{ 
    my $self = shift;
    return ($self->{iSQL_pool}{P0}{last_cmd} =~ /^\-\-\+\s*PWAIT/ ) ? 1 : 0 ;
};
 
 
#######################################################################################
# -* This procedure pass to current_isql into QUEUE command if that haven't HANDLE *- #

sub _pass_to_process_cmd 
{
    my $self = shift;
       $_    = shift;
       s/^(\w+)\s*//;
    my $cmd  = $&;
    s/^[\(\s]*|\s*\'+\s*|[\)\;\s]*$//g;
    my @par  = split /\s*\,+\s*/,$_;
    my $separ= ' ';
    my $desc = ($#par) ? delete $par[$#par] : '';

    $desc = '' unless defined($desc);

    foreach (@par) 
    {
         $cmd.= $separ.$_;
         $separ = ',';
    };

    push @{$current_isql->{IN}},[$exec_line_no, '--+'.$cmd."; " . $desc] if ($cmd);
};

 
###################### Head parse function ################## 
# -*- sub for parse SQL STATMENT Embedid
#
sub DESTROY {
 my $self = shift;
 # -*- If your have WAIT Eveht handle - CANCEL it -*- #
 $self->{ev_wait}->cancel if $self->{ev_wait};
}



sub ts_WAIT  
{
    my $self = shift;
    my $parm = shift;
    my $mess = shift;
     
    if ($parm =~ /^ALL$/)
    {
        # -* Check is QUEUE hase some thing for DO ??    
        unless ( @{$current_isql->{IN} } )
        { 
            print $main::DBG 
                    "   $self->{TestCase}{No}..SKIP # Nothing to DO!!!\n";  
            $self->run_tc if ($self->{TestCasList});  
            $self->sw_queue;
            return undef;    
        };
  
        $self->sw_wait()  ;   
        print $main::DBG "esql switch WAIT\n" if ($main::DEBUG  & 2);
        # -* code for set WAIT *-#
    
        $main::tb->plan( tests => $self->{q_sct},$self->{TestCase}) 
            if (not $main::cfg->{LST});
 
        # -* Check ready isql for same time point start *- #    
        # -* Inicialize sync start event handler         *- #
 
        my @STATE;
        my $ev = $self->{_sync_start};

        foreach (keys %{$self->{iSQL_pool}})
        { 
            $in_do++ if (@{ $self->{iSQL_pool}{$_}{IN} } );
            $self->{iSQL_pool}{$_}->start() if $self->{iSQL_pool}{$_}->{AutoDo};
            push @STATE, \$self->{iSQL_pool}{$_}{'STATE'};
        };
     
        # -* init process sync_start
        $ev->data(\@STATE);
        $ev->start unless $main::DEBUG & 8 ;  
        # -* end of Inicialize sync start event handler *- #     
    } 
    else
    {
        push @{ $current_isql->{IN} },[$exec_line_no, '--+WAIT '. $parm . ";$mess"];      
    };
};


sub ts_SYSTEM
{
    my $self = shift;
    my $parm = shift;
    my $mess = shift;

    $parm =~ s/^\s+|\s+$//g;         # remove witespace  
    push @{ $current_isql->{IN} },[$exec_line_no, '--+SYSTEM '. $parm . ";$mess"] ;  
}

sub ts_KILL_CLIENT
{
    my $self = shift;
    my $parm = shift;
    my $mess = shift;

    $parm =~ s/^\s+|\s+$//g;         # remove witespace  
    $current_isql = $self->{iSQL_pool}{'P0'};
    push @{ $current_isql->{IN} },[$exec_line_no, '--+KILL_CLIENT '. $parm . ";$mess"] ;  
}

# -* PWAIT DISPATCHER * - #
#
sub ts_PWAIT 
{
    my $self = shift;
    my $parm = shift;
    my $mess = shift;

    $parm =~ s/^\s+|\s+$//g;         # remove witespace  
    my @cs   = split /\s*[,]\s*/,$parm; # split parametrs
    @cs   = grep !/^\d*\.?\d*$/,@cs; # remove Tmeout from parametr

    # -* Set current_isql and dispatch --+PWAIT to main process P0 *-  #
    $current_isql = $self->{iSQL_pool}{'P0'};
    push @{ $current_isql->{IN} },[$exec_line_no, '--+PWAIT '. $parm . ";$mess"] ;   

    #  fork --+PW_P to others process #
  
    # --* case when list of process ommit *-- # 
    @cs = keys %{$self->{iSQL_pool}} unless @cs;


    # -* set counter for pwait *- #
    ++$self->{q_pwait};

    foreach my $p_key (@cs)
    {
        push @{ $self->{iSQL_pool}{$p_key}{IN} },[$exec_line_no, "--+PW_P $self->{q_pwait};" ]
            unless ($p_key eq 'P0');
    };    
};

sub ts_LOAD_SQL
{
    my $self = shift;
    my $parm = shift;
    my $mess = shift ||'';
    my $t_queue = [];

    $parm =~ s/\s*//g;
    #print ">>> $parm :: $mess\n";

    #print Dumper $self->{Queue};
    $t_queue = &parse_script_sql($self->{TestCase}{path}.$parm);
    pop @{$t_queue}; ## eliminate the last command, WAIT 
    unshift @{$t_queue}, [$exec_line_no, "--+PRINT (' => [". $parm . "] BEGIN <=', ' ');"];
    push @{$t_queue}, [$exec_line_no, "--+PRINT (' => [". $parm . "] END <=', ' ');"];
    while (@{$t_queue})
    {
        unshift @{$self->{Queue}}, ( pop @{$t_queue});
    }
    #print Dumper $t_queue;
    #print Dumper $self->{Queue};
}
    
sub ts_PRINT
{
    my $self = shift;
    my $parm = shift;    
    my $mess = shift||'';
    push @{$current_isql->{IN}},[$exec_line_no, '--+PRINT '.$parm.";$mess "];
}

# -* Process release for Concurent control *- #

sub ts_PROCESS
{  
    my $self = shift;
    my $parm = shift; 
    # my $mess = shift|| " default iSQL $parm";
    my $mess = shift|| '';


    # -* Cat process No for pool of process
    $parm =~ s/^\s*(\D+\d+)\s*\,?\s*//;
    my $p_key = $1;
  
    if ($self->{iSQL_pool}{$p_key}{q_prc})
    {
          $current_isql=$self->{iSQL_pool}{$p_key};     
        # -* Experemental SECTOR point for sorting orders *- #
        $self->ts_SECTOR(0,"BY ATC");
       
        return;
    };

    my $time_out = ($parm =~ /^\s*(\d*\.?\d*)\s*$/) 
                ?   $1 
                :   $main::cfg->{'IO_TIMEOUT'};

    # -* Check current state READY  pair baind ALTIBASE&isql *- #

    # Check is it object isql blessed #
    if ( ref($self->{iSQL_pool}{$p_key}) eq 'isql' ) 
    { 
        #$self->{iSQL_pool}{$p_key}->_hang_up() unless  $self->{iSQL_pool}{$p_key}->check_myself ;
        $current_isql = $self->{iSQL_pool}{$p_key};
    }
    else
    {
        #        my $prg_name = $main::cfg->{iSQL};
        #        $prg_name =~ s/^isql/$main::cfg->{'DB_DRIVER'}/ 
        #                if $main::cfg->{'DB_DRIVER'};

        $current_isql = new isql
        (
            q_pwait        => 0,    
            max_cb_tm      => $time_out || $main::cfg->{'IO_TIMEOUT'} || 0,    
            id_key         => $p_key,    
            callback_ready => \&callback_unblock_wait,
            # ProgName     => $main::cfg->{iSQL},
            # ProgName        => $prg_name,
        );


        $self->{iSQL_pool}{$p_key} = $current_isql;

        # -* if Shell and DEBUG yuor can see current like $A OBJ *- #
        if ($main::DEBUG) 
        {
            my $eval_str = '*main::'.$p_key.'=\$self->{iSQL_pool}{'.$p_key.'};';
            eval $eval_str;
            print $main::ERR "I can't set GLOB in debug mode to iSQL OBJ !"
                        ."\n $@ " if $@;
            print $main::DBG "exsql  $p_key +\n" if $main::DEBUG & 1 ;
        }; 

        ++$current_isql->{'q_prc'};
 
    }; # END IF                    

    #!? -* Set $carrent_isql !
    #!? $current_isql->{q_sct} = 0;
  
    # -* Clear OUTPUT BUFFER; and reset *- #
    delete  $current_isql->{OUT};
    $current_isql->{OUT}=[];
    $current_isql->{q_out}=0;
          
    # -* Clear time_stmp TIME STMP HASH *- #
    delete  $current_isql->{time_stmp};
          
    # -* Set reference to global HASH 
    $wait_list{$p_key}=$current_isql->{_w_list};
    $post_list{$p_key}=$current_isql->{_p_list};

    # Clear memory !! not drop reference
    splice(@{ $wait_list{$p_key}},0,@{ $wait_list{$p_key}}); 

  
    ## -* Make auto SECTOR statment! *- #
    chomp($mess);
    $self->ts_SECTOR(0,$mess . " BY ATC");
    push @{ $current_isql->{IN} },[$exec_line_no,"--+PROCESS $p_key;$mess"];

    # -* Set node PWAIT ( Level for start );
    $current_isql->{q_pwait} = $self->{q_pwait};

    # Set wait dependence from P0 #   
    unless ($p_key eq 'P0' )
    {
        push @{ $self->{iSQL_pool}{$p_key}{_w_list} },$self->{q_pwait};    
    };

    return $current_isql;      
};

sub ts_CONNECT
{
    my $self   = shift;
    $^W = 0;
    $_ = shift; # use  --+connect  to  host:port  user/passwd ; 
    /^\s*(\w+)?(\:)?(\d+)?\s*(\w+)?(\/)?(\w+)?([ ]\S+\Z)/ ;
    my ($host,$port,$user,$pass,$id) = ($1,$3,$4,$6,$7);

    #    printf $main::DBG  "\n>>host =%s,port=%s,user=%s,pass=%s,id=%s,<<\n",
    #               $host,$port,$user,$pass,$id;

    # -* convert name to host *- #
    if ($host) 
    {
        my (undef,undef, undef, undef, @addrs) = gethostbyname($host);
        unless ($addrs[0]) { return $host =  undef; last };
        my ($a, $b, $c, $d) = unpack('C4', $addrs[0]); 
        $host = "$a.$b.$c.$d"; 
    };

    printf $main::DBG  "\n>>host =%s,port=%s,user=%s,pass=%s,id=%s,<<",
               $host,$port,$user,$pass,$id;
    $^W = 1;
};


=remove ts_SET_ENV
sub ts_SET_ENV 
{
    my $self = shift;
    my $parm = shift;    
    my $mess = shift||'';

    # -* Expand variable and symbol ~ *- #
    $parm =~ s/^\s+//;
    
    $parm =~ s/^(\w+)\s*\=\s*//;    # -* Split
    my    $env_key = $1;                # -* Extract Env Name parametr
    # -* Detect Host local or remote
    
    $current_isql->{ProgName} =~ /\s*(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})\s*/;

    if ($1 eq '127.0.0.1')
    {
        # -* SET local enviroument
      
        $parm =~ s/\=\s*~/=$ENV{HOME}/; # -* add home dir if exist 

        #! can ommit for local  $parm =~ s/\$(\w+)/$ENV{$1}/$;  
        # -* Expand variable

        $ENV{$env_key} = $parm;
    }
    else
    {
        # -* Set structure for remoute implement ENV *- #
        # -* Expand variable
        if ( ($parm =~ /\$(\w+)/) and (defined   $current_isql->{env}{$1}) )
        {
            $parm =~ s/\$(\w+)/$current_isql->{env}{$1}/g;
        };
      
        $current_isql->{env}{$env_key} = $parm;
    }
};
=cut

sub ts_IGNORE 
{
    my $self = shift;
    my $parm = shift|| '';
    my $mess = shift|| '';
    push @{$current_isql->{IN}},[$exec_line_no, '--+IGNORE '.$parm.";$mess "];    
};


sub ts_SECTOR 
{
    my $self = shift;

    my $parm = shift|| 0;
    my $mess = shift||'';

    $parm = ($parm) ? "$self->{q_sct},$parm" : "$self->{q_sct}";
    # -* Change That in concurent control version *- #
   
    push @{$current_isql->{IN}},[$exec_line_no, '--+SECTOR '.$parm.";$mess"] ;
    # -* incriment count of *- #
    #    ++$current_isql->{q_sct};
    ++$self->{q_sct};
}

sub _ping_db
{
    my $self = shift; 
    my $sock = new IO::Socket::INET (
                    PeerAddr    =>  $_[0],
                    PeerPort    =>  $_[1],
                    Proto       =>  'tcp'
                ) || return 0 ;

    # -* Exactly check ALTIBASE port and protocol *- #                      
    $sock->printflush('IDC_INET_');
    $sock->sysread($_,9);

    return (/^IDC_READY/) ? 1 : 0;
}


1;

