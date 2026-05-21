package RepTL;
use strict;
eval{use Data::Dumper } if $main::DEBUG; 
use IO::File;
use File::Basename;

use vars qw($VERSION &plan &ok_sector $Test);
use Time::HiRes qw(gettimeofday  tv_interval );
$VERSION = 0.02;

use constant  OK_STR => 
    [
    'FAIL',   #0 Fail Test 
    'PASS',   #1 Pass Test
    'SKIP',   #2 Skip Test
    ]; # Array of String Reporting


sub new {
    my($class) = shift;
    $Test   = {
        # JAST TEST CASE #
        CurrentTestCase => {},
        # Local data 
        Test_Results    => (),
        Test_Details    => (),
        Test_Died       => 0,
        Have_Plan       => 0,
        Expected_Tests  => 0,
        Exported_To     => '',
        No_Plan         => 0, 
        Skip_All        => 0,    
        # Tuning Data
        Verbose         => 1,    # Verbose is bitmask by 1 - TL level ,2 - TS level, 3 - TC level 
        DirLst          => $main::LST,
        Out_Suffix      => '.out',
        Diff            => $main::DIFF,
        get_expect      => \&_load_lst_file_db,
        fd_out          => new IO::File,
        @_,
    };
    return bless $Test, $class;
}


sub ignore_sector 
 {
    my $self   = shift;
    my $sector = shift;

    my $tc = delete $self->{Expect}{$sector};
    my $reason = ($_[0] =~ /^\s*$/) ? $tc->{desc}: shift; 
    ++$self->{CurrentTestCase}{skip};   
    $self->ok(2,$sector,$reason);
}

sub check_remain_lst_sector
{
    my $self = shift;

    if (keys(%{$self->{Expect}}))
    {
        return "Y";
    }
    else
    {
        return "N";
    }
}

sub ok_sector
{
    my $self   = shift;
    my $isql   = shift;
    my $sector = shift;

	if ($main::cfg->{DIFF_POLICY} eq 'EXPRESS')
	{
		return $self->ok_sector_express($isql, $sector);
    }
	else
	{
		return $self->ok_sector_normal($isql, $sector);
    }
}

## SUCC FAIL
sub ok_sector_normal 
{
    my $self   = shift;
    my $isql   = shift;
    my $sector = shift || '0';

	no strict 'refs';

    my $got    = $isql->{OUT} || '';
    my $expect = $self->{Expect}{$sector}{lst} || '';

	if ( defined @{$expect}[$#{$expect}] &&
             @{$expect}[$#{$expect}] eq '' )
	{
		if (@{$got}[$#{$got}] ne '')
		{
			push @{$got}, @{$expect}[$#{$expect}];
		}
	}

    ## for DEBUG
=for debug
	print "\n>>> EXPECT $sector:\n";
	print Dumper $expect;
	print "\n>>> GOT $sector\n";
	print Dumper $got;
=cut
    # return  undef unless defined $expect;

    my $sector_result = 1;
    my $desc = $self->{Expect}{$sector}{desc} || '';    
    #print ">>>desc1=$desc----\n";
    #delete $self->{Expect}{$sector};
    #print ">>>desc2=$desc----\n";
    
#!This is for external diff Module
#!use Diff qw ( diff );
#!  my $diff = diff($expect,$got);
#!  my $res =  $#{$diff}+1;

#unless ($main::tb->ok((not $self->_is_diff($expect,$got)),$sector,$desc))  
#$main::tb->ok((not $self->_is_diff($expect,$got)),$sector,$desc);  
    # print OUT 

	#print "\n";
	#print Dumper $expect;
	#print Dumper $got;
    if ($main::ex->{is_parallel} eq 'Y')
    {
        my $out_index = $isql->{OutIndex};
        my $lst_index = 0;
=for debug
	    while (@{$expect}[$lst_index] !~ /^\-\-\+\s*SECTOR/)
	    {
		    $lst_index++;
	    }
	    while (@{$got}[$out_index] !~ /^\-\-\+\s*SECTOR/)
	    {
		    $out_index++;
	    }
=cut
        #print "\n>>> lst_index = $lst_index, out_index = $out_index\n";
        my $delta = $#{$got} - $isql->{OutIndex};
        my $delta_out = $#{$got} - $out_index;
		my $delta_lst = $#{$expect} - $lst_index;
		#print "\n$isql->{id_key}>$sector>> #of got :: $#{$got}, #of lst :: $#{$expect}, delta :: $delta, outidnex :: $isql->{OutIndex}\n";
        if ($delta_out != $delta_lst)
        {
			#print "\n>>> delta = $delta_out, #expect = $delta_lst\n";
            $sector_result = 0;
			#print Dumper @{$expect};
			#print Dumper @{$got};
        }
        #my $exp;
        #while ($_ = shift @{$got})
		my $out_string;
		my $lst_string;
        while ($sector_result == 1 && $out_index <= $#{$got})
        { 
            #$exp = shift @{$expect};
			$lst_string = @{$expect}[$lst_index];
			$out_string = @{$got}[$out_index];
            $out_string =~ s/^\. // if $out_string;
            ###$lst_string =~ s/^\. // if $lst_string;
            unless ( $out_string eq $lst_string )
			{
			    
				#print $main::REP "\n[LST:$sector] $lst_index : $lst_string\n";
				#print $main::REP "\n[OUT:$sector] $out_index : $out_string\n";
				#print Dumper @{$expect};
				#print Dumper @{$got};
                $sector_result = 0;
		    }
			#$sector_result = 0 unless ( @{$expect}[$lst_index] eq @{$got}[$out_index] );
            #$sector_result = 0 unless ( $exp eq $_ );

            $out_index++;
            $lst_index++;
        }
        $isql->{OutIndex} += ($delta+1);
    }
    else
    {
        my $fd = $self->{fd_out};
        unless ($fd->opened)
        {
            my $out_file = $main::tp->get_out_name($self->{CurrentTestCase}{file});
            $fd->open($out_file,'w') || die "I can't open $out_file $!\n "; 
        };

        if ($#{$got} != $#{$expect})
        {
            $sector_result = 0;
        }
        my $out_index = 0;
		my $out_string;
		my $lst_string;
        while ($out_index <= $#{$got})
        { 
            #print $fd $_."\n"; 
            my $file_out_str = @{$got}[$out_index];
            $file_out_str =~ s/^\. //;
            print $fd $file_out_str ."\n";
            if ($sector_result == 1)
            {
				$lst_string = @{$expect}[$out_index];
				$out_string = @{$got}[$out_index];
                $out_string =~ s/^\. // if $out_string;
                ###$lst_string =~ s/^\. // if $lst_string;
                unless ( $out_string eq $lst_string )
				{
                                #print $main::REP "<<< DIFF >>>\n";
				#print $main::REP "\n[LST:$sector] $out_index : $lst_string\n";
				#print $main::REP "\n[OUT:$sector] $out_index : $out_string\n";
                    $sector_result = 0;
			    }
				#$sector_result = 0 unless ( @{$expect}[$out_index] eq @{$got}[$out_index] );
            }
            $out_index++;
        }
        delete $isql->{OUT};
    }
    delete $self->{Expect}{$sector};

    $main::tb->ok($sector_result,$sector,$desc);  
	use strict;
};

sub ok_sector_express 
{
    my $self   = shift;
    my $isql   = shift;
    my $sector = shift || '0';

	no strict 'refs';

    my $got    = $isql->{OUT};
    my $expect = $self->{Expect}{$sector}{lst};
    my $desc   = $self->{Expect}{$sector}{desc} || '';    
=for modifying
    if (!$self->{Expect}{$sector})
    {
        $main::tb->ok(0,$sector,$desc);
        return;
    }
=cut 

    ## for DEBUG
=for debug
	print "\n>>> EXPECT:\n";
	print Dumper $expect;
	print "\n>>> GOT\n";
	print Dumper $got;
=cut
    # return  undef unless defined $expect;

    my $sector_result = 1;

    my $lst_string = '';
    my $out_string = '';
    
#!This is for external diff Module
#!use Diff qw ( diff );
#!  my $diff = diff($expect,$got);
#!  my $res =  $#{$diff}+1;

#unless ($main::tb->ok((not $self->_is_diff($expect,$got)),$sector,$desc))  
#$main::tb->ok((not $self->_is_diff($expect,$got)),$sector,$desc);  
    # print OUT 

    if ($main::ex->{is_parallel} eq 'Y')
    {
        #print Dumper $expect;
        #print Dumper $got;
        my $out_index = $isql->{OutIndex};
        my $lst_index = 0;
        my $delta = $#{$got} - $isql->{OutIndex};
        #my $exp;
                #$out_index += 4;
                #$lst_index += 4;
        #while ($_ = shift @{$got})
        while ($sector_result == 1 && $out_index <= $#{$got})
        { 
            #$exp = shift @{$expect};
=for temp
            while ($lst_index <= $#{$expect} && @{$expect}[$lst_index] !~ /^\./)
            {
                $lst_index++;
            }
            while ($out_index <= $#{$got} && @{$got}[$out_index] !~ /^\./)
            {
                $out_index++;
            }
=cut
            ### BUGBUG
            while ($lst_index <= $#{$expect} && 
                    ( @{$expect}[$lst_index] !~ /^\./ ||
                      @{$expect}[$lst_index] =~ /^\.\s+$/ ||
                      #@{$expect}[$lst_index] =~ /^\. =>/ ||
                      #@{$expect}[$lst_index] =~ /^\. >>>/ ||
                        (@{$expect}[$lst_index] =~ /^\. \[ERR/ &&
                         @{$expect}[$lst_index] !~ /\]$/
                        )
                    )
                  )
            {
                if ( $lst_index <= $#{$expect} && @{$expect}[$lst_index] =~ /^\. \[ERR/ &&
                     @{$expect}[$lst_index] !~ /\]$/ )
                {
                    while (@{$expect}[$lst_index] !~ /\]$/)
                    {
                        $lst_index++;
                    }
                }
                $lst_index++;
            }
            while ($out_index <= $#{$got} && 
                    ( @{$got}[$out_index] !~ /^\./ ||
                      @{$got}[$out_index] =~ /^\. \+\-\-/ ||
                      @{$got}[$out_index] =~ /^\. \-\-\+/ ||
                      @{$got}[$out_index] =~ /^\.\s+$/ ||
                        (@{$got}[$out_index] =~ /^\. \[ERR/ &&
                         @{$got}[$out_index] !~ /\]$/
                        )
                    )
                  )
            {
                if ( $out_index <= $#{$got} && @{$got}[$out_index] =~ /^\. \[ERR/ &&
                     @{$got}[$out_index] !~ /\]$/ )
                {
                    while (@{$got}[$out_index] !~ /\]$/)
                    {
                        $out_index++;
                    }
                }
                $out_index++;
            }
            ### BUGBUG - END
            if ($lst_index <= $#{$expect})
            {
                $lst_string = @{$expect}[$lst_index];
            }
            else
            {
                $lst_string = 'THE END FOR ATC';
            }
            if ($out_index <= $#{$got})
            {
                $out_string = @{$got}[$out_index];
            }
            else
            {
                $out_string = 'THE END FOR ATC';
            }
            if ($sector_result == 1)
            {
                $out_string =~ s/^\. //;
                $lst_string =~ s/^\. //;
                unless ( $out_string eq $lst_string )
                {
                    print $main::REP "[LST:$sector] $lst_index : $lst_string\n";
                    #print Dumper @{$expect};
                    print $main::REP "[OUT:$sector] $out_index : $out_string\n";
                    #print Dumper @{$got};
                    $sector_result = 0;
                }
            }

            $out_index++;
            $lst_index++;
            }
        if ($lst_index < $#{$expect})
	{
	    $sector_result = 1;
	}
        #print "$isql->{id_key}>$sector>> #of got :: $#{$got}, #of lst :: $#{$expect}, delta :: $delta, outidnex :: $isql->{OutIndex}\n";
        $isql->{OutIndex} += ($delta+1);
    }
    else
    {
        my $fd = $self->{fd_out};
        unless ($fd->opened)
        {
            my $out_file = $main::tp->get_out_name($self->{CurrentTestCase}{file});
            $fd->open($out_file,'w') || die "I can't open $out_file $!\n "; 
        };

        my $out_index = 0;
        my $lst_index = 0;
        $sector_result = 1;
        #while ($out_index <= $#{$got})
        while ($lst_string ne 'THE END FOR ATC' ||
               $out_string ne 'THE END FOR ATC')
        { 
            #print $fd $_."\n"; 
            my $file_out_str = @{$got}[$out_index];
            $file_out_str =~ s/^\. // if $file_out_str;
            print $fd $file_out_str ."\n" if $out_string ne 'THE END FOR ATC'; 
=for temp
            while ($lst_index <= $#{$expect} && @{$expect}[$lst_index] !~ /^\./)
            {
                $lst_index++;
            }
            while ($out_index <= $#{$got} && @{$got}[$out_index] !~ /^\./)
            {
                $out_index++;
                if ($out_index <= $#{$got})
                {
                    my $file_out_str = @{$got}[$out_index];
                    $file_out_str =~ s/^\. // if $file_out_str;
                    print $fd $file_out_str ."\n"; 
                    #print $fd @{$got}[$out_index] ."\n"; 
                }
            }
=cut
            ### BUGBUG
            while ($lst_index <= $#{$expect} && 
                    ( @{$expect}[$lst_index] !~ /^\./ ||
                      @{$expect}[$lst_index] =~ /^\.\s+$/ ||
                      #@{$expect}[$lst_index] =~ /^\. =>/ ||
                      #@{$expect}[$lst_index] =~ /^\. >>>/ ||
                        (@{$expect}[$lst_index] =~ /^\. \[ERR/ &&
                         @{$expect}[$lst_index] !~ /\]$/
                        )
                    )
                  )
            {
                if ( $lst_index <= $#{$expect} && @{$expect}[$lst_index] =~ /^\. \[ERR/ &&
                     @{$expect}[$lst_index] !~ /\]$/ )
                {
                    while (@{$expect}[$lst_index] !~ /\]$/)
                    {
                        $lst_index++;
                    }
                }
                $lst_index++;
            }
            while ($out_index <= $#{$got} && 
                    ( @{$got}[$out_index] !~ /^\./ ||
                      @{$got}[$out_index] =~ /^\. \+\-\-/ ||
                      @{$got}[$out_index] =~ /^\. \-\-\+/ ||
                      @{$got}[$out_index] =~ /^\.\s+$/ ||
                      #@{$got}[$out_index] =~ /^=>$/ ||
                      #@{$got}[$out_index] =~ /^>>>$/ ||
                        (@{$got}[$out_index] =~ /^\. \[ERR/ &&
                         @{$got}[$out_index] !~ /\]$/
                        )
                    )
                  )
            {
                if ( $out_index <= $#{$got} && @{$got}[$out_index] =~ /^\. \[ERR/ &&
                     @{$got}[$out_index] !~ /\]$/ )
                {
                    while (@{$got}[$out_index] !~ /\]$/)
                    {
                        $out_index++;
                        if ($out_index <= $#{$got})
                        {
                            my $file_out_str = @{$got}[$out_index];
                            $file_out_str =~ s/^\. // if $file_out_str;
                            print $fd $file_out_str ."\n"; 
                            #print $fd @{$got}[$out_index] ."\n"; 
                        }
                    }
                }
                $out_index++;
                if ($out_index <= $#{$got})
                {
                    my $file_out_str = @{$got}[$out_index];
                    $file_out_str =~ s/^\. // if $file_out_str;
                    print $fd $file_out_str ."\n"; 
                    #print $fd @{$got}[$out_index] ."\n"; 
                }
            }
            ### BUGBUG - END
            if ($lst_index <= $#{$expect})
            {
                $lst_string = @{$expect}[$lst_index];
            }
            else
            {
                $lst_string = 'THE END FOR ATC';
            }
            if ($out_index <= $#{$got})
            {
                $out_string = @{$got}[$out_index];
            }
            else
            {
                $out_string = 'THE END FOR ATC';
            }
            if ($sector_result == 1)
            {
                $out_string =~ s/^\. //;
                $lst_string =~ s/^\. //;
                unless ( $out_string eq $lst_string )
                {
                    print $main::REP "[LST:$sector] $lst_index : $lst_string\n";
                    #print Dumper @{$expect};
                    print $main::REP "[OUT:$sector] $out_index : $out_string\n";
                    #print Dumper @{$got};
                    $sector_result = 0;
                }
            }
            $out_index++;
            $lst_index++;
        }
        delete $isql->{OUT};
    }
    delete $self->{Expect}{$sector};

    $main::tb->ok($sector_result,$sector,$desc);  
	use strict;
};


sub _is_diff
{
    my $self   = shift;
    my $expect = shift;
    my $got    = shift;
    my ($exp,$gt);

    print ">>> diff cnt :: $#{$got} :: $#{$expect}\n";
    return 1 if ($#{$got} != $#{$expect});
=for debugging
    print ">>> expect\n";
    print Dumper $expect;
    print ">>> got\n";
    print Dumper $got;
    #return 1;
=cut

    foreach $gt( @{$got} )
    {
        $exp = shift @{$expect};
        return 1 unless ( $exp eq $gt );
    }

    return 0;    
}


# -* set test Case Enviroument *- #

*plan =  \&set_TC;

sub set_TC
{
    my ($sec,$min,$hour,$day,$mon,$year,$wday,$yday,$isdst);
    ($sec,$min,$hour,$day,$mon,$year,$wday,$yday,$isdst) = localtime(time);
    $year += 1900;  
    $mon++;
    if ($mon < 10) { $mon = "0$mon"; }
    if ($day < 10) { $day = "0$day"; }
    if ($hour < 10) { $hour = "0$hour"; }
    if ($min < 10)  { $min = "0$min"; }
    if ($sec < 10) { $sec = "0$sec"; }

    my($self, $cmd, $max,$tc) = @_;
#print "=>>>>>>>>>>>>>>>". $tc->{file}."\n";

    $tc->{BeginTime} = "[BT]". $year . "-" . $mon . "-" . $day . " " . $hour . ":" . $min . ":" . $sec;
  
    return unless $cmd;    

    my @tm = gettimeofday();
    $tc->{ElapseTime} = $tm[0];

    # -* Set Expect Cache structure *- #
    if ($tc)
    {
        my ($fname, $fpath, $fext)
                = fileparse ( $tc->{file}, '\.sql' );
        $self->{Expect} = &{$self->{get_expect}}($self,$fname); 
    } 
    else
    {
        return undef
    };

    $tc->{desc}='' unless defined ($tc->{desc});
    if( $cmd eq 'tests' ) 
    {
        if ( $max > 1 )  
        {
            my $indent_size = @{$main::tp->{stack}}*3;

            if ( $self->{Verbose} >= 3)
			{
                $self->_print  ("\n"." "x$indent_size . " # $tc->{Name} 1..$max\t$tc->{desc}\n");
                $self->_display("\n"." "x$indent_size . " # $tc->{Name} 1..$max\t$tc->{desc}\n");
		    }
        };

        $self->{CurrentTestCase}        = $tc;
        $self->{CurrentTestCase}{plan}  = $max;
        $self->{CurrentTestCase}{skip}  = 0;
        $self->{CurrentTestCase}{ok}    = 0;
   
   }
   else
   {
        return undef
   };

    # -* Make FileName *- #
    $self->{fd_out}->close() if $self->{fd_out}->opened();
    
 };

# -* Report Buttom of TestCase *- #
sub report_TC 
{
    my $self = shift;
    my $tc   = $self->{CurrentTestCase};
    my ($out,$ret);
    
    my @tm = gettimeofday();
    $tc->{ElapseTime} = $tm[0] - $tc->{ElapseTime};

    # erase the prompt line on the screen
    $main::DIS->printflush("\r"." "x68 . "\r");

    # -* Is all Ok ?? *- #
    $ret = $tc->{plan} - $tc->{ok};

    my ($fail,$str) = ('','');

    if ($ret || $self->check_remain_lst_sector eq 'Y')
    { 
        $main::tp->put_failed_test($tc);
        $str = OK_STR->[0]; # FALSE
        #! for more detail!    foreach (@{$tc->{fail}}){$fail.= $_ .','};
    }
    else
    {
        $str = OK_STR->[1];
        
         my $out_file = $main::tp->get_out_name($self->{CurrentTestCase}{file});
         unlink( $out_file );
    }; 
       
    my $depth = @{$main::tp->{stack}};
    my $indent_size = $depth * 3;
    my $space_size  = 25 - length($tc->{Name});
    my $filled_name = $tc->{Name} . "."x$space_size;
    $space_size = 1 if $space_size < 0;

    $out =  sprintf "%s # %s(%2d/%2d)...%.5s%s\t# %s %s\n",
                    " "x$indent_size , $filled_name, $tc->{ok},$tc->{plan},
                    $str, $fail,$tc->{desc}, $tc->{BeginTime};

    my $r_out = $out;                    

    $out =  sprintf "%s # %s(%2d/%2d)...%.5s%s\t# %s\n",
                    " "x$indent_size , $filled_name,$tc->{ok},$tc->{plan},
                    $str, $fail,$tc->{desc};

    my $d_out = $out;


    
    #my ($r_out,$d_out) = ($rout,$out);
         
    if (!$main::cfg->{RunAlone})
    {
        #$self->_display("[X]TS:".$main::tp->get_current_TS_name()."\n");
        $self->_display("[X]$tc->{Name}:$tc->{file}\n");
    }

    $self->_print($r_out) ; 
    $self->_display($d_out);

    return $ret;      
};

# Function Ok

sub ok 
{
    my($self, $ret,$t_no,$name) = @_;
    my $indent_size = @{$main::tp->{stack}} * 3;
    
    # -* FALSE/0 if undefined $test *- #   
    $ret = defined($ret) ? int $ret : int 0 ;

    if ( $self->{CurrentTestCase}{plan} > 1 )
    { 
        if ($self->{Verbose} >= 3)
        {
            $name = $name ? " #".$name."\n" : "\n";
            $t_no = $t_no ? $t_no : "0";    
            my $out = "...............";
        
            my $res = defined(OK_STR->[$ret]) ? OK_STR->[$ret] : OK_STR->[0];     
    
            $out = sprintf "%s   %.12s%.5s%s"," "x$indent_size,"$t_no$out",$res,$name;
            $self->_print("        ".$out);
    
            $self->_display($out);   
        };
    };

    # -* Registrate Resault of test *- #
    if ($ret)
    { 
        ++$self->{CurrentTestCase}{ok};   
    } 
    else 
    { 
        push @{ $self->{CurrentTestCase}{fail} }, $t_no;
    };
    return $ret;
}


# Set output file handler

sub output {
    my($self, $fh) = @_;
    if( defined $fh ) 
    {
        $self->{_output} = _new_fh($fh);
    }
    return $self->{_output};
}

# Set time log file handler

sub set_handle_time_log 
{
    my($self, $fh) = @_;
    if( defined $fh ) 
    {
        $self->{_time_log} = _new_fh($fh);
    }
    return $self->{_time_log};
}



# Set display file handler

sub display 
{
    my($self, $fh) = @_;
    if( defined $fh ) 
    {
        $self->{_display} = _new_fh($fh);
    }
    return $self->{_display};
}


# Set fail output file handler

sub failure_output 
{
    my($self, $fh) = @_;
    if( defined $fh ) 
    {
        $self->{_fail_output} = _new_fh($fh);
    }
    return $self->{_fail_output};
}

# Private subs

sub _print 
{
    my($self, @msgs) = @_;
    local($\, $", $,) = (undef, ' ', '');
    my $fh = $self->{_output};
    print $fh @msgs;
};

sub _display
{
    my($self, @msgs) = @_;
    local($\, $", $,) = (undef, ' ', '');
    my $fh = $self->{_display};
    print $fh @msgs;
};


# Open File or Set FH
sub _new_fh
{
    my($file_or_fh) = shift;
    my $fh;

    unless( UNIVERSAL::isa($file_or_fh, 'GLOB') ) 
    {
        $fh = do { local *FH };
        open $fh, ">$file_or_fh" or  die "Can't open test output log $file_or_fh: $!";
    } 
    else 
    {
        $fh = $file_or_fh;
    }
    return $fh;
};

# load diff to hash from file 

sub _load_lst_file_db 
{
    my $self   = shift;
    my $tc_lst = shift || return undef ;
    my (
        %diffs,
        $sect_ptr
    ); 

    print $main::DIS->printflush( "\r\[$main::ex->{TestCase}{Name}:I\] Loading lst:$tc_lst" ) 
    if $main::cfg->{Verbose} && $main::cfg->{BottomMsg};

    # -* Set for nodesc *- #       
    $sect_ptr  =  0;
    $diffs{$sect_ptr}{desc}= '';

    # -* Make FileName *- #
    $tc_lst = $main::tp->get_lst_name($main::ex->{TestCase}{file});
    #print "22222>>>> $tc_lst\n";
    my $Fail_FH  = $self->{_fail_output};
    
    my $lst = new IO::File($tc_lst,'r') || do 
    {
        print $Fail_FH "I can't Read LST file $tc_lst!\n";
        return undef
    };

    my $cnt = 0;
    my $line = '';
	my $prev_line = '';
    $sect_ptr = 0;
    while  (<$lst>)
    {
        chomp; 
		#next  unless $_;

        $line = $_;

        if(/^\-\-\+SECTOR\s+(.*)\;/)
        {
            my $prev_sect_ptr = $sect_ptr;
            $_ = $1; 
            my $desc = $';
            /^(\d+)[,\s]*.*/;
            $sect_ptr = int $1;
           
            $diffs{$sect_ptr}{desc}=$desc;

			if ($prev_line =~ /^\+\-\-/)
			{
			    my $line_1_before = pop @{$diffs{$prev_sect_ptr}{lst}};
		    
			    my $line_2_before = pop @{$diffs{$prev_sect_ptr}{lst}};
			    push @{ $diffs{$sect_ptr}{lst} },$line_2_before;
			    push @{ $diffs{$sect_ptr}{lst} },$line_1_before;
			}

            #### CAUTION ::: 
            ## eliminate each two lines before and after SECTOR from the file
            ## 
            ## this is related to the 'isql.pm'::ts_SECTOR;
            #shift @{$diffs{$sect_ptr}{lst}};
            #shift @{$diffs{$sect_ptr}{lst}};
            #$lst->getline;
            #$lst->getline;
        } 
        #### BUGBUG
=for temp
        if ($line =~ /^\$P/ ||
            $line =~ /^\+\-\-/ || 
            $line =~ /^\s+$/ ||
            $line =~ /^\-\-\+/)
        {
            push @{ $diffs{$sect_ptr}{lst} },$line;
        }
        else
        {
            push @{ $diffs{$sect_ptr}{lst} },". " . $line;
        }
=cut
        #### BUGBUG - END
		$prev_line = $line;
		push @{ $diffs{$sect_ptr}{lst} },$line;
        
    }; # end while

	#### BUGBUG treating last empty line;
=for temp
	my $last_line = pop @{$diffs{$sect_ptr}{lst}};
	if ($last_line !~ /^\s*$/)
	{
		print "\n>>> last line in lst file : $last_line\n";
		push @{$diffs{$sect_ptr}{lst}}, $last_line;
	}
=cut
	#### BUGBUG END
    #print Dumper %diffs;
    print $main::DIS "\r                                \r"
            if $main::cfg->{Verbose} && $main::cfg->{BottomMsg};

    $lst->close;
    return \%diffs;
};

1;
