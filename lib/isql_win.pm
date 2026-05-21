# -*- perl -w -*- #
package isql;

$^W=1;
use strict;

use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);
use vars qw ($AUTOLOAD  $exec_sql);
require Exporter;

eval {use Data::Dumper  } if $main::DEBUG;

$VERSION    = ''; 
@ISA        = qw( Exporter );
@EXPORT     = qw( );
@EXPORT_OK  = qw( $VERSION);

use Const qw ( QUEUE BLOCK WAIT);
use Event qw( unloop);
use Time::HiRes qw(gettimeofday  tv_interval );
use IO::File;
    
my $OSWinFlag;
if ($^O =~ /(MSW|cygw)in/)
{
    $OSWinFlag = $^O;
}

if ($OSWinFlag) 
{
    use IO::ExtWinSock qw( );
}
else 
{
    use IO::ExtSock qw( );
}

use POSIX qw( BUFSIZ EWOULDBLOCK);
use Fcntl qw( F_SETFL F_GETFL O_NONBLOCK);
use ParseSQL

$VERSION = '0.01';

sub new  
{
    my $class = shift;
    my $self = {
        last_data         => '',
        server_dead       => 'N',
        auto_restart      => 'Y',
        out_string_prefix => ". ",
        rollback_point    => 0,
        new_stmt          => 'Y',
        driver_ready      => 'N',
        last => [],
        # keep a line index in isql->{OUT} to handle parallel out
        # It should be changed!!!
        OutIndex          => 0,
        # Current line number
        script_line      => 0,
        try_cnt_connect  => 0,
        try_max_connect  => 3,
        result_receiving => 'N',
        _lst_p           => '',
        max_cb_tm        =>  0,  # Exceed time out for take some thing from iSQL
        callback_cmd         => \&callback_cmd,
        callback_read_handle => \&callback_read_handle,
        callback_ready       => \&callback_ready,
        #ProgName            => 'loader.sh isql -s 127.0.0.1 -u sys -p MANAGER -silent',
        AutoDo               => int 1,   # Auto Do nextcommand if READY
        # -* It use when READY and TC finishid (SET FOR NEXT TC) *- #
        BufferIN  => '',
        IN        => [],
        #Expect   => 'iSQL>\s$|^\s+\d+\s$|^>\s$', # Expect for unblock
        ExpectFirst => 'iSQL>\s$', # Expect First prompt
        Expect    => 'iSQL>\s$|iSQL\d+\s+$', # Expect for unblock
        id_key    => 'P0',         # Default name of process/can be redefined 
        ok_sector => 1,            # 1 - Check by ok_sector call
        STATE     => BLOCK+WAIT,#TCurrent State
        _SW       => int 0,     # Internal state of process    
        _state    => 0,         # Store previose STATE 
        _skip     => 0,         # Flag for skip output 
        q_cmd     => 0,            # Count of common script cmd
        q_sct     => 0,         # Counter of SECTOR's
        q_out     => 0,         # Counter of OUT queue
        # ref Array for post and wait solve use in ExecSQL %wait_list,%post_list
        # Attention DONT MANIPULATE BY REF - ExecSql use Same ref fro lists
        _p_list  => [],        # List To post event for WAIT
        _p_history  => [],        # List To post event for WAIT
        _w_list  => [],        # List wait for string
        # stub for check wait method
        #!?callback_check_wait   => \&callback_check_wait 
        last_cmd => '',
        @_,
    };

    bless( $self,$class);
  
    #$self->{ProgName} = $self->make_client_command($self->{id_key});

    # -* primpt for output *- #
    $self->{'prompt'}     = '$'.$self->{id_key}.'> ';    

    # -* Callback for time Exceed I/O can be CODE ref *- #
    $self->{'timeout_cb'} ||= [$self,'_timeout_cb'];   

    if ($main::DEBUG & 1)
    {
        $SIG{PIPE} = sub 
        { 
            print  $main::LOG ">$self->{prompt} PIPE Broke! <<<\n";
        }; 
    }
    else 
    {
        $SIG{PIPE} = 'IGNORE';
        $SIG{INT} = sub
        {
            #print Dumper $self;
            print "\n";
            $main::ex->{warning} = "\nInterrupted by SIGINT\n";
            $main::ex->abrupt_exit();
            #&main::_exit(255);
        }
    };


    # -*-  Set sender to Client -*- ##
    $self->{evs} = Event->var(
        pool   => 'w',
        var       => \$self->{STATE},
        desc   => "WP",   # description;
        repeat => 1,                         # keep alive after events;
        cb     => sub 
        { 
            # -*- detect vector of change state -*- 
            my $sem = $self->{_state} ^ $self->{STATE};
            $self->{_state} = $self->{STATE};

            # -* NoThing Change - I take only SIGNAL SYNCK            *- #
            # -* It's Happend when all finishid for global WAIT synck *- #
            #print "\n--- $self->{prompt} sem value = $sem\n";
            return  $self->_do_synck unless ($sem);

            $self->_do_wait  if _is_wait ($sem);
            $self->_do_block if _is_block($sem);    
            # -*-   Change Queue state now   -*- #
            $self->_do_queue if _is_queue($sem);

            # -*- save previose state of semaphore -*- # 
        }
    );

    $self->{evt} = Event->timer(
        interval => 0,
        repeat => 0,
        desc   => "TIMER",   # description;
        cb => $self->{timeout_cb}
    );

    $self->{evt}->stop;
 
    # -*- Some Elapse Timer -*- #
    $self->{TimeElapse} = 0 ;
    $self->{TimeOP}     = $main::ex->{sem_st}->cbtime;


    # -*  heck state of Server *- #
    # my %prm;
    # $prm{prm}='server start';
    # $self->ts_SYSTEM(\%prm) unless ($self->_ping_db and $main::cfg->{SERVER_AUTOSTART};

    $self->{driver_ready} = 'N';
    $self->sw_block;
    return  $self;
};

sub make_client_command
{
    my $self = shift;
    my $idkey = shift;
    my $tmpl = $main::tp->get_nearest_scope($idkey, 'client_list');
    my $server = undef;
    my $cmd;
    my $cmd_env;
    my $cmd_arg;
use Sys::Hostname;
use HostIP;
    my $host_name = hostname;
    my $host_ip = hostip;
no Sys::Hostname;
no HostIP;
no strict 'refs';
    my $server_name = $tmpl->{SERVER};

    if ( defined ($server_name) )
    {
        $server = $main::tp->get_nearest_scope($server_name,'server_list');
        $self->{SERVER_CONTEXT} = $server_name;
        $tmpl->{DB_SERVER} = $server->{HOST_IP};
    }
    else
    {
        $tmpl->{DB_SERVER} = '127.0.0.1';
    }

    #print Dumper $tmpl;
    $cmd = '';
    if (($tmpl->{HOST_IP} ne "127.0.0.1") &&
        ($tmpl->{HOST_IP} ne $host_name) &&
        ($tmpl->{HOST_IP} ne $host_ip))
    {
        $cmd .= "rsh " . $tmpl->{HOST_IP};
    }

    $cmd .= " loader.sh ";

    if (defined $server && defined $server->{ALTIBASE_HOME})
    {
        $cmd_env .= " -D ALTIBASE_HOME=". $server->{ALTIBASE_HOME};
        $cmd_env .= " -D PATH="."'\$ALTIBASE_HOME/bin:\$PATH'";
    }

    $cmd_env .= " -D ISQL_CONNECTION=". $tmpl->{ISQL_CONNECTION} if defined $tmpl->{ISQL_CONNECTION};
	if ($OSWinFlag) 
    {
	    $cmd_arg .= " 'cd $main::ex->{TestCase}{path}; " . "WinAtc \"" . $tmpl->{DRIVER}; 
	}
	else 
    {
	    $cmd_arg .= " 'cd $main::ex->{TestCase}{path}; " . $tmpl->{DRIVER};
	}

    ### for new version
    $cmd_arg .= ' -atc';
    ### end

    if ( $tmpl->{HOST_IP} eq $tmpl->{DB_SERVER} ) 
    {
        $cmd_arg .= ' -s 127.0.0.1';
    }
    else 
    {
        $cmd_arg .= " -s " . $tmpl->{DB_SERVER};
    }

    $cmd_arg .= " -u " . $tmpl->{DB_USER}   if defined $tmpl->{DB_USER};
    $cmd_arg .= " -p " . $tmpl->{DB_PASSWD} if defined $tmpl->{DB_PASSWD};
    if (defined $tmpl->{PORT_NO})
    {
        my $port_no = $tmpl->{PORT_NO};
        if (defined $server && defined $server->{ALTIBASE_PORT_NO})
        {
            $port_no = $server->{ALTIBASE_PORT_NO};
            if ($port_no =~ /%PORT_NO/)
            {
                $port_no = $self->_getPortNo($main::cfg->{PORT_NO}, $');
            }
        }
        if (defined $self->{env}{ALTIBASE_PORT_NO})
        {
            $port_no = $self->{env}{ALTIBASE_PORT_NO};
            if ($port_no =~ /%PORT_NO/)
            {
                $port_no = $self->_getPortNo($main::cfg->{PORT_NO}, $');
            }
        }
        $cmd_arg .= " -port ". $port_no;
        $cmd_env .= " -D ALTIBASE_PORT_NO=" . $port_no;
    }
    if (defined $self->{env}{ALTIBASE_NLS_USE})
    {
        $cmd_env .= " -D ALTIBASE_NLS_USE=" . $self->{env}{ALTIBASE_NLS_USE}{value};
    }
    $cmd_arg .= " " . $tmpl->{OPTIONS}      if defined $tmpl->{OPTIONS};
    
    # windows tcp port 
	if ($OSWinFlag) 
    {
        if ($main::win_port == 0)
        {
            $main::win_port = $self->_getPortNo($main::cfg->{PORT_NO}) + 10001;
        }
        $cmd_arg .= "\" \"$main::win_port";
        $cmd_arg .= "\"'";
	}
	else {
	    $cmd_arg .= "'";
	}
    $cmd .= $cmd_env . $cmd_arg;

    $self->{DB_SERVER} = $tmpl->{DB_SERVER} if defined $tmpl->{DB_SERVER};
    $self->{PORT_NO} = $tmpl->{PORT_NO} if defined $tmpl->{PORT_NO};

    my $log_str = sprintf("\[$main::ex->{TestCase}{Name}:C\] $self->{prompt} %s\n\n", $cmd); 
    open(SYSLOG, ">> $main::cfg->{SYSTEM_log_file}");
    print SYSLOG $log_str; 
    close(SYSLOG);
    use strict;

    $self->{ProgName} = $cmd;
    return $cmd;
}

## -*- This Reader from Sockets -*- ##
sub _open  
{
    my $self = shift;

    #print ">>>> OPEN::: idkey = $self->{id_key}\n";
    #print Dumper $self;
    my $cmd = $self->make_client_command ($self->{id_key});
    #print "ISQL COMMAND = [$cmd]\n";

    $self->{q_cmd} = 0; # reset couter for TC
    $self->{_SW}   = 0; # Set state to 0    

    #! my $sock = new IO::ExtTTY($self->{ProgName})  || do { 
    #print ">>> now start isql\n";
    #print "\n>>> open :: ($self->{last}[0]) $self->{last}[1]\n";
	my $sock;
	if ($OSWinFlag) {
	    $sock = new IO::ExtWinSock( $cmd )  || do 
	        {
	            print $main::ERR "$self->{prompt}I cant start process @_\n" ;
	            return undef;
	        };
	}
	else {
	    $sock = new IO::ExtSock( $cmd )  || do 
	        {
	            print $main::ERR "$self->{prompt}I cant start process @_\n" ;
	            return undef;
	        };
	}

    #!    $sock->blocking(1);
    
    my $pid  = ${*$sock}{pid};  
 
    $self->{pid}  = $pid;
    $self->{sock} = $sock;
 
    if ( $self->read_data_from_isql < 0)
    {
        $self->_close;
        #$self->sw_block if _is_block($self->{STATE});
        #$self->sw_wait if _is_wait($self->{STATE});
        #print "\n>>> $self->{prompt} : not connected :: $self->{last}[1]\n";
        #$self->{last} = shift @{$self->{IN}} if @{$self->{IN}};
        $self->{_state} = 1;
        $self->_do_block;
        return;
    }

    $self->{evs}->stop;
    unless ( _is_block($self->{STATE}) )
    {
        $self->{ STATE}^=BLOCK  + WAIT;
        $self->{_state}^=BLOCK  + WAIT;
    };

    #! $self->{evs}->start;
    $self->{evs}->again;
 
    $self->{evr}  = Event->io (
        # -* Timeout callback breack
        timeout    => $self->{max_cb_tm},
        timeout_cb => $self->{timeout_cb},

        # -* config Event *- #
        pool => 'r',         
        fd   => $sock,
        desc => "RP:$pid",
        cb   => sub 
        {
            # -*- I take event and Elapse Time of Response -*- #    
            #$self->{TimeElapse}=tv_interval($self->{TimeOP});

            my $sock = $_[0]->w->fd; # take the Sock handle
            my $data = ''; 
            # -*- This two for clean call -*- #
if ($self->{server_dead} eq 'N')
{
            my $rv   = sysread($sock,$data,POSIX::BUFSIZ);
            
			print "\n>>> data : $data\n" if ($main::DEBUG & 1); 
            if (!$rv || $!) # Some ERROR HANDLE
            {
                #if ($self->{id_key} eq 'P0')
                {
                    print $main::ERR "$self->{prompt}Process $pid close sock $!\n"
                         if ($main::DEBUG & 1); 
                    $self->_err_pipe;
                }
=for modifying
                else
                {
                    $self->sw_block if _is_block($self->{STATE});
                    #$self->sw_wait if _is_wait($self->{STATE});
                    if ($self->{OUT}[@{$self->{OUT}}-1] !~ /PROCESS/)
                    {
                       $self->_pop_out;
                       #pop @{$self->{OUT}};
                    }
                    $self->_mark_start_tdx_item('R');
                    $self->_push_out("$self->{prompt} Connect To Server Fail");
                    $self->_mark_end_tdx_item();
                }
                #$self->{driver_ready} = 'N';
=cut
            }
            else
            {
                $self->{last_data} = $data;
                if ($data =~ /Connection closed/ ||
                    $data =~ /Fail connect to server/ ||
                    $data =~ /Communication failure/ )
                {
                    #print "\n>>> Detect Server Death...\n";
                    #print "auto_restart = $self->{auto_restart}\n";
                    if ( $self->{auto_restart} eq 'Y' )
                    {
                        $self->sw_block if  _is_block($self->{STATE});
                        $self->_err_pipe('OK');
                    }
                    else
                    {
                        $self->{server_dead} = 'Y';
                        $self->sw_block if _is_block($self->{STATE});
                        $self->_push_out("Client was disconnected from the server");
                        $self->{result_receiving} = 'Y';
                    }
                }
                else
                {
                    &{$self->{callback_read_handle}}($self,$data);
                }
            }
}
else
{
    $self->sw_block if _is_block($self->{STATE});
    if ($self->{result_receiving} eq 'N')
    {
        $self->_push_out("Client was disconnected from the server");
        $self->{result_receiving} = 'Y';
    }
}
        }
    );

    print  $main::DBG "$self->{prompt}$pid:Process  started...\n"
                      if ($main::DEBUG & 1) ;

    $self->{driver_ready} = 'Y';
    return $sock;
};


sub handle_disconnect
{
    my $self = shift;

    $self->{driver_ready} = 'N';
    $self->{try_cnt_connect}++;
    if ($self->{id_key} eq 'P0')
    {
        print $main::ERR "INIT> $self->{prompt}Process $self->{pid} close sock $!\n"
                if ($main::DEBUG & 1); 
        if ($self->{try_cnt_connect} > $self->{try_max_connect})
        {
            print $main::ERR "\n\n$self->{prompt} Connect To Server Fail\n";
            $main::ex->{warning} = "Can't connect to Server\n";
            $main::ex->abrupt_exit();
        }
        else
        {
            $self->_err_pipe;
        }
    }
    else
    {
        if (@{$self->{IN}} && $self->{IN}[1] !~ /^--+/)
        {
            $self->{last} = shift @{$self->{IN}} if @{$self->{IN}} ;
        }
        #print Dumper $self->{IN};
        #$self->_mark_start_tdx_item('R');
        #$self->_push_out("$self->{last_data}");
        #$self->_mark_end_tdx_item();
    }
    return -1;
}
## Get the first prompt from isql ##
sub read_data_from_isql
{
    my $self = shift;
    my $data = ''; 
    my $rv   = sysread($self->{sock},$data,POSIX::BUFSIZ);
            
    if (!$rv || $!) # Some ERROR HANDLE
    {
        return $self->handle_disconnect;
    }
    else
    {
        $self->{last_data} = $data;
	    #print "\n>>> data : $data\n";
	    #if ($data =~ /Connect To Server Fail/ )
	    #if ($data =~ /Client unable to establish connection/ ||
        #    $data =~ /Fail connect to server/)
        if ($data !~ /iSQL>/)
        {
            #print "\n>>> data : $data\n";
            $rv   = sysread($self->{sock},$data,POSIX::BUFSIZ);
            while ($rv && !$!)
            {
                $self->{last_data} .= $data;
                $rv   = sysread($self->{sock},$data,POSIX::BUFSIZ);
            }
            my $t_ln = "";
            if ( /\n$/ )
            {
                $t_ln = "\n";
            }
            my @_data = split /[\r\n]/,$self->{last_data};
            while ( @_data > 0)
            {
                $_ = shift @_data;
                $self->_push_out($self->{out_string_prefix} . $_ ) if $_ ;
            };
            #$self->_push_out($t_ln);

            return $self->handle_disconnect;
        }
        #print "\n>>> isql ready\n";
    }
    $self->{try_cnt_connect} = 0;
    return 0;
}

sub _hang_up($)
{
    my $self = shift;
    $self->_close ; 
    $self->sw_block unless _is_block($self->{STATE});

    #print $main::ERR "_hang_up:::\n";
    $self->_open ; 

    if ($self->{driver_ready} eq 'Y')
    {
        return 0;
    }
    else
    {
        return -1;
    }
    #return $self->check_myself;
};

sub _save_final_result
{
    my $self = shift;
    #if ($self->{last})
    {
        $self->_push_out('killed by KILL_CLIENT command');
        $main::tb->ok_sector($self,$self->{Sector_Key}) if ( $self->{ok_sector});
    }
}

sub _close
{
    my $self = shift;
    my $mode = shift || undef;
    my $pid  = $self->{pid} || return undef;

    # --*-- Stop control Watcher --*-- #
    $self->{evr}->cancel if $self->{evr};
    $self->{evt}->cancel if $self->{evt};
    # --*--       Some Info       --*--#
    print  $main::DBG "$self->{prompt}I try to kill process $pid ...\n"
            if ($main::DEBUG & 1);

    #print "\n>>> mode : $mode :: ($self->{last}[0])$self->{last}[1]\n";
    if ($self->{sock})
    {
        my $sock =  $self->{sock};

        if ($sock->opened)
        {
            if (defined $mode && $mode eq 'NORMAL')
            {
                #print "\n>>> $mode :: exit\n";
                my $data = "exit;\n";
                my $blksize = length($data);  
                my $rv   = syswrite($sock,$data,$blksize); 
                #$sock->sysread($_,150);
                #print ">>> read :: $_\n";
                sleep 0;
                waitpid($pid,0);
                #$sock->printflush( "exit;\n");
                #wait until the isql finishes
                #$self->read_data_from_isql;
            }
            $sock->close if $sock->opened;
        } 
    }; 
    #if (defined $mode && $mode eq 'NORMAL')
    if ($self->{pid})
    {
        #kill 'TERM',$pid;
        #print ">>> $self->{id_key} :: loader pid = $pid\n";
        {
            open(KILL_SH,"ps -ef | grep $pid |");
            while (<KILL_SH>)
            {
                s/^\s+//;
                my @col = split /\s+/, $_;
                if ($col[2] eq $pid )
                {
                    kill '9', $col[1];
                    #print ">>> @col\n";
                }
            }
            close(KILL_SH);
        }
        kill '9',$pid;
        sleep 0;
        waitpid($pid,0);
    }
};

sub _err_pipe
{
    my $self = shift;
    my $mode = shift || '';

    #print "\n>>> ERR PIPE CALLED....\n";
    #print "\n>>> $self->{last}[0] :: $self->{last}[1]\n";
    if ($mode !~ /DISCARD/)
    {
        #splice( @{$self->{IN}},0,0,$self->{last}) if defined $self->{last};
    }
      
    # -*- Hm I can't Do my work becouse Cant connect to ALTIBASE -*- ##
    if ( $self->_hang_up < 0 )
    {
        #print $main::ERR   $self->{BufferIN} . "\n";
        if ( $self->{id_key} eq 'P0' )
        {
            print $main::ERR "\n[ALERT] $self->{id_key} : Can't connect to Server\n";
            $main::ex->{warning} = "Can't connect to Server\n";
            $main::ex->abrupt_exit();
            #&main::_exit(255);
        }
        else
        {
            shift @{$self->{IN}} if @{$self->{IN}};
            #$self->_close;
            $self->{driver_ready} = 'N';
            $self->sw_block if _is_block($self->{STATE});
            $self->_mark_start_tdx_item('R');
            $self->_push_out("$self->{prompt} Connect To Server Fail");
            $self->_mark_end_tdx_item();
            $mode = 'DISCARD';
            #$self->_open;
        }
    };
    $self->{new_stmt} = 'Y';
    $self->sw_block if _is_block($self->{STATE});
    if ($mode !~ /DISCARD/)
    {
        delete($self->{last});
        ### cancel output of previous sql stmt
	$self->_rollback_out;
=for testing rollback
        if ($self->{OUT}[@{$self->{OUT}}-1] !~ /PROCESS/)
        {
            $self->_pop_out;
            #pop @{$self->{OUT}};
        }
=cut
    }
};


sub abrupt_exit
{
    my $self = shift;
    my $mode = shift || '';

    #print Dumper $self; # if $main::DEBUG & 1;
    $self->_close();
    if ($mode ne 'OK' && $self->{last})
    {
        print $main::ERR " $self->{prompt}($self->{last}[0]) $self->{last}[1]\n";
        print $main::REP " $self->{prompt}($self->{last}[0]) $self->{last}[1]\n";
        $main::tb->ok_sector($self,$self->{Sector_Key}) if ( $self->{ok_sector});
    }
    if ($mode eq 'SIGINT')
    {
        my $inx;
        print $main::ERR ">>> Server dead : $self->{server_dead} \n";
        print $main::ERR ">>> Auto restart: $self->{auto_restart} \n";
        print $main::ERR ">>> Driver ready: $self->{driver_ready} \n";
        print $main::ERR ">>> STATE       : $self->{STATE} \n";
        print $main::ERR ">>> Post list   : ";
        for ($inx=0; $inx < @{$self->{_p_history}}; $inx++)
        {
            print $self->{_p_history}[$inx] . " ";
        }
        print "\n";
        print $main::ERR ">>> Wait list   : ";
        for ($inx=0; $inx < @{$self->{_w_list}}; $inx++)
        {
            print $self->{_w_list}[$inx] . " ";
        }
        print "\n";
        print $main::ERR ">>> STATE       : $self->{STATE} \n";
        print $main::ERR ">>> _SW         : $self->{_SW} \n";
        print $main::ERR ">>> _state      : $self->{_state} \n";
        print $main::ERR ">>> Last data   : $self->{last_data} \n";
    }
}
    
sub _get_time_tick
{
    my $self = shift;
    my @tm  = gettimeofday();  
    return $tm[0] . '.' .$tm[1];
}

# -* Time Out callback by default *- #
sub _timeout_cb 
{
    my $self = shift;
  
    my $mess  = sprintf "%4.4sTimeout I/O %7.4f sec. Exceed;",
                         $self->{prompt},$self->{evt}->interval();

    $main::DBG->print("$mess\n") if $main::DEBUG & 1;
    #print ">>> timeout : " . $self->_get_time_tick;
    # -- this point fix TimeStamp fo PWAIT timeout 
    if ( $main::ex->{is_parallel} eq 'Y' )
    {
        #print ">>> timeout :: $self->{prompt} $self->{q_out}\n";
        #print Dumper $self->{time_stmp};
        my $idx = $self->{q_out} ; # rollback for index
        my @tm  = gettimeofday();  
        #$self->{time_stmp}{$idx}{time_stmp} = $tm[0] . '.' .$tm[1];
        $self->{time_stmp}{$idx}{time_stmp} = $self->_get_time_tick;
    }
    $self->_push_out($mess);
    # -* ---------------------------------------------------------
  
     
    $self->sw_wait   if _is_wait($self->{STATE}); 

    # Set process timeout back after wait;
    $self->{evt}->stop;

    # -* Clear WAIT list
    splice(@{ $self->{_w_list} },0,@{ $self->{_w_list} });

    $self->do_next;
};    

DESTROY 
{
    my $self = shift; 
    $self->{evs}->cancel if $self->{evs};
    $self->{evt}->cancel if $self->{evt};
    $self->_close;   
    #!   foreach (keys %{$self}){delete $self->{$_}};
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



sub _do_synck ($) 
{
    my $self =shift;
    print $main::DBG "$self->{prompt}isql syn\n" if $main::DEBUG & 2;
}

sub _do_wait 
{ 
    my $self = shift;
    unless (  _is_wait($self->{STATE}))
    {
        my $last_cmd = $self->{last}[1] || '';
        # rewrite time stamp for PWAIT by switch off wait timestamp       
        if ($main::ex->{is_parallel} eq 'Y' &&
            $last_cmd =~ /PWAIT/ )
        {
            #print Dumper $self;
            my $idx = $self->{q_out};

            if(defined( $self->{time_stmp}{$idx}))  
            {
                $self->{time_stmp}{$idx}{time_stmp} = $self->_get_time_tick;
            }    
        }
        $self->do_next ;
    };

    if ( $main::DEBUG & 2) 
    {
        print $main::DBG ( _is_wait($self->{STATE})) 
            ? "$self->{prompt}isql w+\n" 
            : "$self->{prompt}isql w-\n";
     };

    #d!  print Dumper \%ExecSQL::wait_list;
    # -* Take reference to Post list
    my $ref_post = $self->{_p_list};     

    unless ( _is_wait($self->{STATE})  )
    {
        splice(@$ref_post,0,@$ref_post); # Clear memory !! not drop reference
    }
};

sub do_next{$_[0]->_do_block(1)};

sub _do_block 
{ 
    my $self =  shift;
    my $next =  shift;
    
    if ($main::DEBUG & 2)
    {
        printf  $main::DBG  "\$%2s>|%12.4f|%.4f|> %3s",
              $self->{id_key},$self->{'TimeOP'},$self->{'TimeElapse'},
              _is_block($self->{STATE})? "b+\n" :"b-\n";
     };                             
 
     #print "\n>>> $self->{prompt} next value = $next\n";
     #print "\n>>> $self->{prompt} self->{STATE} = $self->{STATE}\n";
    if( ($self->{AutoDo} or $next ) 
        and ($self->{STATE} == 2 ) )
    {
        $main::Elapse += $self->{'TimeElapse'};

     
     
        $^W = 0; # Some test without sql make warning     
        # Point for execute all '--+' statment

        my $line = $self->{IN}[0][0];
        my $cmd  = $self->{IN}[0][1];
        while ( $cmd=~/^\s*\-\-\+\s*/ ||
                $cmd=~/^\s*\-\-\#/ ||
			    $cmd=~/^\s*$/ 
			  )
        { 
            #print "\n>>> $self->{prompt} $line: [$cmd]\n";
            my $sys_cmd = $';
            # remove command from FIFO and set last_cmd (for Polish notation)
            print $main::DBG  "$self->{prompt}($line)$self->{q_cmd}:$'\n"   if ( $main::DEBUG & 4);
            #print $main::DBG  "\n$self->{prompt}($line)$self->{q_cmd}:$'\n" ;
            $self->{last} = shift(@{$self->{IN}});
            if ($cmd =~ /^\s*\-\-\+\s*/)
            {
                chomp($sys_cmd);
                $self->_do_cmd($sys_cmd); 
                # -* Check for lock execute process into WAITE state *- #
                return 0 if _is_wait($self->{STATE}) ;
            }
            else
            {
                chomp($cmd);
                $self->_push_out($cmd);
                sw_queue($self) if ( $#{$self->{IN}}+1 xor _is_queue($self->{STATE}) );
            }
	    $self->{rollback_point} = $self->{q_out};
            last unless defined $self->{IN}[0];


            # -* check State of connection after command *- #
            #++$self->{q_cmd};
            $cmd  = $self->{IN}[0][1];
            $line = $self->{IN}[0][0];
        };
        
        if ( ( $main::DEBUG & 4) and $self->{IN}[0] )
        {
            print $main::DBG "$self->{prompt}($line)$self->{q_cmd}:$cmd";
        };

        # PRINT OUT the current stmt and time
        if ( $main::cfg->{Verbose} && $main::cfg->{BottomMsg} )
        {
            $main::DIS->printflush("\r" . " "x68 . "\r");
            my $cur_stmt = $cmd;
            chomp($cur_stmt);
            my $progress = sprintf("\[%d%\]", $main::tp->get_progress());
            my $prompt_str = sprintf("$progress\[$main::ex->{TestCase}{Name}($self->{last}[0]):Q\] $self->{prompt} %s",
                                      substr($cur_stmt,0,44-$main::ex->{TestCase}{NameLength}));   
            $prompt_str =~ s/\t/ /g;
            $main::DIS->printflush("\r$prompt_str\r");
        }
        if (@{$self->{IN}} && 
            $self->{auto_restart} eq 'Y' &&
            $self->{driver_ready} eq 'N')
        {
            #print $main::DIS "\n>>> now start stmt\n";
            #print $main::DBG "$self->{prompt}($line)$self->{q_cmd}:$cmd";
            my $t_STATE = $self->{STATE};
            my $t_state = $self->{_state};
            $self->_open;
            if ($self->{driver_ready} eq 'Y')
            {
                $self->{STATE} = $t_STATE;
                $self->{_state} = $t_state;
            }
            $self->{server_dead} = 'N';
        }
        $^W = 1;    
        if (@{$self->{IN}}  && $self->{driver_ready} eq 'Y')
        {
            delete $self->{last};
            $self->{last} = shift @{$self->{IN}};
	        push @{$self->{last_queue}}, $self->{last};
            $self->_send();
        }

        ++$self->{q_cmd};
    }
        else 
    {
        ################################     
        # -* Time stamp  index file *- #
        # -*    SEND to isql part   *- #
        ################################     
=for debugging
        do
        {
            my (%time_stmp); 
            $time_stmp{type}='S';

            # -* Experemental  point $idx *- #
            my $idx =  $self->{q_out};
        
            $time_stmp{time_stmp} = $self->_get_time_tick;
            $self->{time_stmp}{$idx} = \%time_stmp;
        
        };# end do
=cut

    }; 

    #print "\n>>> $self->{prompt} finalize?:: self->{STATE} = $self->{STATE}\n";
    # FINALIZE FOR A TC 
    # -*-  READY HANLE STATE -*- #
    unless ($self->{STATE}) 
    {
        ### Make LST file - it not clean only prototype *- #
        if ( $main::cfg->{'LST'} )
        { 
            # $self->_make_lst;
        }
        else
        {
            #--$self->{q_out};
            if ( defined($self->{Sector_Key})  )
            {
                $self->ts_SECTOR( { prm => $self->{Sector_Key} });
            };
        }
       
        # Use for main process Jast number of node finish   
    
        push @{ $self->{_p_list} },( $self->{id_key} eq 'P0' ) 
                ? $self->{q_pwait}++ 
                : $self->{id_key}; 

        $main::ex->check_wait;
        # STROB     
        #shift  @{ $self->{_p_list} };    
    
        $self->{OutIndex}=0;
        $self->{try_cnt_connect}=0;
        $self->{q_cmd}=0;   
        $self->{q_prc}=0;
        $self->{driver_ready} = 'N';
        #print "\n>>> now close isql\n";
        $self->_close('NORMAL');     
        delete $self->{pid};
        delete $self->{last};
        delete $self->{env};
        &{$self->{callback_ready}};
    };# UNLESS READY
};


sub callback_ready 
{
    my $self= shift ;
    print $main::DBG "isql Queue of cmd iSQL empty I'am READY \n "
};


sub _send 
{
    my $self = shift;

    #print Dumper $self;

    # New generation of send : 
    #   use send_buff for roll-back in breack connection case

    my $data =  $self->{last}[1];

    #print "\n";
    #print Dumper $self->{last};
    #print ">>> pre :: $data\n";
    # Expand Environment Variables
    my $var_name;
    while ( $data =~ /\$\{\w+[\@]*[\w]*\}/ )
    {   
        my $pre_str = $`;
        my $post_str = $';
        $_ = $&;
                                            
        $var_name = $&;
        $var_name =~ s/\$\{//;
        $var_name =~ s/\}//;
        if ($var_name =~ /\@/)
        {
            my $property = $`;
            my $host     = $';
            my $server = $main::tp->get_nearest_scope($host,'server_list');

            if (defined $server)
            {
                if (defined $server->{$property})
                {
                    my $value = $server->{$property};
                    if ($property =~ /ALTIBASE_REPLICATION_PORT_NO/)
                    {
                        my $port_no = $server->{ALTIBASE_PORT_NO};
                        if ($port_no =~ /%PORT_NO/)
                        {
                            $port_no = $self->_getPortNo($main::cfg->{PORT_NO}, $');
                        }
                        my $repl_port_no = $self->_getReplPortNo($port_no);
                        $value = $repl_port_no;
                    }
                    $data = $pre_str . $value . $post_str;
                }
                else
                {
                    print $main::ERR "\n [ERROR] There is no property for $property at $host\n";
                    $main::ex->{warning} = "\n [ERROR] There is no property for $property at $host\n";
                    $main::ex->abrupt_exit();
                }
            }
            else
            {
                print $main::ERR "\n [ERROR] There is no name for $host\n";
                $main::ex->{warning} = "\n [ERROR] There is no name for $host\n";
                $main::ex->abrupt_exit();
            }
        }
        else
        {
            ### BUGBUG:: To make the env variables on server context & SET_ENV list be usable....
            /\w+/;
            $data = $pre_str . $ENV{$&} . $post_str;
        }
    }
    #print ">>> post :: $data\n";

    my $sem  = $self->{STATE};
    # Filter Queue for internal command 
    #   - return only command for pass to process

    # ! $data=&{$self->{callback_filter}}($self,$data);

    # -*- sckip if nothing to send -*- #
    return undef  if (not defined($data) or not($data)  );

    #!  -* for Solaris OS *- #
    #! -* in Solaris & Linux different out on TTY device - strange !!?
    #!  if ($^O eq 'solaris') 
    #!   {
    #!  $_=$self->{prompt} . $data;  
    #!      chomp; push @{$self->{OUT}},$_;
    #!   };

    if (defined $self->{last})
    {
        my $stm;
            if ($self->{last}[1] =~ /^\s*\-\-/ ||
                $self->{last}[1] =~ /^\s*$/)
            {
                $self->{last}[1] =~ s/^\s+//;
            $stm = $self->{last}[1];
            }
            elsif ($self->{new_stmt} eq 'Y')
            {
                $self->{last}[1] =~ s/^\s+//;
                $self->{length_indent} = 0;
		if ($&)
		{
                    $self->{length_indent} = length($&);
		}
                $stm = $self->{prompt} . $self->{last}[1];
            }
            elsif ($self->{new_stmt} eq 'N')
            {
                $self->{last}[1] =~ s/^\s{$self->{length_indent}}//;
            my $indent = length($self->{prompt});
            $stm = " "x$indent . $self->{last}[1];
            }
            else
            {
            $stm = $self->{prompt} . $self->{last}[1];
            }
            if (defined $stm)
            {
                chomp($stm);

                $self->_push_out($stm);
            }
        if ( $main::ex->{is_parallel} eq 'Y')
        {
                my (%time_stmp); 
                $time_stmp{type}='S';
    
                # -* Experemental  point $idx *- #
                my $idx =  $self->{q_out};
            
                $time_stmp{time_stmp} = $self->_get_time_tick;
                ###!!!###
                $time_stmp{cmd} = $data;
                $self->{time_stmp}{$idx} = \%time_stmp;
        }
    }

    sw_block($self) unless _is_block($sem); # BLOCK when send
if ($self->{server_dead} eq 'N')
{
    my $blksize = length($data);  
    my $sock = $self->{sock};
    my $rv   = syswrite($sock,$data,$blksize); 
     
    #print $main::ERR ">>> send : $data ($blksize)\n";
    unless (defined $rv)
    {
        if ( $self->{id_key} eq 'P0' )
        {
            print $main::ERR 
                "\n$self->{prompt}Can't send an sql stmt to Altibase server.\n";
                
            $main::ex->{warning} = "\n$self->{prompt}Can't send an sql stmt to Altibase server.\n";
            $main::ex->abrupt_exit();
            #&main::_exit(255);
        }
        else
        {
            #$self->abrupt_exit('OK');
            $rv = -1;
        }
    };
    $self->_err_pipe unless ( $rv == $blksize ||  $! == POSIX::EWOULDBLOCK );
}

    $self->{result_receiving} = 'N';
    sw_queue($self) if ( $#{$self->{IN}}+1 xor _is_queue($self->{STATE}) ); 
}

sub _do_queue 
{ 
    my $self = shift;

    if ($main::DEBUG & 2)
    {
        print $main::DBG ( _is_queue($self->{STATE})) 
                ?   "$self->{prompt}isql q+\n"
                :   "$self->{prompt}isql q-\n" ;
    };

    if ( _is_queue($self->{STATE}) and not ($self->{id_key} eq 'P0') )
    {
        # $main::ex->set_wait_process($self->{id_key},['P0']) 
        #       if  _is_queue($self->{STATE});
    } 
};


# -*- Handle subroutine input stream from process -*- #

sub callback_read_handle ($$)
{
    my $self   = shift; 
    $_ = shift;

    my $in_buffer = $self->{BufferIN};
    my $current_in = $_;

    ## Control point for do next command from queue ##
    # Very difficult code !!! isql utilite is craze !!!
    # it can make any sequence of output 

    #print $main::ERR ">>> read :: in buffer :: $in_buffer\n";
    #print $main::ERR ">>> read :: current :: $current_in\n";
    #$main::ERR->flush();

    $_ = $in_buffer . $current_in;
    #print $main::ERR ">>> $self->{id_key} con :: $_\n";

    #  -*-  Send Event for Execute SQL STATMENT  -*- #        
    if ( $main::ex->{is_parallel} eq 'Y' &&
         $self->{result_receiving} eq 'N'  && 
         $self->{evr}->cbtime > 0 )
    {
        my (%time_stmp);
        $time_stmp{type}='R';

        # -* Experemental  point $idx *- #
        my $idx =  $self->{q_out} + 1; 
   
        #print ">>> $self->{id_key} :: " . $self->{evr}->cbtime . ":: $_\n";
        $time_stmp{time_stmp} = $self->_get_time_tick;
        $self->{time_stmp}{$idx}=\%time_stmp;
      
        $self->{result_receiving} = 'Y';
    }

    if (/$self->{ExpectFirst}/)
    {
        $self->{new_stmt} = 'Y';
	$self->{rollback_point} = $self->{q_out};
        delete $self->{last_queue};
    }
    else
    {
        $self->{new_stmt} = 'N';
    }
    if (s/$self->{Expect}//)
    {
        #print $main::ERR ">>> con :: $_\n";
        #print ">>> ok I got expected ...\n";
        # -* copy to OUT command for lst *- # 
      
        # Estimate real timing;  
        # $self->{TimeElapse}=tv_interval($self->{TimeOP}); 

        my $t_cb =  $self->{evr}->cbtime;
        $self->{TimeElapse} = $t_cb - $self->{TimeOP}; 
        $self->{TimeOP}     = $t_cb;

        # -*- Loop back post Event decriment  -*- #
        # switch trigger State to UNBLOCK
        $self->sw_block if  _is_block($self->{STATE});
        ### BUGBUG
        #$_ = delete($self->{BufferIN}).$_;
        #delete($self->{BufferIN});
        $self->{BufferIN} = "";

        return unless ($_);
        return if $self->{_skip};

        #### BUGBUG 
        #s/\r//g;

        my @_data = split /[\r\n]/,$_;

        while ( @_data )
        {
            $_ = shift @_data;
            $self->_push_out($self->{out_string_prefix} . $_) if $_;
        };
    } # END IF 'Then'  EXPECT
    else 
    {
        return if $self->{_skip};
        my $t_ln = "";
        if ( /\n$/ )
        {
            $t_ln = "\n";
        }
        my @_data = split /[\r\n]/,$_;
        while ( @_data > 1)
        {
            $_ = shift @_data;
            $self->_push_out($self->{out_string_prefix} . $_ ) if $_ ;
        };
        $self->{BufferIN} =(shift @_data) . $t_ln;
    }; 
};





################################################################################
# Filter Handler for separate command from SQL statmant #
# -*- by default it do nothing and return back stmt     #

sub get ($) {
   my $self = shift;
   if (wantarray)
   { 
     my @ret;
     while ( $_=shift @{$self->{OUT}}) 
       { 
        push @ret,$_;
       };
     return @ret;
   }
   else
   { 
      $_= shift @{$self->{OUT}}; 
      return $_; 
   };
};


# -*- Print to STDOUT isql output -*- #


# -*- Print to STDOUT isql output -*- #

sub _print ($$)
 {
  my     $self = shift;
  my     $fd   = shift ;
  while (defined($_= $self->get))
   {
    s/^\. //;
    print $fd $_."\n";
   };
 }

#
sub do_stmt ($$) {
   my $self = shift;
      $_    = shift;
   push @{$self->{IN}},$_."\n";
    # -*- initialize q_cmd and generate Event for execute -*- #
      $self->do_next;
    # -*- set off flag queue  -*- #
      $self->{STATE} |= QUEUE  unless ($self->{STATE}&QUEUE);    
#
   
};

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
sub start 
 {
    my $self = shift;
    
# -* old finish   push @{$self->{IN}},"--+SECTOR 0;\n"; 
#!!  $self->{Sector_Key} = 0; # Firs sector all 
     $self->{Sector_Key} = undef;
# -* Nothing to do !! if 
#    unless ( $#{ $self->{IN}} + 1 )
#     {
#    #!        &{$self->{callback_ready}}();
#       return 0;
#     };
   
 $self->{STATE} = 4;
 $self->{_state} = 4;
 delete($self->{last});
 $self->sw_queue;
 $self->{driver_ready} = 'N';
}


# -*-       Set Auto execute mode for isql stmt            -*- #
sub do_auto ($$) 
 {
 my $self = shift;
 my $mode = int shift;
    $self->{AutoDo}= $mode ? int 1 : int 0; 
#    sw_next($self) if $mode > 1;
 }


#


sub callback_cmd
{
    my $self = shift;
    my $data = shift;

    return undef unless $data;
    $self->_do_cmd($') if ( $data=~/^\-\-\+*\s*/);

    return $data; 
};


# For multi process test case
sub _make_out ($)
{  
    my $self = shift;
    my $fd   = $main::ex->{out_fd} || return 0;

    $fd->open() unless      $fd->opened;

    $self->_print($fd); 
    $fd->flush;

    delete $self->{OUT};
};

sub _make_lst ($)
{  
    my $self = shift;
    my $fd   = $main::ex->{lst_fd} || return 0;

    $fd->open() unless      $fd->opened;
    $self->_print($fd); 
    $fd->flush;

    print $main::DBG "$self->{prompt}:$main::ex->{TestCase}{Name} - lst compled Elapse isql Time $main::Elapse \n";    
};

sub _mark_start_tdx_item
{
    my $self = shift;
    my $type = shift;

    if ( $main::ex->{is_parallel} eq 'Y' )
    {
        my (%time_stmp);
        $time_stmp{type}=$type;
        $time_stmp{start_idx} =  $self->{q_out}+1;
        $time_stmp{time_stmp}    = $self->_get_time_tick;
        $self->{tmp_tdx} = \%time_stmp;
    }
}

sub _mark_end_tdx_item
{
    my $self = shift;

    if ( $main::ex->{is_parallel} eq 'Y' )
    {
        $self->{tmp_tdx}{end_idx} =  $self->{q_out};
        $self->_make_tdx_item();
    }
}

sub _make_tdx_item
{
    my $self = shift;
    $self->{time_stmp}{$self->{tmp_tdx}{start_idx}} = $self->{tmp_tdx};
}

sub _make_tdx 
{  
    my $self = shift;
    my $base = shift||0; 
    my $fd   = $main::ex->{tdx_fd} || return 0;
       $fd->open() unless $fd->opened;

    my $p_key = $self->{id_key};
    my $offset;
    my $str;

    #print Dumper $self;
#    if ($p_key eq 'P1')
#    {
#        $base++;   #### Strange, but it is needed!!!
#    }
    for  $offset (sort {$a <=> $b} keys %{ $self->{time_stmp} })
    { 
		my @e_time = split /\./, $self->{time_stmp}{$offset}{time_stmp};
		my $time_str = sprintf("%d.%06d", $e_time[0], $e_time[1]);
        $str = int($base + $offset)
              . '|' . $self->{time_stmp}{$offset}{type}
              . '|' . $self->{id_key}
              . '|' . $time_str;
	      #. '|' . $self->{time_stmp}{$offset}{time_stmp}; 
        print $fd $str,"\n";
        #print  ">>>",$str,"|",$self->{OUT}[int $offset],"<<<\n";
    };

    delete $self->{time_stmp};

    # Return offset for next process #    
    #print "\n>>>$self->{prompt} base = $base qout = $self->{q_out}\n";
    return $self->{q_out} + $base ;
};

sub _getPortNo
{
    my $self    = shift;
    my $port_no = shift;
    my $no      = shift;

    return $port_no + $no*1000;
}

sub _getShmDbKey
{
    my $self        = shift;
    my $port_no   = shift;

    return $port_no;
}

sub _getReplPortNo
{
    my $self        = shift;
    my $port_no   = shift;

    return $port_no + 5000;
}

########################################
#
# Command Handler for --+ 
#
########################################

sub _do_cmd 
{
    my $self = shift;
    my $cmd  = shift;

    ### It replace +" into ' reversely because Parser replaced ' into +"
    ###     in order to avoid perl's misunderstanding...
    #print "\n>>> passed cmd = $cmd\n";
    if ($self->{new_stmt} eq 'Y')
    {
        $cmd =~ s/^\s*//g;
    }
    $cmd =~ s/\+"/'/g;
    $cmd =~ /(^\w+)\s*(\'[\s\S]+\'|[\S\s]+)?\s*;/;    
    my $ts_command = $1;
    $cmd = '$self->ts_'.$ts_command.'($prm);';
    my $_cmd = $1;     
     
    my $prm = 
    { 
        prm  => defined($2)? $2 : '',
        desc => $' || '',
    };

    if ($ts_command =~ /SECTOR/)
    {
        if ( $prm->{prm} =~ /;/ )
        {
            $prm->{prm} = $`;
            $prm->{desc} = $' . ';' . $prm->{desc};
        }
    }


    #print "\n>>> cmd = $cmd\n";
    #print "\n>>> prm = $prm->{prm}\n";
    #print "\n>>> desc = $prm->{desc}\n";
    # -* Check CODE procedure exist ?? *- #
 
    no strict 'refs';
    if ( defined(*{'isql::ts_'.$ts_command}{CODE}) )    
    {
        ########################################
        #    Time STAMP set For COMAND 
        # -* Time stamp  index file *- #
        # -*    COMMAND from isql part   *- #
        if ( $main::ex->{is_parallel} eq 'Y' )
        {
            my (%time_stmp);
            $time_stmp{type}='C';

            # TimeStamp point $idx ! but for PWAIT rewrite on _do_wait() #
            my $idx =  $self->{q_out} + 1;
            if ($self->{id_key} ne 'P0' && 
                $ts_command eq 'SECTOR' && $prm->{desc} =~ /BY ATC/)
            {
                $idx += 2;
            }
            $time_stmp{time_stmp}    = $self->_get_time_tick;
            $time_stmp{cmd} = $_cmd;
            #$time_stmp{cmd} = $self->{last}[1];
            $self->{time_stmp}{$idx} = \%time_stmp;
            #print ">>> $self->{prompt} $time_stmp{cmd}:: " . $self->{evs}->cbtime . "\n";
        }

        ########################################
        eval $cmd;  
        print $main::ERR "\nisql>",$@ if $@;
    }
    else 
    {
        print $main::ERR "\nWarning $self->{prompt} Wrong command!!!  ( $self->{last}[0] : $self->{last}[1] )\n";
        #print $main::ERR "WARN \$$self->{id_key}> I haven't handle for $cmd!\n";
    };

    use strict;  
    sw_queue($self) if ( $#{$self->{IN}}+1 xor _is_queue($self->{STATE}) );
};

sub ts_DUMPER 
{
    my $self = shift;
    my $prm  = shift || { prm => ''};
    
    print Dumper $self;
}

sub ts_SECTOR 
{
    my $self = shift;
    my $prm  = shift || { prm => '', desc => ''} ;
    my $ign_sec;
# -* Change That in concurent control version *- #
    my ($sec,$mod)  = split /\s*[,]\s*/,$prm->{prm},2;           

    print  $main::DBG "$self->{id_key}> SECTOR+ $sec \n"  if $main::DEBUG & 2 ;

    #print "\n>>> prm    = $prm->{prm}\n";
    #print "\n>>> sector = $sec\n";

    if (defined($mod) and $mod =~ /IGNORE/)
    {
        $ign_sec = $sec;
        undef $sec;       
    };

    # -* excange var and Test SECTOR  *- #    
    ($sec,$self->{Sector_Key}) = ($self->{Sector_Key},$sec) ;

    if (!$main::cfg->{LST})
    {
        #++$self->{q_out};   
        if ( defined($sec)) # not NULL (defined)
        {
            $main::tb->ok_sector($self,$sec) if ( $self->{ok_sector});
        }
    }

    if (@{$self->{IN}} && $self->{last}[1] =~ /\-\-\+\s*SECTOR/)
    {
            if (defined $prm->{desc} && $prm->{desc} =~ /BY ATC/)
            {
        $self->_push_out( " ");
        $self->_push_out( "+". "-"x70 ."+");
                chomp($self->{last}[1]);
                $self->_push_out($self->{last}[1]);
        $self->_push_out( "+". "-"x70 ."+");
        $self->_push_out( " ");
            }
            else
            {
                chomp($self->{last}[1]);
                $self->_push_out($self->{last}[1]);
            }
    }

    $main::tb->ignore_sector($ign_sec,'') if $ign_sec;   
    return 1; # do next --+ command if exist;
};

sub ts_IGNORE 
{ 
    my $self = shift;
    my $prm = shift;

    $main::tb->ignore_sector($self->{Sector_Key},$prm->{desc});
    $self->{Sector_Key} = undef;     

    return 1; # do next --+ command if exist;      
}

sub ts_APPEND_LST
{
    my $self = shift;
    my $prm = shift;

    #print ">>> $prm->{prm} :: $prm->{desc}\n";
    $self->_push_out("--+APPEND_LST $prm->{prm};");
    $self->_mark_start_tdx_item('R');
    my $fd = new IO::File $main::ex->{TestCase}{path}.$prm->{prm}, 'r';
    unless ($fd)
    {
        $self->_push_out($self->{out_string_prefix} . ">>> [$prm->{prm}] NOT FOUND <<<");
        $self->_mark_end_tdx_item();
        return 1;
    }
    my $max_cb_tm;
    $self->_push_out($self->{out_string_prefix} . ">>> [$prm->{prm}] BEGIN <<<");
    while (<$fd>) 
    {
        chomp;
        # windows cr remove
	    if ($OSWinFlag) 
        {
            
            $_ =~ s/\r$//g;
            
	    }

        if (length($_) == 0)
        {
            $_ = " ";
        }
        $self->_push_out($self->{out_string_prefix} . $_);
    }
    $fd->close;
    $self->_push_out($self->{out_string_prefix} . ">>> [$prm->{prm}] END <<<");
    $self->_mark_end_tdx_item();

    return 1;
}


sub ts_PRINT
{  
    my $self =  shift;
    my $prm =  shift;

    $self->_push_out($self->{out_string_prefix} . $prm->{prm});
    #print  $main::DBG $prm->{desc}."\n" 
    #if $prm->{prm} >= $main::cfg->{PrintLEvel};
    return 1; # do next --+ command if exist;      
}

# -* Handler for isql error message analise jast todo *- #
sub ts_PROCESS
{
    my $self = shift;
    my $prm =  shift;
    $self->_push_out(
        $self->{prompt}.'--+PROCESS '.$prm->{prm}.';'.$prm->{desc});
}



sub ts_AUTO 
{
    my $self = shift;
    my $prm = shift;   

    if ($main::cfg->{Shell})
    {
       $self->do_auto($prm->{prm});
       $self->{evr}->timeout(0);
    };

    print $main::DBG "esql autodo $self->{AutoDo}" if $main::DEBUG ;
    return 0; # not do next --+ command if exist;
};

sub ts_SKIP
{
    my $self = shift;
    my $prm  = shift;

    $self->{_skip} = 1 if ( $prm->{prm} =~ /[\s\,]*BEGIN[\s\,\;]*/);
    $self->{_skip} = 0 if ( $prm->{prm} =~ /[\s\,]*END[\s\,\;]*/);
    $self->_push_out( '--+SKIP '.$prm->{prm}.';'.$prm->{desc}   );     
    return 1; # do next --+ command if exist;
};

#####################################################################
#     -*         Control Multi Process  Mode !!         *-                     #
sub ts_POST
{
    my $self= shift;
    my $prm = shift;
    my @post = grep /^\w+$/,split /[,]/,$prm->{prm};

    # -* /Post command for string posting *- #
    map{push @{ $self->{_p_list} },$_; } @post;

    #d! print "WAIT>$self->{id_key}>", Dumper \%ExecSQL::wait_list;
    #d! print "POST>$self->{id_key}>", Dumper \%ExecSQL::post_list;

    $main::ex->check_wait();
    # STROB signal
    shift  @{ $self->{_p_list} }; 
 
    #d! print "WAIT<$self->{id_key}<", Dumper \%ExecSQL::wait_list;
    #d! print "POST<$self->{id_key}<", Dumper \%ExecSQL::post_list;

   $self->_push_out($self->{prompt}.'--+POST '.$prm->{prm}.';'.$prm->{desc});
    print $main::DBG "$self->{prompt}post $prm->{prm}\n"  
            if ($main::DEBUG & 1); 
    return 1; # do next --+ command if exist;    
};

sub ts_WAIT
{
    my $self= shift;
    my $prm = shift;

    #   $main::ex->drop_post_wait([$self->{id_key}]);
     
     $self->_push_out($self->{prompt}.'--+WAIT '.$prm->{prm}.';'.$prm->{desc});
    my @w = split /\s*[,]\s*/,$prm->{prm};

    # -* set timeout parametr *- # 
    if ($w[$#w] =~/^\d*\.?\d*$/)
    { 
        my $to =  pop @w;
        if (defined ($self->{evt}) )
        {
           if ($to)
           {
               $self->{evt}->interval($to);
               $self->{evt}->again;
           }
           else
           {
               $self->{evt}->stop;
           }
        }
    };    

    # -* difference wit process - NOT STROB *- #
    # Clear memory !! not drop reference  
    splice(@{$self->{_w_list}},0,@{$self->{_w_list}});
    map{push @{ $self->{_w_list} },$_; } @w;    
    $main::ex->check_wait();
  
        
    $self->sw_wait;
    #!! $main::ex->set_wait_process($self->{ id_key},\@w);

    return 1; # do next --+ command if exist;
};


sub ts_PWAIT
{
    my $self = shift;
    my $prm = shift;
    #
    my @w;

    $self->_push_out($self->{prompt}.'--+PWAIT '.$prm->{prm}.';'.$prm->{desc});
    @w = split /\s*[,]\s*/,$prm->{prm};  
    
    # -* set timeout parametr *- #
    if ($w[$#w] =~/^\d*\.?\d*$/)
    {
        my $to =  pop @w;
    if (defined ($self->{evt}) )
    {
           if ($to)
           {
               $self->{evt}->interval($to);
               $self->{evt}->again;
           }
           else
           {
               $self->{evt}->stop;
           }
    }
    }

    #  Drop previose STATE in post  automaticly by _do_wait event
    unless (@w)
    {
        @w = keys %{$main::ex->{iSQL_pool}};      
        @w = grep !/P0/
                && ($self->{q_pwait} >= $main::ex->{iSQL_pool}{$_}{q_pwait} )
                # This is for same NODE
                ,@w;
    };

    # Set list for wait
    map {push @{$self->{_w_list}},$_;}@w;

    print  $main::DBG ">PWAIT:$self->{q_pwait} |@w;\n" if $main::DEBUG & 4;

    #print ">>> before : " . $self->{evs}->cbtime;
    $self->sw_wait unless (_is_wait($self->{STATE}));
    # Check READY post for myself
    #!  $main::ex->check_wait;

    push @{ $self->{_p_list} }, $self->{q_pwait};  # Post
    push @{ $self->{_p_history} }, $self->{q_pwait};  # Post
                      
    ++$self->{q_pwait};
           
    #d!           print "WAIT$self->{id_key}>", Dumper \%ExecSQL::wait_list;
    #d!        print "POST$self->{id_key}>", Dumper \%ExecSQL::post_list;

    $main::ex->check_wait;              # Check for all WAIT

    #!JAST STROB
    #!     shift  @{ $self->{_p_list} };                  # STROB Signal mode
    #d!           print "$self->{id_key}WAIT>", Dumper \%ExecSQL::wait_list;
    #d!           print "$self->{id_key}POST>", Dumper \%ExecSQL::post_list;
};

# -* Special internal command  WAIT  PW_P & PW_X         *- #
# -* for PW_P - pwait and post - PW_X pwait none post *- #

# -* Process Wait without POST *- #

sub ts_PW_X
{
    my $self = shift;
    my $prm  = shift;
};

# -* Process Wait and POST handler *- #
sub ts_PW_P
{
    my $self = shift;
    my $prm  = shift;
  
    print  $main::DBG "$self->{id_key}>PW_P:$self->{q_pwait};\n"
        if $main::DEBUG & 4; 

    # -* this only for none P0 prcess *- #
    #print "\n>>> $self->{prompt} $prm->{prm}  == $main::ex->{iSQL_pool}{P0}{q_pwait}<<<<<<\n";
    if ($prm->{prm} >= $main::ex->{iSQL_pool}{P0}{q_pwait})     
    {
        push @{$self->{_w_list}},$prm->{prm};
        ++$self->{q_pwait};
        $self->sw_wait  unless _is_wait($self->{STATE}) ;

     
    #if ($prm->{prm} >= $main::ex->{iSQL_pool}{P0}{q_pwait})     
    #    if ($prm->{prm} < $ExecSQL::pwait_levl)
    #{
        push @{ $self->{_p_list} }, $self->{id_key};  # Post
        #print "\n>>> $self->{prompt} now... wait for going next\n";
        $main::ex->check_wait;
        #print "\n>>> $self->{prompt} ok... go next\n";
        #!JAST STROB
        push @{ $self->{_p_history}}, $prm->{prm};
        shift  @{ $self->{_p_list} }; 
    }
    else
    {
        #$main::ex->check_wait;      
    } 
 };

sub ts_SET_RESTART
{
    my $self = shift;
    my $prm  = shift;

    my $arg  = $prm->{prm};

    $self->_push_out('--+SET_RESTART ' . $prm->{prm});
    if ($arg eq 'OFF')
    {
        $self->{auto_restart} = 'N';
    }
    if ($arg eq 'ON')
    {
        $self->{auto_restart} = 'Y';
        $self->{server_dead}  = 'N';
        $self->{driver_ready} = 'N';
        $self->_close;
    }
    #print "\nSET_RESTART $arg :: " . $self->{auto_restart}. ".\n";
}
    
sub ts_SYSTEM
{
    my $self = shift;
    my $prm  = shift;
    $_  = $prm->{prm}; 
    #/^\s*(\w+\s*\@)?\s*(\w+\s*\:)?\s*(\S+)\s*/ ;
    #my ($user,$host,$cmd,$par) = ($1||'',$2||'',$3,$');
    /^\s*(\@\w+\s*)?\s*(\S+)\s*/ ;
    my ($server,$a_cmd,$par) = ($1||'',$2||'',$');
    #print ">>> cmd :: $1 :: $2 :: $'\n";
    ###  
    #$user =~ s/[\s\@\t]//g;
    #$host =~ s/[\s\:\t]//g;

    # for reserving the orginal value in order to print it
    my $t_server = $server;
    $t_server =~ s/[\s\@\t]*//g;

    # -* Check for process context *- #
    my  $command ;
=for modifying
    unless ($host)
    {
        $self->{ProgName} =~ /-s\s*(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}|\w+)\s*/;
        $host = ($1 eq '127.0.0.1') ? '' : $1;
    };
=cut

    #print "UNIX[1] : $t_server \n";
    #print "UNIX[2] : $a_cmd \n";
    #print "UNIX[3] : $par \n";

    use IO::WinMake;
    my $cmd;
    if ($OSWinFlag) 
    {
        my ($winCmd, $winPar) = ($a_cmd, $par);
        my $unixMakefile;
        my $winMakefile;
        if($winCmd =~ /^make/)
        {
            if ($winPar =~ /-f/)
            {
                $unixMakefile = $winPar;
                $winMakefile =  $winPar;
                $unixMakefile =~ s/-f(.*)\.mk(.*)/$1.mk/g;
                $winMakefile =~ s/-f(.*)\.mk(.*)/$1.win.mk/g; 
                $winPar =~ s/-f(.*)\.mk(.*)/-f $1.win.mk $2/g;
            }
            else
            {
                $unixMakefile = "Makefile";
                $winMakefile = "Makefile.win.mk";                
                $winPar = "-f Makefile.win.mk " . $winPar;
            }
            
            new IO::WinMake($RepTL::Test->{CurrentTestCase}{file}, $unixMakefile, $winMakefile); 

            #print "unixMakefile ".  $unixMakefile . "\n";
            #print ">>>>>>>>>>>>>>".  . "\n";
        }
        #print "WIN[1] : $t_server \n";
        #print "WIN[2] : $winCmd \n";
        #print "WIN[3] : $winPar \n";
        $cmd = $self->make_server_command ( $t_server,$winCmd.' '.$winPar );        
    }
    else
    {
        $cmd = $self->make_server_command ( $t_server,$a_cmd.' '.$par );
        if ($cmd =~ /^rsh/)
        {
            $cmd = "$cmd $a_cmd $par";
        }
    }


=for modifying
    if ($host)
    {
        $command = 'rsh '.$host;
        $command.= ' -l '. $user  if ($user) ;
        #$command.= " \'";
        # -* set export command for remoute execute *- #

        # for AGER
        #$self->{env}{ALTIBASE_AGER_STOP} = '1' if $main::cfg->{Ager};

        my ($env_key);
        foreach $env_key (keys  %{ $self->{env} })
        {
            $command.= 'export '.$env_key.'='.$self->{env}{$env_key}.';';
        }

=cut
        # -* set export command for remoute execute *- #
        $command.= "cd $main::$main::ex->{TestCase}{path};". $cmd . ' ';
        #$command.= $par . "\' ";
=for modifying
    }
    else
    {
        #$ENV{ALTIBASE_AGER_STOP} = '1' if $main::cfg->{Ager};
        $command = "cd $main::$main::ex->{TestCase}{path};" . $cmd . ' ' . $par;
    };

    # -* all output to null *- #
    #  1>>/dev/null;" ;
    if ( $command =~/2\>/ )
    {
        $command.="  >> $main::cfg->{SYSTEM_log_file};"; 
    }
    elsif ( $command =~/\>/ )
    {
        $command.="  2>\&1 ;"; 
    }
    else
    {
        $command.="  2>\&1 >> $main::cfg->{SYSTEM_log_file};"; 
    }
=cut

    if ($main::cfg->{Verbose} && $main::cfg->{BottomMsg})
    {
        my $progress = sprintf("\[%d%\]", $main::tp->get_progress());
        my $display_str = sprintf("$progress\[$main::ex->{TestCase}{Name}($self->{last}[0]):C\] %s", substr($server.' '.$a_cmd.' '.$par,0,44-$main::ex->{TestCase}{NameLength}));
        $main::DIS->printflush("\r"." "x68 . "\r");
        $display_str =~ s/\t/ /g;
        $main::DIS->printflush("\r$display_str\r");
    }

    my $print_str ;
    if ($server)
    {
        $print_str = '--+SYSTEM '.$server. ' ' .$a_cmd.' '.$par. ";";
    }
    else
    {
        $print_str = '--+SYSTEM '.$a_cmd.' '.$par. ";";
    }
    $self->_push_out($print_str);

    #print ">>> command ::: $command\n";
    # -*  Execute system command *- #
    my $max_cb_tm;
    eval
    {
        #local (STDOUT);
        my $rc = 0xffff & system($command);
        open(SYSLOG, ">> $main::cfg->{SYSTEM_log_file}");
        if ( $rc != 0 ) {
            $rc >>= 8;
            print SYSLOG ">>> return code : $rc \n\n";
        }
        else
        {
            print SYSLOG "\n";
        }
        close(SYSLOG);
    };

    #$main::DIS->printflush("\r"." "x68."\r") if $main::cfg->{Verbose} && $main::cfg->{BottomMsg};

    #print $main::ERR "\nERROR --+SYSTEM " . $! .':'  if ($?);
};


sub ts_DECLARE
{
    my $self = shift;
    my $parm = shift;
    my $prm  = $parm->{prm};
    my $desc = $parm->{desc} || '';
    $self->_push_out("--+DECLARE $prm; $desc");
}

sub ts_SET_ENV
{
    my $self = shift;
    my $parm = shift;
    my $prm = $parm->{prm};

    # extract env_key
    $prm =~ s/^s+//;
    $prm =~ s/^(\w+)[\s\t]*\=[\s\t]*//;
    my $env_key = $1;

    $self->_push_out("--+SET_ENV $parm->{prm};");
    my $host_name = $self->_get_server_hostname;

=for modifying
    if ($host_name eq '127.0.0.1')  # loca host
    {   
        $prm =~ s/\=\s*~/=$ENV{HOME}/; # expand '~' to $HOME
        $ENV{$env_key} = $prm;
    }
    else  # remote host
=cut
    {
=for modifying
        if ( ($prm =~ /\$(w+)/) and (defined $self->{env}{$1} ))
        {
            $prm =~ s/\$(\w+)/$self->{env}{$1}/g;
        }
        else
        {
            print "\n>>> ###$1###$self->{env}{$1}\n";
        }
=cut

        $self->{env}{$env_key} = { index => ++$self->{env_cnt}, 
                                   value => $prm};
        if ( $prm eq "" )
        {
            delete $self->{env}{$env_key};
        }
        #print Dumper $self->{env};
    }
}

sub make_server_command
{
    my $self = shift;
    my $server_name = shift;
    my $command = shift;
    my $cmd;
    my $key;
    my $is_enclosed='N';

use Sys::Hostname;
use HostIP;
    my $host_name = hostname;
    my $host_ip = hostip;
no Sys::Hostname;
no HostIP;

    #print "SERVER HOST_IP : #".$server->{HOST_IP}."#\n";
    #print "MY HOST_IP : #".$host_ip."#\n";

    #print Dumper $server;

    my $server = $main::tp->get_nearest_scope($server_name,'server_list');

    $cmd = '';
    if (($server->{HOST_IP} ne "127.0.0.1") &&
        ($server->{HOST_IP} ne $host_name) &&
        ($server->{HOST_IP} ne $host_ip))
    {
        return $cmd = "rsh ".$server->{HOST_IP}." " ;
    }

    #$cmd .= "loader.sh server $command ";
    $cmd .= "loader.sh ";
    
    my $t_port_no = $main::cfg->{PORT_NO};

    my $param_env = {};
    foreach $key ( keys %$server )
    {
        if ( $key =~ /ALTIBASE_\w+/ )
        {
            my $value = $server->{$key};
            if ($key =~ /ALTIBASE_PORT_NO/)
            {
                if ($value =~ /%PORT_NO/)
                {
                    $value = $self->_getPortNo($main::cfg->{PORT_NO}, $');
                    $server->{$key} = $value;
                }
                $t_port_no = $value;
            }
            elsif ($key =~ /ALTIBASE_HOME/)
            {
                $param_env->{$key} = $value;
            }

            if ($value =~ /%SHM_DB_KEY/  ||
                $value =~ /%REPLICATION_PORT_NO/)
            {
                $param_env->{$key} = $value;
            }
            else
            {
                $cmd .= " -D $key=".$value;
            }
        }
    }

    my ($env_key);
    foreach $env_key (sort {$self->{env}{$a}{index} <=> $self->{env}{$b}{index}} keys  %{ $self->{env} })
    {
        # In order to expand the environment variables turn by turn,
        #    we need to prevent the shell from expanding the environment variables 
        #    before passing it to the shell program.
        # eg) SET_ENV A1=abc;
        #     SET_ENV A2=$A1/abc;
        #     -------------------
        #     We should use like this:
        #     -D A1=abc -D A2='$A1/abc';
        # if not, shell may expand $A1 and pass it to the shell program.
        # so, the shell program gets nothing because there is no A1 envrionment variable
        # at that time.

        my $value = $self->{env}{$env_key}{value};
        if ($env_key =~ /ALTIBASE_PORT_NO/)
        {
            if ($value =~ /%PORT_NO/)
            {
                $value = $self->_getPortNo($main::cfg->{PORT_NO}, $');
            }
            $t_port_no = $value;
        }
        elsif ($env_key =~ /ALTIBASE_HOME/)
        {
            $param_env->{$env_key} = $value;
        }

        if ($value =~ /%SHM_DB_KEY/  ||
            $value =~ /%REPLICATION_PORT_NO/)
        {
            $param_env->{$env_key} = $value;
        }
        else
        {
            if ($value =~ /\$/)
            {
                $cmd.= " -D $env_key="."'".$value."'";
            }
            else
            {
                $cmd.= " -D $env_key=".$value;
            }
        }
            
    }
    #print Dumper $param_env;
    foreach my $key (keys %{$param_env})
    {
        my $value = $param_env->{$key};
        if ($value =~ /%SHM_DB_KEY/ )
        {
            $value = $self->_getShmDbKey($t_port_no);
        }
        elsif ($value =~ /%REPLICATION_PORT_NO/)
        {
            $value = $self->_getReplPortNo($t_port_no);
        }
        if ($value =~ /\$/)
        {
            $cmd.= " -D $key="."'".$value."'";
        }
        else
        {
            $cmd.= " -D $key=".$value;
        }
        if ($key =~ /ALTIBASE_HOME/)
        {
            $cmd .= " -D PATH="."'\$ALTIBASE_HOME/bin:\$PATH'";
        }
    }

=for next step
    my $pre = undef;
    my $ext;
    my $pos;
    $_ = $command;
    $command = '';
    while (/'(\$*\w*\s*)*'/)
    {
        $pre = $`;
        $ext = $&;
        $pos = $';
        $pre =~ s/(\$\{*\w*\}*)(\s*)/'$1'$2/g;
        $command .= $pre . $ext;
        $_ = $pos;
        print "\n>>> $command\n";
    }
    #if (!defined $pre)
    {
        $_ =~ s/(\$\{*\w*\}*)(\s*)/'$1'$2/g;
    }
    $command .= $_;
=cut

    if ( $command =~/2\>/ )
    {
        #$cmd.= ' ' . " ' " .$` . " ' " .$& . $';
        $cmd.= ' ' . " ' " .$command . " ' " ;
        $cmd.="  >> $main::cfg->{SYSTEM_log_file};";
    }
    elsif ( $command =~/\>/ )
    {
        #$cmd.= ' ' . " ' " .$` . " ' " .$& . $';
        $cmd.= ' ' . " ' " .$command . " ' " ;
        $cmd.="  2>> $main::cfg->{SYSTEM_log_file} ;";
        #$cmd.="  2>\&1 ;";
    }
    else
    { 
        $cmd .= ' ' ." ' " . $command . " ' " ;
        $cmd.="  2>> $main::cfg->{SYSTEM_log_file} >> $main::cfg->{SYSTEM_log_file};";
        #$cmd.="  2>\&1 >> $main::cfg->{SYSTEM_log_file};";
    }

    my $log_str = sprintf("\[$main::ex->{TestCase}{Name}($self->{last}[0]):C\] $self->{prompt} %s\n", $cmd); 
    open(SYSLOG, ">> $main::cfg->{SYSTEM_log_file}");
    print SYSLOG $log_str; 
    close(SYSLOG);

    return $cmd;
}

# discard remain queue in current scetor  of killed client 
sub _discard_remain_queue_in_current_sector
{
    my $self = shift;
    my $cur_cmd = $self->{IN}[0][1];

    #print Dumper $self->{IN};
    #print ">>> #of in = $#{$self->{IN}}\n";
    while ($#{$self->{IN}} > 0 && $cur_cmd !~ /^\-\-\+\s*SECTOR/ )
    {
        chomp($cur_cmd);
        if ($cur_cmd !~ /^\-\-\+\s*PW_P/)
        {
            $self->_push_out("> $cur_cmd");
            $self->_push_out("discarded due to KILL_CLIENT command");
        }
        shift @{$self->{IN}};
        $cur_cmd = $self->{IN}[0][1];
    }
}

sub ts_KILL_CLIENT
{
    my $self = shift;
    my $parm = shift || undef;

    $self->_push_out($self->{prompt}."--+KILL_CLIENT $parm->{prm};");
    if ($parm)
    {
        my @client_list = split /\s*[,]\s*/,$parm->{prm};

        foreach my $client (@client_list)
        {
            #$main::ex->{iSQL_pool}{$client}->_close();
            #$main::ex->{iSQL_pool}{$client}->{sock} = undef;
            #$main::ex->{iSQL_pool}{$client}->_save_final_result();
            $main::ex->{iSQL_pool}{$client}->sw_block if  _is_block($self->{STATE});
            $main::ex->{iSQL_pool}{$client}->_err_pipe('OK&DISCARD');
            $main::ex->{iSQL_pool}{$client}->_mark_start_tdx_item('R');
            $main::ex->{iSQL_pool}{$client}->_push_out('killed by KILL_CLIENT command');
            $main::ex->{iSQL_pool}{$client}->_discard_remain_queue_in_current_sector();
            $main::ex->{iSQL_pool}{$client}->_mark_end_tdx_item();
        }
    }
    else
    {
        foreach my $client (keys %{$main::ex->{iSQL_pool}})
        {
            #$main::ex->{iSQL_pool}{$client}->_close();
            #$main::ex->{iSQL_pool}{$client}->{sock} = undef;
            #$main::ex->{iSQL_pool}{$client}->_save_final_result();
            $main::ex->{iSQL_pool}{$client}->sw_block if  _is_block($self->{STATE});
            $main::ex->{iSQL_pool}{$client}->_err_pipe('OK&DISCARD');
            $main::ex->{iSQL_pool}{$client}->_mark_start_tdx_item('R');
            $main::ex->{iSQL_pool}{$client}->_push_out('killed by KILL_CLIENT command');
            $main::ex->{iSQL_pool}{$client}->_discard_remain_queue_in_current_sector();
            $main::ex->{iSQL_pool}{$client}->_mark_end_tdx_item();
        }
    }
}
    
sub TS_VERIFY_METHOD
{
    my $self = shift;
    my $parm = shift;
    my $prm = $parm->{prm};
}

sub _get_server_hostname
{
    my $self = shift;

    $self->{ProgName} =~ /\s*(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})\s*/;
    return $1;
}

#   Exceed Time  ??? 
sub _exceed_timer
{
    my $self =  shift;
    $self->_push_out("--! Time exceed by timer"); 
};

#####################################################################
 
sub error_handler
{
    my ($self,$error)  = @_;
};

# -* Set time out if have got param  $max_ti *- #
# -* return prviouse max_cb_tm          *- #
sub  timeout
{ 
    my $self = shift;
    my $tm  = shift;
    my $ret;

    if (defined($tm) )
    {
        $ret = $self->{evt}->interval;     
        $self->{max_cb_tm} =  $tm;
        $self->{evt}->interval($tm);
        return $ret;
    };
       
    $self->{evt}->interval($self->{max_cb_tm});
};

sub _max_cb_timeout
{
    print $main::LOG "Timeout exceed !";
};

# -* Function for checkin self  *- #
# -* Return TRUE/FULSE            *- #


sub check_myself
{
    my $self = shift;
    # -* This is stuped method but getsig it not implemet in perl now *- #
    unless ($self->{pid})
    {
       return 0;
    }
    return 0 unless kill 0,$self->{pid};
    return 1;
    # return $self->_ping_db;
};

  
# ################ ROLLBACK ######################
sub _rollback_out
{
	my $self = shift;

	my $current_index = $self->{q_out};

	while ($current_index > $self->{rollback_point})
	{
		$self->_pop_out;
		$current_index--;
	}

	while (defined $self->{last_queue} && @{$self->{last_queue}} > 0)
	{
		unshift (@{$self->{IN}}, pop @{$self->{last_queue}});
	}
}

# ################ POP OUT ######################

sub _pop_out
{
    # push to out stting out and increment couter 
    if(defined( $_[0]->{time_stmp}{$_[0]}))  
    {
        delete $_[0]->{time_stmp}{$_[0]};
    }    
    --$_[0]->{q_out};
    pop @{ $_[0]->{OUT} };
}

# ################ PUSH OUT ######################

sub _push_out
{
    # push to out stting out and increment couter 
    ++$_[0]->{q_out};
    push @{ $_[0]->{OUT} },$_[1];
    #print ">>> $_[0]->{id_key} :: $_[0]->{q_out} :: ".$_[0]->_get_time_tick ." :: $_[1]\n";
}

# ############### SHIFT OUT ######################
sub _shift_out 
{
    # shift to out stting out and decrement couter
    my $ret =  shift @{ $_[0]->{OUT} };
    --$_[0]->{q_out} if scalar  @{ $_[0]->{OUT} } ;
    return $ret;     
}     

# ################################################# 

sub _ping_db 
{
    my $self = shift;

    # -* Check ALTIBASE Database Protocol Connection *- #
    $self->{ProgName} =~ 
        /-s\s*(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}|\w+)\s*.*-port\s\s*(\d+)\s*/;

    my $sock = new IO::Socket::INET(PeerAddr=>$1,PeerPort =>$2,Proto =>'tcp') 
        || return 0 ;
 
    # -* Exactly check ALTIBASE port and protocol *- #
    $sock->printflush('IDC_INET_');
    $sock->sysread($_,128);

    return (/^IDC_READY/) ? 1 : 0;
};

1;
