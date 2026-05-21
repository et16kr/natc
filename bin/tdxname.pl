#!/usr/local/bin/perl
use lib $ENV{ATC_HOME} . '/lib' ;

use strict;
use IO::File;
use AltibaseInfo;
use File::Basename;
use TSmap;

    if ($#ARGV == -1 || $ARGV[0] =~ "-h")
    {
       print "==================================================\n";
       print "[viewout.pl] usage\n";
       print "==================================================\n";
       print "viewout.pl options test_script_file]\n";
       print "\n";
       print "options:\n";
       print "           -h : help\n";
       print "\n";
       print "test_script_file = [TS name::]script file\n";
       print "\n";
       print "eg) viewout.pl sys1.sql\n";
       print "    viewout.pl sqlsys.ts::sys1.sql\n";
       print "==================================================\n";
    
       exit;
    }

	my $tsmap = new TSmap;
	my $target = 'OUT';

	my @par = split /::/, $ARGV[0];

	if ($ARGV[1])
	{
		$target = uc($ARGV[1]);
	}

	#print ">>> arg : $par[0] :: $par[1]\n";
    my $file = $par[1];

	if ($par[0] =~ /.ts/)
	{
		my $fd = new IO::File $file, 'r';
		if ($fd)
		{
			$fd->close;
		}
		else
		{
	        my $ts_path = $tsmap->find_path_TS_map($par[0]);
	        if ($ts_path)
	        {
			    $file = $ts_path . $file;
		    }
		};
	}
	else
	{
		$file = $par[0];
	}
		
    my $file_wo_ext = $file;

	$_ = $file;
    if (/.sql$/)
    {
       s/.sql$//;
       $file_wo_ext = $_;
       #print "new = $_\n";
    }

    my $altibase_info = new AltibaseInfo();
    my $ls_file;
    my $df_file;
    my $tdx_file;
    
	$ls_file = $file_wo_ext . $altibase_info->get_file_ext() . ".lst";
    $df_file = $file_wo_ext . $altibase_info->get_file_ext() . ".out";
    $tdx_file = $file_wo_ext . $altibase_info->get_file_ext() . ".tdx";
    
	if ($target eq 'LST')
	{
        if (! -e $ls_file)
        {
			my $file_ext = $altibase_info->get_file_ext();
			if ($file_ext =~ /32$/)
			{
				$file_ext =~ s/32$/64/;
				$ls_file = $file_wo_ext . $file_ext . ".lst";
			}
			if (! -e $ls_file)
			{
                print "There is no such LST file ($ls_file)\n";
                exit -1;
			}
        }
	    print("$ls_file") if ($file != -1) ;
	}

	if ($target eq 'OUT')
	{
        if (! -e $df_file)
        {
            print "There is no such OUT file ($df_file)\n";
            exit -1;
        }
	    print("$df_file") if ($file != -1) ;
	}
    
	if ($target eq 'TDX')
	{
        if (! -e $tdx_file)
        {
            print "There is no such TDX file ($tdx_file)\n";
            exit -1;
        }
	    print("$tdx_file") if ($file != -1) ;
	}
    

