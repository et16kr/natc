#!/usr/bin/perl -w
package CfgRead;
$^W=1;
require Exporter;

@ISA = qw (Exporter);
@EXPORT = qw ( new _init_isql_dsn );
use vars qw( $AUTOLOAD $DEBUG);
use Getopt::Long;
eval { use Data::Dumper } if $main::DEBUG; 
use File::Basename;
use IO::File;
use help;
use error;
use AltibaseInfo;

use Carp qw(croak);

$DEBUG ||=0;  # may be predefined


=head1 CONSTRUCTOR
=item new ( FILENAME)
This is the constructor for a new  TestLib;: CfgReader
C<FILENAME> tells twhere to look for the configuration file.
Return The REFERENCE to the HASH of Parametr
Attention The CASE sensitive !!! key on HASH
 Next parametr is special directive it find #plan e.t.c.
 an parse to array of parametrs  
=cut


sub new {
    my ($class) = shift;
    # -* check last symbol on PATH *- # 
    $ENV{ATC_HOME}.='/' unless $ENV{ATC_HOME} =~ /.*\/$/; 

    my $self  = 
    {
        #fname          => $ENV{ATC_HOME} . 'conf/'.basename($0).'.conf',
        alti_ver        => '',
        alti_major_ver  => '',
        fname           => $ENV{ATC_HOME} . 'conf/atc.conf',
        WorkDir         =>  'work/',
        Ager            => 1,    # 0: off, 1: on
        plan_only       => 0,  # 0: off, 1: TL only 2: TL+TS only 3: ALL
        @_,              
    };

    bless($self, $class);
    $self->{Verbose} = 0;
    $self->{WorkDir} = $ENV{ATC_WORK} if $ENV{ATC_WORK};

    if ($^O =~ /MSWin/) 
    {
       $self->{WorkDir} = $self->{WorkDir}."/";
    }
    else 
    {
       $self->{WorkDir} = $self->make_absolute_path($self->{WorkDir});
    }

    # No auto abbreviation, because I'd get conflicts with the
    # command-line options if I would use it. If you still get errors
    # then you should have a look if the variable POSIXLY_CORRECT is set
    # and if it is you should unset it.

    Getopt::Long::Configure('no_auto_abbrev');

    my ($p_no, $db_serv, $v, $q, $pr, $atm, $plan_only);
    GetOptions(
        "help|h|?"          =>\&help                , # Check if anyone needs help...
        "c|conf=s"          =>\$self->{fname}       , # Config File
        # -*  Need to do push to Array
        "sh|shell"          =>\$self->{Shell}       , # TEst Case File    
        "v|verbose:s"       =>\$v                   , # Verbouse  mode 1/2/3
        "q|quiet"           =>\$q                   , # quite
        "ok_sector:i"       =>\$self->{ok_sector}   , # Ok_SECTOR test switch
        "p|port|=s"         =>\$p_no                , # PORT Servers
        "s|server|=s"       =>\$db_serv             , # Addr Servers
        "lst|listing:i"     =>\$self->{LST}         , # Generate LST files
        "pl|printlevel"     =>\$pr                  , # Print level for PRINT stmt
        "atm"               =>\$atm                 , # ATM running mode
        "plan_only:i"       =>\$plan_only           , # plan only
        # Plugin
        "d|debug:i"         =>\$main::DEBUG         , # DEBUG Level
    ) || error (4); # Incorrect command line options!!!

    ##########################################
    ## Get CONFIG file for execution programm
    ##########################################
    if (defined($plan_only))
    {
        if ($plan_only == 0)
        {
            $plan_only = 3;
        }
        $self->{plan_only} = $plan_only;
    }
    $self->_parse($self->{"fname"});
    $self->{PORT_NO}  = $p_no     if $p_no;

    # -* convert name to ip string *- #
    if ( $db_serv)
    {
        my (undef,undef, undef, undef, @addrs) = gethostbyname($db_serv);
   
        unless ( defined $addrs[0]) 
        { 
            print $main::ERR "Wrong  $db_serv - I cant resolve and use default!\n";
        }
        else 
        { 
            my ($a, $b, $c, $d) = unpack('C4', $addrs[0]);
            $self->{DB_SERVER} = $db_serv  = "$a.$b.$c.$d";
        };  
    };
  
    ### Initialisation PARTH for DSN_ODBC     
    $self->{'DBI_DSN'} =$self->_init_dbi_dsn;
    $self->{'iSQL'}    =$self->_init_isql_dsn;
    $self->{'DBI_ATR'} =$self->_init_dbi_atr;

    $self->{LST}||=0; 
    $self->{Verbose}    = $v    if defined($v );
    $self->{BottomMsg}  = 1    unless defined ($q);
    $self->{RunAlone}   = 1    unless defined ($atm);
    $self->{PrintLevel} = $pr   if defined($pr);

    # -* Directory releative ATC_HOME *- # 
    $self->{DirLst} &&= $ENV{ATC_HOME} . $self->{DirLst};
    $self->{TCASE}  &&= $ENV{ATC_HOME} . $self->{TCASE} ;
    $self->{Diff}   &&= $self->{WorkDir} . $self->{Diff};
     
    $self->{DBT_MAP} &&= $ENV{ATC_HOME} . $self->{DBT_MAP} ;

    ## Expand the *_log_files to full path name
    $self->{SYSTEM_log_file} 
            = $self->{WorkDir}.$self->{SYSTEM_log_file};
    $self->{EXCEPTION_log_file} 
            = $self->{WorkDir}.$self->{EXCEPTION_log_file};
    $self->{REPORT_log_file} 
            = $self->{WorkDir}.$self->{REPORT_log_file};
    $self->{TIME_log_file} 
            = $self->{WorkDir}.$self->{TIME_log_file};
    $self->{ERROR_log_file} 
            = $self->{WorkDir}.$self->{ERROR_log_file};

    $self->{SERVER_CTX} = $ENV{ATC_HOME} . "/conf/atc.server.ctx";
    #    $self->{CLIENT_CTX} = $ENV{ATC_HOME} . "/conf/atc.client.ctx";

    # Makefile DF & log directories
    $self->make_init_dir;
    $self->get_altibase_version;

    return $self;
}

###
#  
#  Sub parse of statment from file
##
sub _parse {
   my $self  = shift;
   my $fname = shift;
   my $str;
   
   my $f_conf = new IO::File ($fname,'r') ||   die "Config: Can't open config file " . $fname . ": $!";
GET: 
    while (<$f_conf>) 
    {   
        chomp;
        next if /^\s*$/;  #  Ignore   blank  string
        s/^\s+//;    
        s/\s+$//;
        
        if (s/\\.*$// && ! $f_conf->eof)  
        { 
            $_.= <$f_conf>;
            redo;    
        };         # Use next line if "\" symbol like shell
                                                               # Split alll leader and traling whitespace 
        s/^#include\s*// && do 
        {
            if (/^\$(\w+)/) 
            { 
                $_ = $ENV{$1}.'/conf/altibase.properties'
            };
            $self->_parse($_);
            warn "Find include String:  $_\n " if $DEBUG;
            next GET
        }; # Dettermine "#include" statment
        
        /^\s*#/  && next GET;            # Ignore all flash and comment line
        $_=$` if /(?=#)/;                       #  cat all string after comment
        s/\s+|\s*\=+\s*|\s*\|+\s*|\s*\|+\s*|\s*\t+\s*|\s*\,+\s*/ /g;        #  Replace delimiters to witecode
        my ($key, $value) = _parse_line($_);
        #warn "Key:'$key'\tValue:'$value'\n" if $DEBUG;
        $self->{$key} = $value ;# if !defined  $self->{$key};
        warn "Key:'$key' \tValue:'$$self{'Config'}{$key}'\n" if $DEBUG;
    }
    $f_conf->close;
    return 1;
}

# Internal methods
sub _parse_line {
    shift;
    my ($key,@val);
    s/^\@//     && do{ ($key,@val)= split; return ($key ,\@val) };
    s/^\%(w+)// && do
    {  
        $key = $1;
        my %param;     
        return ($key,\%param);    
    };
    return split ;    
};

# Return SCALAR to DSN fof DBI Driver 
 sub _init_dbi_dsn {
    my $self = shift;
    my $cfg = $self->{'Config'};
    my $dsn;
## DEFINE SECTION for DSN parametr of   
    if (  $self->{'DBI'}) 
    {
        $dsn .= "dbi:ODBC:";
        if ( $self->{'DB_SERVER'})
        { 
            $dsn .='DSN='.$self->{'DB_SERVER'}.';';
        }
        else
        { 
            $dsn .='DSN=127.0.0.1;'  
        };  
           
        if ( $self->{'DB_UID'})            
        { 
            $dsn .= 'UID='     . $self->{'DB_UID'}   .';' ;
        }
        else 
        { 
            $dsn .='UID=SYS;'
        };
        
        if ( $self->{'DB_PASSWD'})
        { 
            $dsn .= 'PWD='     . $self->{'DB_PASSWD'}.';' ;
        }
        else
        { 
            $dsn .='PWD=MANAGER;'
        };
        
        if ( $self->{'CONNTYPE'})
        { 
            $dsn .= 'CONNTYPE='. $self->{'CONNTYPE'}.';' ;
        }
        else
        { 
            $dsn .= 'CONNTYPE=1;'
        };
         
        if ($self->{'NLS_USE'})
        { 
            $dsn .= 'NLS_USE='. $self->{'NLS_USE'}.';' ;
        }
        else
        { 
            $dsn .= 'NLS_USE=US7ASCII;'
        };
        
        if ($self->{'PORT_NO'})
        { 
            $dsn .= 'PORT_NO='. $self->{'PORT_NO'}.';' ;
        }
        else
        { 
            $dsn .= 'PORT_NO=20330;'
        };
    } 
    elsif ( $ENV{'DBI_DSN'} ) { $dsn=$ENV{'DBI_DSN'}} ;
        return $dsn;
 };## END sub _init_odbc_dsn

sub _init_isql_dsn {
    my $self = shift;
    my $dsn;
## DEFINE SECTION for DSN parametr of   
#        $dsn .= "isql ";

    if ( $self->{'DB_DRIVER'} ) 
    { 
        $dsn .= $self->{'DB_DRIVER'}.' ';
    } 
    else    
    {
        $dsn .= "isql ";
    };

    if ( $self->{'DB_SERVER'})
    { 
        $dsn .='-s '.$self->{'DB_SERVER'}.' ';
    }
    else 
    { 
        $dsn .='-s 127.0.0.1 '  
    };  

    if ( $self->{'DB_UID'})            
    { 
        $dsn .= '-u '.$self->{'DB_UID'}.' ' ;
    }
    else
    { 
        $dsn .='-u SYS '
    };
    if ( $self->{'DB_PASSWD'})
    { 
        $dsn .= '-p '.$self->{'DB_PASSWD'}.' ' ;
    }
    else
    { 
        $dsn .='-p MANAGER '
    };
    if ( $self->{'PORT_NO'})
    { 
        $dsn .= '-port '. $self->{'PORT_NO'}.' ' ;
    }
    else
    { 
        $dsn .= '-port 20330 '
    };
    return $dsn.' -silent';
};


sub _init_dbi_atr 
{
    my $self = shift;
    my $dbi_atr;
    ## DEFINE SECTION for param ATRIBUT refence of HASH DBI  
    if ( defined $self->{'RAISE_ERROR'}) 
    {
        $dbi_atr->{'RaiseError'}= $self->{'RAISE_ERROR'} 
    }
    else
    {    
        $dbi_atr->{'RaiseError'}= 0; # Default is "0"
    }; ## END of IF
    
    if ( defined $self->{'PRINT_ERROR'}) 
    {
        $dbi_atr->{'PrintError'}= $self->{'PRINT_ERROR'} 
    }
    else
    {    
        $dbi_atr->{'PrintError'}= 1; # By default print driwer message Error 
    }; ## END of IF
    
    if ( defined $self->{'AUTO_COMMIT'}) 
    {
        $dbi_atr->{'AutoCommit'}= $self->{'AUTO_COMMIT'} 
    }
    else
    {    
        $dbi_atr->{'AutoCommit'}= 1; # Default is AUTOCOMMIT Mode
    }; ## END of IF
    
    if ( defined $self->{'LONG_READ_LEN'}) 
    {
        $dbi_atr->{'LongReadLen'}= $self->{'LONG_READ_LEN'} 
    }
    else
    {    
        $dbi_atr->{'LongReadLen'}= 0;# By default don't read LongData
    }; ## END of IF
    return $dbi_atr
}

sub make_init_dir  {
    my $self = shift;
    my $path;

use File::Path;

    $path = dirname($self->{ERROR_log_file});
    mkpath $path unless -d $path;

    $path = dirname($self->{SYSTEM_log_file});
    mkpath $path unless -d $path;

    $path = dirname($self->{EXCEPTION_log_file});
    mkpath $path unless -d $path;

    $path = dirname($self->{REPORT_log_file});
    mkpath $path unless -d $path;

    $path = dirname($self->{TIME_log_file});
    mkpath $path unless -d $path;

    $path = $self->{Diff};
    mkpath $path unless -d $path;

no File::Path;
}

###########################################
# TODO : Considerate about Remote Server
###########################################
sub get_altibase_version
{
    my $self = shift;
    my $rc;

    my $v_file = $self->{WorkDir}."altibase.info";
    if ($^O =~ /MSWin/) {
        $rc = 0xffff & system ("altibase.exe -v > $v_file");
    }
    else {
        $rc = 0xffff & system ("altibase -v > $v_file");
    }

    if ($rc != 0 )
    {
        system("rm -f $v_file");
    }

    my $v_fd = new IO::File ( $v_file, 'r')
            || die "Can't open altibase version info file ($v_file)\n";

    my $version_string = <$v_fd>;
    my ($name,$version,$package,$host,$date) = split ' ', $version_string;
    my ($mager_v,$middle_v,$patch_v) = split '\.', $version;
    $v_fd->close;

    $self->{alti_ver} = $version_string;
    $self->{alti_major_ver} = "A$mager_v";
    $self->{DirLst} = $self->{DirLst}."A$mager_v\/";

    my $alti_info = new AltibaseInfo;
    $self->{file_ext} = $alti_info->get_file_ext;
}

sub make_absolute_path
{
    my $self = shift;
    my $path = shift;

    $path = $ENV{ATC_HOME}.'/'.$path unless $path =~ /^\//;
    $path .= "/" unless $path =~ /\/$/;

    return $path;
}

1;