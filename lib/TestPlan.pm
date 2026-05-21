package TestPlan;

use strict;
#use Diff qw ( diff );

use Data::Dumper;
use File::Basename;
use IO::File;
use Socket;
use Sys::Hostname;

use AltibaseInfo;
use vars qw( $VERSION %DBT_MAP );
use Time::HiRes qw(gettimeofday  tv_interval );
$VERSION = 0.02;

my @TSERROR; # -* list of referece to error test cases

sub new {
    my($class) = shift;
    my $self   = 
    {  
        # -* Test List prefix/suffix  *- #
        TL_dir         => $ENV{ATC_HOME} . "TL/",
        TL_Suffix      => ".tl",
        
        # -* Test Suite prefix/suffix *- #
        TS_dir         => $ENV{ATC_HOME} . "TS/",
        TS_Suffix      => ".ts",

        # -* Test Case prefix/suffix *- #
        TC_dir         => "TC/",
        TC_Suffix      => ".sql",
        
        # -* Test Suite ERROR file 
        TSERROR        =>  ($main::cfg->{TSERROR})
            ? $main::cfg->{WorkDir}.$main::cfg->{TSERROR} 
            : $main::cfg->{WorkDir}."TS/TS999999.ts",     

        tl_count        => 0,
        ts_count        => 0,
        tc_count        => 0,
        tl_fail_count   => 0,
        ts_fail_count   => 0,
        tc_fail_count   => 0,
        doing_tc_count  => 0,
        current_tl      => undef,
        current_ts      => undef,
        current_tc      => undef,
        pg_value        => undef,
        local_ip        => undef,
        @_,
    };

    bless ($self, $class);

    open( FILE, $ENV{'ATC_HOME'} . "/conf/platform_groups.conf" );

    my @lines = <FILE>;

    my $key    = undef;
    my $value1 = undef;
    my @value2 = undef;
    my @value3 = undef;
    my $s1     = undef;
    my $s2     = undef;
    my $s3     = undef;
    my $line   = undef;

    for( $a = 0; $a <= $#lines; $a++ )
    {
        $line = $lines[$a];

        chomp $line;

        if( $line =~ /^\s*$/ )
        {
            next;
        }
        $line =~ s/^\s+//;
        $line =~ s/\s+$//;
        $line =~ s/#.*//;

        ($key, $value1) = split( /[ \t]*:[ \t]+/, $line );

        @value2 = split( /[ \t]+/, $value1 );
        @value3 = ();

        for( $b = 0; $b <= $#value2; $b++ )
        {
            $s1 = $value2[$b];
            $s2 = gethostbyname($s1);
            if( defined( $s2 ) )
            {
                $s3 = inet_ntoa($s2);
                $value3[$b] = $s3;
            }
        }

        $self->{pg_value}{$key} = "@value3";
    }

    $s1 = gethostbyname(hostname());
    if( defined( $s1) )
    {
        $self->{local_ip} = join('.' => unpack 'C4' => $s1);
    } 
    else
    {
        $self->{local_ip} = 127.0.0.1;
    }

    # -* Parse ARGV parametr for TL TS TC etc and others file *- #
    # @ARGV = sort @ARGV;    --> remove by kskim

    $self->{idx}= 0 ;
    $self->{stack}= [] ;
    while ($_= shift @ARGV)
    {
        SWITCH: 
        {
        if (/^\S+\.tl/)
        {
            $self->_parse_TL($_);
            #$self->get_test_set;
            $self->{idx} = 0;
            last SWITCH;
        }
        if (/^\S+\.ts$/)    # this is ts file
        {
            $self->_parse_TS($_);
            $self->{idx} = 0;

            last SWITCH;
        };
        if (/^\S+\.sql$/) # This is sql file script
        {
            $self->_parse_TC($_);
            last SWITCH;        
        };
            
        # ! mast be common Error Handler in next wersion
        print $main::ERR "Wrong parametr of string \'$_\' I cant do It !\n";
        main::_exit(255);
     
        }; # END SWITCH
    #!  push @{$self->{'TC'}},$_;
    };
    $self->{current_tl} = undef;
    $self->{current_ts} = undef;
    $self->{current_tc} = undef;

    return $self;
};

# 2 == 64BIT, 2!=0 32BIT
sub get_lst_name
{
   
    my $self = shift;
    my $tc_file_name = shift;
    my ($fname,$fpath,$f_suffix) = fileparse ( $tc_file_name, '\.sql');
    my $root_dir = '';
    my $file_ext;
    my $file_name = "";
    $file_ext = $main::cfg->{file_ext};

    my $altiInfo = new AltibaseInfo;
    #if 64BIT then

    if($altiInfo->{"bit"} == 64)
    {
	 $file_name = $fpath . '/' . $fname . "_" . $altiInfo->{"endian"} . $file_ext . $main::Lst_Suffix;
        if(-e $file_name)
        {
           return $file_name;
        }

        $file_name = $fpath . '/' . $fname . "_" . $altiInfo->{"os"} . $file_ext . $main::Lst_Suffix;
        if(-e $file_name)
        {
           return $file_name; 
        }

        $file_name = $fpath . '/' . $fname . $file_ext . $main::Lst_Suffix;
        if(-e $file_name)
        {
            return $file_name;
        }
    }
    else
    {

        
        $file_ext =~ s/64$/32/;
        $file_name = $fpath . '/' . $fname . "_" . $altiInfo->{"endian"} . $file_ext . $main::Lst_Suffix;
        if(-e $file_name)
        {
            return $file_name;
        }

        $file_ext =~ s/32$/64/;
        $file_name = $fpath . '/' . $fname . "_" . $altiInfo->{"endian"} . $file_ext . $main::Lst_Suffix;
        if(-e $file_name)
        {
            return $file_name;
        }

        $file_ext =~ s/64$/32/;
        $file_name = $fpath . '/' . $fname . "_" . $altiInfo->{"os"} . $file_ext . $main::Lst_Suffix;
        if(-e $file_name)
        {
            return $file_name;
        }

        $file_ext =~ s/32$/64/;
        $file_name = $fpath . '/' . $fname . "_" . $altiInfo->{"os"} . $file_ext . $main::Lst_Suffix;
        if(-e $file_name)
        {
            return $file_name;
        }
        
        $file_ext =~ s/64$/32/;
        $file_name = $fpath . '/' . $fname . $file_ext . $main::Lst_Suffix;
        if(-e $file_name)
        {
            return $file_name;
        }
        
        $file_ext =~ s/32$/64/;
        $file_name = $fpath . '/' . $fname . $file_ext . $main::Lst_Suffix;
        if(-e $file_name)
        {
            return $file_name;
        }
    }
    return $file_name;
}

sub get_out_name
{
    my $self = shift;
    my $tc_file_name = shift;
    my ($fname,$fpath,$f_suffix) = fileparse ( $tc_file_name, '\.sql');
    my $file_name = "";
    
    my $altiInfo = new AltibaseInfo;
    
   $file_name = $fpath . '/' . $fname . $main::cfg->{file_ext} . ".out";
    
    if(-e $file_name)
    {
        return $file_name;
    }
    return $file_name;
}

sub get_tdx_name
{
    my $self = shift;
    my $tc_file_name = shift;

    my ($fname,$fpath,$f_suffix) = 
                    fileparse ( $tc_file_name, '\.sql');

    my $root_dir = '';

    my $file_name =  ($main::cfg->{'LST'} == 2 )
         #? $fname . $main::cfg->{file_ext} . '.tdx'
         ? $fpath . '/' . $fname . $main::cfg->{file_ext} . '.tdx' 
         : $fpath . '/' . $fname . $main::cfg->{file_ext} . '.tdx';

    return $file_name;
}

sub _parse_TL 
{
    my $self  = shift;
    my $tl_name = shift;
    my $tl_desc = shift;
    my $depth = shift || 0;
    my %_tl;

    my $fd   = new IO::File $self->{TL_dir}.$tl_name,'r' ;
    unless ($fd) 
    {
        print $main::ERR "I can't open $tl_name file of lst! \n";
        print $main::REPORT "I can't open $tl_name file of lst! \n";
        return undef;
    };
    my ($tl_fname, $tl_path, $tl_suffix) = 
                              fileparse($tl_name, '\.tl');
    $_tl{No} = '';
    $_tl{Name} = $tl_fname . $tl_suffix;
    $_tl{type} = 'TL';
    $_tl{desc}= $tl_desc;
    $_tl{path}= $tl_path;
    $_tl{tl_count} = 0;
    $_tl{ts_count} = 0;
    $_tl{tc_count} = 0;
    $_tl{failed_list} = [];
    $_tl{server_list} = {};
    $_tl{client_list} = {};
    $_tl{desc}= '';
    $_tl{depth} = $depth;

    my $case_item = {item=>\%_tl, state=>'S'};
    push @{$self->{List}}, $case_item;

    if ($main::cfg->{plan_only} >= 1)
    {
        my $indent = $depth*3;
        $_ = $_tl{path};
        /TC\//;
        my $path = $';
        print " "x$indent."# $_tl{Name} $path $_tl{desc}\n";
    }
    $self->{current_tl} = \%_tl;

GET: while (<$fd>) {   
        chomp;
        next if /^\s*$/;              #  Ignore   blank  string
        s/^\s+//;
        s/\s+$//;
        /^\s*#/  && next GET;       # Ignore all flash and comment line
        #$_=$` if /(?=#)/;           #  cat all string after comment
        # for line param
        if (/TestListDescription/)
        {
            my ($key,$val) = split /\s*=\s*/,$_,2;
            $_tl{desc}= $val; 
            next;
        }
        elsif (/^[\t\s]*\#/ || /^[\t\s]*\n/)
        {
            next GET;
        }
        else
        {
            my @par;
            @par = split /\S*#\S*/,$_, 2;
            $par[0] =~ s/[\t\s]*//g;
            $par[1] = '' unless ($par[1]);
            $par[1] =~ s/[\t\s]*//;
            #print "par = $par[0] ::: $par[1]\n";
            if (/^\S*\.tl/)
            {
                my $tl;
                #my ($tl_fname, $tl_path, $tl_suffix) = 
                #fileparse($par[0], '\.tl');
                $tl      = $self->_parse_TL($par[0], $par[1], $depth+1);     
                #push @{$_tl{List}},$tl;
                $_tl{tl_count} ++;

            }
            elsif (/^\S*\.ts/)
            {
                my $ts;
                #### find ts name in the ts_map file and replace it
                #my $ts_full_path = $ENV{ATC_HOME} . '/' . $par[0];
                #my ($ts_fname, $ts_path, $ts_suffix) = 
                #fileparse($ts_full_path, '\.ts');
                $ts = $self->_parse_TS($par[0], $par[1], $depth+1);     
                #$ts->{No}  = '';
                #$ts->{file}= $ts_full_path;
                #$ts->{desc}= $par[1];
                #$ts->{type}= "TS";
                #$ts->{path}= $ts_path;
                #push @{$_tl{List}},$ts;

                $_tl{ts_count} ++;

            }
        }
   } # end while

    $fd->close;   
    $case_item = {item=>\%_tl, state=>'E'};
    push @{$self->{List}}, $case_item;
    $self->{tl_count} ++;
    #return \%_tl;
};

sub _parse_TS 
{
    my $self  = shift;
    my $ts_name = shift;
    my $ts_desc = shift;
    my $depth = shift || 0;
    my $parent_case = shift || '';
    my %_ts;

    my $fd   = new IO::File $ENV{ATC_HOME} . $ts_name,'r' ;
    unless ($fd) 
    {
        $fd   = new IO::File $ts_name,'r' ;
        unless ($fd) 
        {
            my $f_ts_name = $main::tsmap->find_TS_map($ts_name);
            #print ">>> full name ::: #$f_ts_name# ::: #$ts_name#\n";
            if ($f_ts_name)
            {
                $fd = new IO::File $f_ts_name, 'r';
                $ts_name = $f_ts_name;
            }
            unless ($fd)
            {
                print $main::ERR "$ts_name TS file not found in $parent_case \n";
                print $main::EXCEPTION "$ts_name TS file not found in $parent_case \n";
                return undef;
                #main::_exit(255);
            };
        };
    };
    my ($ts_cname, $ts_cpath, $ts_csuffix) = 
                                  fileparse($ts_name, '\.ts');
    $_ts{Name} = $ts_cname . $ts_csuffix;
    $_ts{No} = '';
    $_ts{type} = 'TS';
    $_ts{file} = $ts_name;
    $_ts{path} = $ts_cpath;
    $_ts{tl_count} = 0;
    $_ts{ts_count} = 0;
    $_ts{tc_count} = 0;
    $_ts{failed_list} = [];
    $_ts{desc}= '';
    $_ts{server_list} = {};
    $_ts{client_list} = {};
    $_ts{depth} = $depth;

    my $case_item = {item=>\%_ts, state=>'S'};
    push @{$self->{List}}, $case_item;
    $self->{current_ts} = \%_ts;

    if ($main::cfg->{plan_only} >= 2)
    {
        my $indent = $depth*3;
        $_ = $_ts{path};
        /TC\//;
        my $path = $';
        print " "x$indent."- $_ts{Name} $path $_ts{desc}\n";
    }

GET: while (<$fd>) {   
        chomp;
        next if /^\s*$/;              #  Ignore   blank  string
        s/^\s+//;
        s/\s+$//;
        /^\s*#/  && next GET;       # Ignore all flash and comment line
        
        my $altiInfo1 = new AltibaseInfo;
        if($altiInfo1->{"os"} eq 'WIN_NT' )
        {
            s/^\~//;                    # for only WIN_NT, Ignore ~
            /^\s*!/  && next GET;       # Ignore all line started with !
        }
        else
        {
            s/^\!//;                    # for any other OS except WIN_NT
            /^\s*~/  && next GET;       # Ignore all line started with ~
        }

        #$_=$` if /(?=#)/;           #  cat all string after comment
        # for line param
        if (/TestSuiteDescription/)
        {
            my ($key,$val) = split /\s*=\s*/,$_,2;
            $_ts{desc}= $val; 
            next;
        }
        elsif (/^[\t\s]*\#/ ||  /^[\t\s]*\n/)
        {
            next GET;
        }
        else
        {
            my @par;
            @par = split /\S*#\S*/,$_, 2;
            $par[0] =~ s/[\t\s]*//g;
            $par[1] = '' unless ($par[1]);
            $par[1] =~ s/[\t\s]*//;
            #print "par = $par[0] ::: $par[1]\n";
            if (/^\S*\.ts/)
            {
                my $run = $self->_parse_pg($par[0]);

                if( $run == 1 )
                {
                    $_ = $par[0];
                    s/\[(\w)+\]//;
                    s/\[\^(\w)+\]//;
                    $par[0] = $_;
                }
                else
                {
                    next GET;
                }

                my $ts;
                my $ts_full_name = $ts_cpath . $par[0];
                $ts      = $self->_parse_TS($ts_full_name, $par[1], $depth+1,
                                            $_ts{path}.$_ts{Name});     
                #push @{$_ts{List}},$ts;
                if (defined $ts)
                {
                    $_ts{ts_count} ++;
                }
            }
            elsif (/^\S*\.sql/)
            {
                my $run = $self->_parse_pg($par[0]);
 
                if( $run == 1 )
                {
                    $_ = $par[0];
                    s/\[(\w)+\]//;
                    s/\[\^(\w)+\]//;
                    $par[0] = $_;
                }
                else
                {
                    next GET;
                }

                my $tc;
                #### find ts name in the ts_map file and replace it
                my ($tc_fname, $tc_path, $tc_suffix) = 
                                          fileparse($par[0], '\.sql');
                my $tc_full_name = $ts_cpath . $par[0];
                $tc      = $self->_parse_TC($tc_full_name, $par[1], $depth+1,
                                            $_ts{path}.$_ts{Name});     
                #push @{$_ts{List}},$tc;

                if (defined $tc)
                {
                    $_ts{tc_count} ++;
                }
            }
        }
   } # end while

    $fd->close;   
    $case_item = {item=>\%_ts, state=>'E'};
    push @{$self->{List}}, $case_item;
    $self->{ts_count} ++;
    #return \%_ts;
};


# -* Getting list of TestCase for ExecSQL module *- #

sub _parse_TC
{     
    my $self   = shift;
    my $a_tc_name = shift;
    my $a_tc_desc = shift;
    my $depth = shift || 0;
    my $parent_ts = shift || '' ;
    my %_tc;

    my ($tc_fname, $tc_path, $tc_suffix) = 
                                  fileparse($a_tc_name, '\.sql');
    $_tc{No}  = '';
    $_tc{Name}= $tc_fname . '.sql';
    $_tc{server_list} = {};
    $_tc{client_list} = {};
    $_tc{depth}  = $depth;

    if ($tc_path =~ /^TC/)
    {
        $_tc{file}= $ENV{ATC_HOME} . '/' . $tc_path . $_tc{Name};
        $_tc{path}= $ENV{ATC_HOME} . '/' . $tc_path; 
    }
    else
    {
        if ($tc_path =~ /^\//)
        {
            $_tc{file}= $tc_path . $_tc{Name};
            $_tc{path}= $tc_path;
        }
        else
        {
            $_tc{file}= $ENV{PWD} . "/" . $tc_path . $_tc{Name};
            $_tc{path}= $ENV{PWD} . "/" . $tc_path;
        }
    }
    #print ">>> $_tc{path}\n";
    $_tc{desc}= $a_tc_desc;
    $_tc{type}= "TC";
    my $case_item = {item=>\%_tc, state=>'E'};
    if (! -e $_tc{file})
    {
        print $main::ERR "$_tc{file} TC file not found in $parent_ts\n";
        print $main::EXCEPTION "$_tc{file} TC file not found in $parent_ts\n";
    }
    else
    {
        push @{$self->{List}}, $case_item;
        $self->{tc_count}++;
        $self->{current_tc} = \%_tc;
    }

    if ($main::cfg->{plan_only} >= 3)
    {
        my $indent = $depth*3;
        $_ = $_tc{path};
        /TC\//;
        my $path = $';
        print " "x$indent."+ $_tc{Name} $path $_tc{desc}\n";
    }
};

# -* Test Suite Parse to Tree from file *- #

sub get_list_tc 
{
    my $self = shift; 
    my ($tl,$ts,$tc); 
    my @tc_list;     

    foreach $tl (@{$self->{List}})
    {
        foreach $ts (@{$tl->{List}})
        {
            foreach $tc (@{$ts->{List}}) 
            {
                push @tc_list,$tc; 
            }
        }
    }

    return \@tc_list;
};

# -* Get Test Case Sequencly from TestDB *- #

my ($idx_tl,$idx_ts,$idx_tc) = (0,0,0); # Current TestList TestSuite TestCase index 
my ($_tl,$_ts);                # Store prviose State

sub get_cur_tl
{
    my $self = shift;

    return $_tl->{Name};
}

sub get_progress
{
    my $self = shift;

    return $self->{doing_tc_cnt} * 100 / $self->{tc_count};
}

sub get_cur_ts
{
    my $self = shift;

    return $_ts->{Name};
}

sub get_test_set
{
    my $self = shift;

    my $cur_item = $self->{List}[$self->{idx}];
    my $cur_case = $cur_item->{item};
    my $cur_state = $cur_item->{state};
    #print Dumper $self;
    while ( $cur_case )
    {
        #print ">>> $cur_case->{type} :: $cur_case->{Name} :: $cur_state\n";
        $self->{idx}++;
        $cur_item = $self->{List}[$self->{idx}];
        $cur_case = $cur_item->{item};
        $cur_state = $cur_item->{state};
    }
}

sub get_higher_scope
{
    my $self = shift;
    my $find_name = shift;
    my $current_scope_obj = shift;
    my $which_list = shift;

    my $container;

    #print Dumper $current_scope_obj;
    my $stack_ptr = @{$self->{stack}};

    # First, find it on the current TC
    $container = $self->{current_tc};
    if ($find_name !~ /ALL/ &&
        defined $container->{$which_list}{ALL})
    {
        return $container->{$which_list}{ALL};
    }
    # find the position of the current scope object in the stack
    if ($stack_ptr > 0 &&
        $current_scope_obj->{type} ne "TC")
        
    {
        $container = $self->{stack}[--$stack_ptr];
        while (! ($container->{Name} eq $current_scope_obj->{Name} ||
                  defined $current_scope_obj->{ALL})
              )
        {
            $container = $self->{stack}[--$stack_ptr];
        }
    }

    # find the higher scope object on the stack 
    #            from the position of the current scope object in the stack

    while ($stack_ptr > 0)
    {
        $container = $self->{stack}[--$stack_ptr];
        if (defined $container->{$which_list}{$find_name})
        {
            return $container->{$which_list}{$find_name};
        }
        elsif (defined $container->{$which_list}{ALL})
        {
            return $container->{$which_list}{ALL};
        }
    }

    # if not found, return the default template
    if ($which_list =~ /server_list/)
    {
        return $main::server_tmpl->{DEFAULT};
    }
    else
    {
        return $main::client_tmpl->{DEFAULT};
    }
}

sub get_nearest_scope
{
    my $self = shift;
    my $find_name = shift;
    my $which_list = shift;

    my $container;

    my $stack_ptr = @{$self->{stack}};

    # First, find it on the current TC
    $container = $self->{current_tc};
    if (defined $container->{$which_list}{$find_name} )
    {
        return $container->{$which_list}{$find_name};
    }
    elsif (defined $container->{$which_list}{ALL})
    {
        return $container->{$which_list}{ALL};
    }


    # Second, find it on the hierarchy chain
    while ($stack_ptr > 0)
    {
        $container = $self->{stack}[--$stack_ptr];
        #print Dumper $container;
        if (defined $container->{$which_list}{$find_name})
        {
            return $container->{$which_list}{$find_name};
        }
        elsif (defined $container->{$which_list}{ALL})
        {
            return $container->{$which_list}{ALL};
        }
    }

    # Third, return DEFAULT template
    if ($which_list =~ /server_list/)
    {
        return $main::server_tmpl->{DEFAULT};
    }
    else
    {
        return $main::client_tmpl->{DEFAULT};
    }
}

sub get_nearest_server_scope_old
{
    my $self = shift;
    my $server_name = shift;

    my $tmp_context = undef;
    my $tmp_ok = 0;
    if (defined $self->{current_tc})
    {
        $tmp_context = $self->{current_tc}->{server_list}{$server_name};
        if (defined $tmp_context)
        {
            $tmp_ok = 1;
        }
    }

    if ($tmp_ok != 1 && defined $self->{current_ts})
    {
        $tmp_context = $self->{current_ts}->{server_list}{$server_name};
        if (defined $tmp_context)
        {
            $tmp_ok = 1;
        }
    }

    if ($tmp_ok != 1 && defined $self->{current_tl})
    {
        $tmp_context = $self->{current_tl}->{server_list}{$server_name};
        if (defined $tmp_context)
        {
            $tmp_ok = 1;
        }
    }

    if ($tmp_ok != 1)
    {
        $tmp_context = $main::server_tmpl->{DEFAULT};
    }

    return $tmp_context;
}

sub get_nearest_client_scope_old
{
    my $self = shift;
    my $client_name = shift;

    my $tmp_context = undef;
    my $tmp_ok = 0;
    if (defined $self->{current_tc})
    {
        $tmp_context = $self->{current_tc}->{client_list}{$client_name};
        if (defined $tmp_context)
        {
            $tmp_ok = 1;
        }
    }

    if ($tmp_ok != 1 && defined $self->{current_ts})
    {
        $tmp_context = $self->{current_ts}->{client_list}{$client_name};
        if (defined $tmp_context)
        {
            $tmp_ok = 1;
        }
    }

    if ($tmp_ok != 1 && defined $self->{current_tl})
    {
        $tmp_context = $self->{current_tl}->{client_list}{$client_name};
        if (defined $tmp_context)
        {
            $tmp_ok = 1;
        }
    }

    if ($tmp_ok != 1)
    {
        $tmp_context = $main::client_tmpl->{DEFAULT};
    }

    return $tmp_context;
}

sub get_tc
{
    my $self = shift;
    my $cur_item = $self->{List}[$self->{idx}];
    my $cur_case = $cur_item->{item};
    my $cur_state = $cur_item->{state};

    my ($sec,$min,$hour,$day,$mon,$year,$wday,$yday,$isdst);
    ($sec,$min,$hour,$day,$mon,$year,$wday,$yday,$isdst) = localtime(time);
    $year += 1900;  
    $mon++;
    if ($mon < 10) { $mon = "0$mon"; }
    if ($day < 10) { $day = "0$day"; }
    if ($hour < 10) { $hour = "0$hour"; }
    if ($min < 10)  { $min = "0$min"; }
    if ($sec < 10) { $sec = "0$sec"; }
    
    $self->{EndTime} = "[ET]". $year . "-" . $mon . "-" . $day . " " . $hour . ":" . $min . ":" . $sec;

    #print ">>> index = $self->{idx}\n";

    while ( $cur_case && $cur_case->{type} ne 'TC' )
    {
        if ( $cur_state eq 'S' && $cur_case->{type} eq 'TS' )
        {
            $self->report_TS_header($cur_case); 
            push @{$self->{stack}}, $cur_case;
            $self->{current_ts} = $cur_case;
        } 
        elsif ( $cur_state eq 'E' && $cur_case->{type} eq 'TS' )
        {
            pop @{$self->{stack}};
            $self->report_TS_bottom($cur_case); 

            my $top_test = $self->{stack}[@{$self->{stack}}];
            if (defined $top_test && $top_test->{type} eq 'TS')
            {
                $self->{current_ts} = $top_test;
            }
            elsif (defined $top_test && $top_test->{type} eq 'TL')
            {
                $self->{current_tl} = $top_test;
            }
        } 
        elsif ( $cur_state eq 'S' && $cur_case->{type} eq 'TL' )
        {
            $self->report_TL_header($cur_case); 
            push @{$self->{stack}}, $cur_case;
            $self->{current_tl} = $cur_case;
        } 
        elsif ( $cur_state eq 'E' && $cur_case->{type} eq 'TL' )
        {
            pop @{$self->{stack}};
            $self->report_TL_bottom($cur_case); 

            my $top_test = $self->{stack}[@{$self->{stack}}];
            if (defined $top_test && $top_test->{type} eq 'TS')
            {
                $self->{current_ts} = $top_test;
            }
            elsif (defined $top_test && $top_test->{type} eq 'TL')
            {
                $self->{current_tl} = $top_test;
            }
        }
        $self->{idx}++;
        $cur_item = $self->{List}[$self->{idx}];
        $cur_case = $cur_item->{item};
        $cur_state = $cur_item->{state};
    }
    #print ">>> index[a] = $self->{idx}\n";
    #print ">>> $cur_case->{type} :: $cur_case->{Name} :: $cur_state\n";
    $self->{idx}++;
    #if ($cur_case->{type} eq 'TC')
    if ($cur_case)
    {
        #print Dumper $self->{stack};
        #print ">>> stack size = " . @{$self->{stack}} ."\n";
        $self->{current_tc} = $cur_case;
        $self->{doing_tc_cnt}++;
        return $cur_case;
    }
    else
    {
        $self->report_tot_bottom;
        if ($main::cfg->{TIME_STAT} eq 'YES')
        {
            $self->report_time_stat_per_tc;
        }
        $self->{current_tc} = undef;
        #$self->report_TSERROR;
        return;
    }
}


sub get_tc_old
{
    my $self = shift; 
    my ($tl,$ts,$tc); # Current TestList TestSuite TestCase

TL: do
    {
        $tl = $self->{List}[$idx_tl]; 
        return unless $tl;
        $_tl = $tl;

TS:     do
        {
            $ts = $tl->{List}[$idx_ts]; 

            do
            {
                ++$idx_tl; 
                $idx_ts = 0;

                $self->report_TL_bottom($_tl) unless $main::cfg->{LST};
                #$self->report_TSERROR;             
                goto TL
            } unless ($ts);

            $_ts = $ts;    

TC:         do
            {  
                $tc = $ts->{List}[$idx_tc];
                do
                {  
                    ++$idx_ts; 
                    $idx_tc = 0; 
                    $self->report_TS_bottom($_ts) unless $main::cfg->{LST};
                    goto TS
                } unless ($tc);
                ++$idx_tc;
            }; # Test Case

            $self->report_TS_header($ts) if $idx_tc == 1;
        }; # Test Suite
    }; # Test List

    return $tc;
};

sub put_failed_test
{
    my $self = shift;
    my $cur_test = shift;

    my $parent_test;
    if ( @{$self->{stack}} > 0 )
    {
        $parent_test = $self->{stack}[@{$self->{stack}}-1];
        push @{$parent_test->{failed_list}}, $cur_test;
        #print Dumper $parent_test;
    }
    if ( $cur_test->{type} =~ /TL/ )
    {
        $self->{tl_fail_count}++;
        # Don't put it to TSERROR list
        return;
    }
    elsif ( $cur_test->{type} =~ /TS/ )
    {
        $self->{ts_fail_count}++;
    }
    elsif ( $cur_test->{type} =~ /TC/ )
    {
        $self->{tc_fail_count}++;
        if (@{$self->{stack}} > 0)
        {
            $parent_test = $self->{stack}[@{$self->{stack}}-1];
        }
        else
        {
            $parent_test = undef;
        }
        $self->report_TSERROR($parent_test, $cur_test);
    }
    push @TSERROR, $cur_test;
}

sub get_current_TS_name
{
    my $self = shift;

    if (@{$self->{stack}} > 0)
    {
        my $parent_test = $self->{stack}[@{$self->{stack}}-1];
        return $parent_test->{Name};
    }
    else
    {
        return "NO TS";
    }
}

# -* Common Report TestList/TestSuite/ 

sub report_TEST_ALL
{
    my $self = shift;
    my $out;

    my @tm = gettimeofday();
    $self->{ElapseTime} = $tm[0];

    #$self->_print ("="x75 ."\n");
    #$self->_display ("="x75 ."\n") if $main::cfg->{Verbose};
    $out = sprintf "ATC TEST REPORT [ Test Lists : %lu, Test Suites : %lu, Test Cases : %lu ]\n",
                       $self->{tl_count}, $self->{ts_count},$self->{tc_count}   ;
  
    $self->_print ($out);
    $self->_display ($out) if $main::cfg->{Verbose};
    #$self->_print ("="x75 ."\n");
    #$self->_display ("="x75 ."\n\n") if $main::cfg->{Verbose};
}
sub report_tot_bottom
{
    my $self = shift;
    my $out;

    #$self->_print ("\n". "="x75 ."\n");
    #$self->_display ("\n". "="x75 ."\n") if $main::cfg->{Verbose};
    
    my @tm = gettimeofday();
    $self->{ElapseTime} = $tm[0] - $self->{ElapseTime};

    $out = sprintf "ATC TEST RESULT [ Test Lists : %lu/%lu, Test Suites : %lu/%lu, Test Cases : %lu/%lu ] Elapsed : %d sec %s.\n",
             $self->{tl_count} - $self->{tl_fail_count}, $self->{tl_count},
             $self->{ts_count} - $self->{ts_fail_count}, $self->{ts_count},
             $self->{tc_count} - $self->{tc_fail_count}, $self->{tc_count},
             $self->{ElapseTime}, $self->{EndTime};

    $self->_print ($out);

    $out = sprintf "ATC TEST RESULT [ Test Lists : %lu/%lu, Test Suites : %lu/%lu, Test Cases : %lu/%lu ] Elapsed : %d sec.\n",
             $self->{tl_count} - $self->{tl_fail_count}, $self->{tl_count},
             $self->{ts_count} - $self->{ts_fail_count}, $self->{ts_count},
             $self->{tc_count} - $self->{tc_fail_count}, $self->{tc_count},
             $self->{ElapseTime};

    $self->_display ($out) if $main::cfg->{Verbose};
    #$self->_print ("="x75 ."\n");
    #$self->_display ("="x75 ."\n") if $main::cfg->{Verbose};
}

sub report_TL_header 
{
    my $self = shift;
    my $tl   = shift;

    my @tm = gettimeofday();
    $tl->{ElapseTime} = $tm[0];

    my $indent_size = @{$self->{stack}}*3;
    my $space_size  = 25 - length($tl->{Name});
    $space_size = 1 if $space_size < 0;
    my $filled_name = $tl->{Name} . "."x$space_size;

    #print ">>> TL::header ::$indent_size\n";
    return unless $tl;

    $self->_print  (" "x$indent_size . "- $filled_name # $tl->{desc}\n");
    $self->_display(" "x$indent_size . "- $filled_name # $tl->{desc}\n") 
        if $main::cfg->{Verbose};
};

sub report_TL_bottom 
{
    my $self = shift;     
    my $tl   = shift;
    my ($tl_fail,$ts_fail) = (0,0);
    my $indent_size = @{$self->{stack}} * 3;
    my $space_size  = 25 - length($tl->{Name});
    my $filled_name = $tl->{Name} . "."x$space_size;
    my $pass_or_fail = "PASS";
    #print ">>> TL::bottom ::$indent_size\n";

    $space_size = 1 if $space_size < 0;
    foreach my $test_item (@{$tl->{failed_list}})
    { 
        if ( $test_item )
        {
            if ( $test_item->{failed_list} )
            {
                if ( $test_item->{type} eq 'TS' )
                {
                    ++$ts_fail;
                } 
                elsif ( $test_item->{type} eq 'TL' )
                {
                    ++$tl_fail;
                }
            }
            $pass_or_fail = "FAIL";
        }
    };  
    if ($pass_or_fail =~ /FAIL/)
    {
        $self->put_failed_test($tl);
    }

    my @tm = gettimeofday();
    $tl->{ElapseTime} = $tm[0] - $tl->{ElapseTime};

    my $out;
    $out  = sprintf "%s- %s %s TL=%2d/%2d, TS=%2d/%2d\n"
                ," "x$indent_size, $filled_name, $pass_or_fail, 
                $tl_fail, $tl->{tl_count}, 
                $ts_fail, $tl->{ts_count};
    $self->_print  ($out);
    $self->_display($out) if $main::cfg->{Verbose};
    #$main::TC_ERRORS = $tc_errors;

};

sub report_TS_header
{
    my $self = shift;
    my $ts   = shift;
    #    my $out  = "  Test Caseses:$ts->{file}\t# $ts->{desc}\n";   

    my @tm = gettimeofday();
    $ts->{ElapseTime} = $tm[0];

    my $indent_size = @{$self->{stack}} * 3;
    my $space_size  = 25 - length($ts->{Name});
    my $filled_name = $ts->{Name} . "."x$space_size;
    #print ">>> TS::header ::$indent_size\n";

    $space_size = 1 if $space_size < 0;
    #my $out = " "x$indent_size .  " " . "*"x50 . "\n" 
    #. " "x$indent_size .  " " . "-"x50 . "\n";
    my $out = " "x$indent_size .  " + " . $filled_name . "# " . $ts->{desc}. "\n";

    $self->_print  ($out);
    $self->_display($out) if $main::cfg->{Verbose} ;
};

sub report_TS_bottom 
{
    my $self = shift;     
    my $ts   = shift;
 
    my ($tc) =  (0,0,0) ;
    my ($ts_fail, $tc_fail) = (0,0);
    my $test_item;
    my (@fail_tc);

    my $indent_size = @{$self->{stack}}  * 3;
    my ($out,$str) = ('','');     
    my $space_size ;
    my $filled_name ;
    if ( @{$self->{stack}} > 0 )
    {
        $indent_size = (@{$self->{stack}} +1 )  * 3;
    }
    else
    {
        $indent_size = 0;
    }
    #print ">>> TS::bottom ::$indent_size\n";
     
    foreach $test_item (@{$ts->{failed_list}})
    { 
        if ( $test_item )
        {
            if ( $test_item->{type} eq 'TC' )
            {
                $tc = $test_item;
                if ( $tc->{plan} != $tc->{ok} ) 
                {
                    ++$tc_fail;
                    #push @TSERROR,$tc;
                    if ($indent_size == 0)
                    {
                        $indent_size = 3;
                    }
                    $space_size  = 25 - length($tc->{Name});
                    $space_size = 1 if $space_size < 0;
                    $filled_name = $tc->{Name} . " "x$space_size;
                    $str = $str.sprintf "%s X %s FAIL: Sector ",
                                " "x$indent_size , $filled_name;
                    foreach (@{$tc->{fail}})
                    {
                        $str .= $_.",";
                    };
                    $str =  $str."\n";
                };
            } elsif ( $test_item->{type} eq 'TS' )
            {
                if ( $test_item->{failed_list} )
                {
                    ++$ts_fail;
                    if ($indent_size == 0)
                    {
                        $indent_size = 3;
                    }
                    $space_size  = 25 - length($test_item->{Name});
                    $space_size = 1 if $space_size < 0;
                    $filled_name = $test_item->{Name} . "."x$space_size;
                    $str = $str.sprintf "%s X %s FAIL ",
                                " "x$indent_size , $filled_name;
                    $str =  $str."\n";
                }
            }
        }
    };  

    my @tm = gettimeofday();
    $ts->{ElapseTime} = $tm[0] - $ts->{ElapseTime};
          

    if ($tc_fail > 0 || $ts_fail > 0)
    {
        if ($indent_size == 0)
        {
            $indent_size = 3;
        }
        $space_size  = 25 - length($ts->{Name});
        $space_size = 1 if $space_size < 0;
        $filled_name = $ts->{Name} . "."x$space_size;
        $out = sprintf  "%s + %s FAIL TS=%2d/%2d, TC=%2d/%2d, %s\n", 
                   " "x$indent_size , $filled_name,  $ts_fail, $ts->{ts_count}, 
                   $tc_fail, $ts->{tc_count},  $ts->{desc};
        $self->put_failed_test($ts);
    }
    else
    { 
        if ($indent_size == 0)
        {
            $indent_size = 3;
        }
        $space_size  = 25 - length($ts->{Name});
        $space_size = 1 if $space_size < 0;
        $filled_name = $ts->{Name} . "."x$space_size;
        $out = sprintf  "%s + %s PASS TS:%4d,TC:%4d # %s\n", 
                        " "x$indent_size , $filled_name,$ts->{ts_count}, 
                        $ts->{tc_count}, $ts->{desc};
    };
   
    #$str = $str." "x$indent_size . " ************************************************\n" if $str;
    #$out =  "\n". " "x$indent_size . " ================================================\n". $out; 
 
    $self->_print ($out , $str);
    $self->_display ($out, $str);
    #$self->_print  ($out,
    #" "x$indent_size ." ------------------------------------------------\n",$str);
    #$self->_display($out,
    #" "x$indent_size ." ------------------------------------------------\n",$str) 
    #if $main::cfg->{Verbose};

};


sub report_TSERROR_open
{
    my $self = shift;

    $self->{error_fd} = new IO::File ($self->{TSERROR},'w');
    unless ($self->{error_fd}) 
    {     
        print $main::ERR "I can't write TSERROR to file $self->{TSERROR} \n";
        return 0;
    }; 
    $self->{error_fd}->print(<< "HEAD");

TestSuiteDescription     =   Test for Test Case where have got FAIL test
#########################################################################
HEAD
}

sub report_TSERROR_close
{
    my $self = shift;

    $self->{error_fd}->close;
}

sub report_TSERROR 
{
    my $self = shift;
    my $ts   = shift;
    my $tc   = shift;


    if ($ts)
    {
        $self->{error_fd}->printf( "%s # %s #%s\n",
                             $tc->{file} ,$tc->{desc}, $ts->{Name});
    }
    else
    {
        $self->{error_fd}->printf( "%s # %s #%s\n",
                             $tc->{file} ,$tc->{desc}, "NO TS");
    }
    $self->{error_fd}->flush;

};

sub report_time_stat_per_tc
{
    my $self = shift;

    my $index = 0;

    my $time_log_fd = new IO::File $ENV{ATC_WORK}."/log/timestat.log", 'w' ;
    unless ($time_log_fd) 
    {
        print $main::ERR "WARN:Can't open log file for time stat\n";
        &main::_exit(255);
    }

    my $cur_item = $self->{List}[$index];

    my $cur_case = $cur_item->{item};
    my $cur_state = $cur_item->{state};

    while ( $cur_case )
    {
        #if($cur_case->{type} eq 'TC')
        if ($cur_state eq 'E')
        {
			if ($self->{ElapseTime} == 0)
			{
				$self->{ElapseTime} = 1;
			}
            my $out_str = sprintf "%s %s %d %5.2f%s\n", $cur_case->{type}, $cur_case->{file}, $cur_case->{ElapseTime}, ($cur_case->{ElapseTime} * 100 / $self->{ElapseTime}, '%') ;
            print $time_log_fd $out_str;
        }
        $index++;
        $cur_item = $self->{List}[$index];
        $cur_case = $cur_item->{item};
        $cur_state = $cur_item->{state};
    }
    $time_log_fd->close;
}

sub _is_fail_all
{
    my $self = shift; 
    my ($tl,$ts,$tc); 
    my ($plan,$fail) = (0,0);     

    foreach $tl (@{$self->{List}})
    {
        foreach $ts (@{$tl->{List}})
        {
            foreach $tc (@{$ts->{List}}) 
            {
                last unless defined($tc->{plan});
                unless ($tc->{plan} == $tc->{ok})
                { 
                    ++$fail;
                    $tc->{desc} = $ts->{Name};
                    push @TSERROR,$tc;
                }
                ++$plan;
            }
        }
    }
    return ($plan,$fail);
};

sub load_ts_map
{ 
    my $self = shift;
    my $fd = new IO::File ($main::cfg->{DBT_MAP},'r') || do
            {    
                print $main::ERR 
                      "I can't open file DB $main::cfg->{DBI_MAP} for read: \n";
                return undef;
            };

    while (<$fd>) { 
        chomp;
        next if (s/^\|//);
        my %_ts;

        ($_ts{name}, $_ts{path},$_ts{desc}) =  split /[\t\s]*\#[\s\t]*/,$_;
        $_ts{ismap} = 1;
        $DBT_MAP{file}{basename($_ts{file})} = \%_ts; # HASH index for File
        $DBT_MAP{TS  }{            $_ts{name}} = \%_ts; # HASH index for TC
    };

    $fd->close;     
};


sub _print
{
    my($self, @msgs) = @_;
    local($\, $", $,) = (undef, ' ', '');
    print $main::REP @msgs;
};

sub _display
{
    my($self, @msgs) = @_;
    local($\, $", $,) = (undef, ' ', '');
    print $main::DIS @msgs;
};

sub _parse_pg()
{
    my ($self, $a, @b) = @_;
    my $run = undef;
    my $s1  = undef;
    my @s2  = undef;
    my $s3  = undef;

    if( $a =~ /\^/ )
    {
        $_ = $a;
        /\[\^(\w+)\](.+)/;

        $s1 = $1;
        if( defined($s1) == 0 )
        { 
            return 1;
        }
        @s2 = $self->{pg_value}{$s1};
        if( defined($s2[0]) == 0 )
        { 
            return 1;
        }
        $s3 = 0;

        for( $a = 0; $a <= $#s2; $a++ )
        {
            if( $s2[$a] =~ /$self->{local_ip}/ )
            {
                $s3 = 1;
            }
        }

        if( $s3 == 0 )
        {
            $run = 1;
        }
        else
        {
            $run = 0;
        }
    }
    else
    {
        $_ = $a;
        /\[(\w+)\](.+)/;

        $s1 = $1;
        if( defined($s1) == 0 )
        { 
            return 1;
        }
        @s2 = $self->{pg_value}{$s1};
        if( defined($s2[0]) == 0 )
        { 
            return 1;
        }
        $s3 = 0;

        for( $a = 0; $a <= $#s2; $a++ )
        {
            if( $s2[$a] =~ /$self->{local_ip}/ )
            {
                $s3 = 1;
            }
        }

        if( $s3 == 1 )
        {
            $run = 1;
        }
        else
        {
            $run = 0;
        }
    }

    return $run;
}

 
BEGIN {


};


1;
