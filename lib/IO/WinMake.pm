package IO::WinMake;
use strict;
use Exporter;
use File::Basename;
use FileHandle;
use IO::File;

use vars qw($fileFullName $unixMakefile $winMakefile);
sub new
{
	my $class = shift; 
	$fileFullName = $_[0]; 
	$unixMakefile = $_[1]; 
	$winMakefile  = $_[2]; 

	# Head WhiteSpace Remove
	$fileFullName =~ s/\s+$//;
    $unixMakefile =~ s/\s+$//;
    $winMakefile  =~ s/\s+$//;
	# Tail WhiteSpace Remove
	$fileFullName =~ s/^\s+//;
    $unixMakefile =~ s/^\s+//;
    $winMakefile  =~ s/^\s+//;
    
	my $path    = GetCwd($fileFullName);  
	my $fdRead  = new IO::File;
	my $fdWrite = new IO::File;

    $fdRead->open($path.$unixMakefile, "r")
	    || return "Can't Open UnixMakeFile : [$path$unixMakefile] \n";
	    

    $fdWrite->open($path.$winMakefile, "w")
        || return "Can't Open WinMakeFile : [$path$winMakefile] \n";
        

   print $fdWrite "ALTIBASE_HOME=C:\\\\Altibase\\\\Altibase3_Server\n";
   print $fdWrite "ATC_HOME=C:\\\\cygwin\\\\home\\\\Administrator\\\\work\\\\atc\n";
   print $fdWrite "ALTIDEV_HOME=C:\\\\cygwin\\\\home\\\\Administrator\\\\work\\\\altidev\n";
   
   #print $fdWrite "ATC_HOME=/home/Administrator/work/atc\n";
   $fdWrite->autoflush();       
            
    while(<$fdRead>)
    {
        $_ =~ s/-l(\w)/-DEFAULTLIB:$1/g;   
        $_ =~ s/\.o/\.obj/g;                
        $_ =~ s/\.a/\.lib/g;                        
        $_ =~ s/\.so\.1/\.dll/g;                                        
        if ($_ =~ /-o/)
        {
            $_ =~ s/-o[ ]*/-out:/g;
        }
        elsif ($_ =~ /CC_OUTPUT_FLAG/)
        {
            $_ =~ s/\$\(CC_OUTPUT_FLAG\)[ ]*/\$\(CC_OUTPUT_FLAG\)/g;        
        }

        my ($ipos, $npos, $spos, $lpos) = (0,0,0,0);
        my ($spos1, $spos2) = (0,0);

        if ($_ =~ /include/)
        {
            #$_ =~ s/\//\\/g;
        }

        # altibase.env.mk altibase.env.win.mk
        if ($_ =~ /^include/)
        {
            $_ =~ s/altibase_env\.mk/altibase_env\.win\.mk/g;
=includecut            
            $_ =~ m/include/g;
            $ipos = pos $_;
	        $_ =~ m/\s/g;
	        $spos1 = pos $_;
	        $_ =~ m/[\s|\n]/g;
	        $spos2 = pos $_;	        
#print ">>>>>".$spos2.substr($_, $ipos+1, $spos2)."<<<\n";	        
            last if (!defined($ipos));
            $_ = substr($_, 0, $ipos+1)."\"".substr($_, $ipos+1, $spos2-$spos1-1)."\"".substr($_,$spos2-1);
=cut            
        }
        
        # INCLUDE
        if ($_ =~ /-I/)
        {
            $lpos = 0;
            $ipos = 0;
            $npos = 0;
            $spos = 0;
            $_ =~ s/\//\\/g;
            while(1)
            {
                pos $_ = $spos+2;
                $_ =~ m/-I/g;
                $ipos = pos $_;
	            $_ =~ m/[\s|\n]/g;
	            $spos = pos $_;
                last if (!defined($ipos));
                $_ = substr($_, 0, $ipos)."\"".substr($_, $ipos, $spos-$ipos-1)."\"".substr($_,$spos-1);
            }                
        }

        # LIB
        if ($_ =~ /-L/)
        {
            $lpos = 0;
            $ipos = 0;
            $npos = 0;
            $spos = 0;
        
            $_ =~ s/\//\\/g;
            $_ =~ s/-L/\-LIBPATH:/g; 
            while(1)
            {
                pos $_ = $spos+2;
                $_ =~ m/-LIBPATH:/g;
                $ipos = pos $_;
	            $_ =~ m/[\s|\n]/g;
	            $spos = pos $_;
                last if (!defined($ipos));
                $_ = substr($_, 0, $ipos)."\"".substr($_, $ipos, $spos-$ipos-1)."\"".substr($_,$spos-1);
            }                
        }
        print $fdWrite $_; 
        $fdWrite->autoflush();        
    }	    
};

sub GetCwd()
{
    my ($fileName, $path, $suffix) = fileparse($_[0]);
    return $path;
};

1;
