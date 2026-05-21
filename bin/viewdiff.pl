#!/usr/bin/perl
use lib $ENV{ATC_HOME} . '/lib' ;

use strict;
use IO::File;
use AltibaseInfo;
use File::Basename;
use TSmap;

my $pwd = $ENV{PWD} . "/";
my $test_case_path = $ENV{ATAF_TEST_CASE};
my $test_result_path = $ENV{ATAF_TEST_RESULT};

    if ($#ARGV == -1 || $ARGV[0] =~ "-h")
    {
       print "==================================================\n";
       print "[viewlst.pl] usage\n";
       print "==================================================\n";
       print "viewlst.pl options test_script_file]\n";
       print "\n";
       print "options:\n";
       print "           -h : help\n";
       print "\n";
       print "test_script_file = [TS name::]script file\n";
       print "\n";
       print "eg) viewlst.pl sys1.sql\n";
       print "    viewlst.pl sqlsys.ts::sys1.sql\n";
       print "==================================================\n";
    
       exit;
    }

	my $tsmap = new TSmap;

	my @par = split /::/, $ARGV[0];
	my $opt = $ARGV[1];

	#print ">>> arg : $par[0] :: $par[1]\n";
    my $file = $par[1];

	if ($par[0] =~ /\.ts/)
	{
		my $fd = new IO::File $file, 'r';
		if ($fd)
		{
			$fd->close;
		}
		else
		{
	        my $ts_path = $tsmap->find_path_TS_map($par[0]);
			#print ">>> ts path :: $ts_path\n";
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

	my $need_lst=0;
	my $need_out=0;
	my $need_src=0;


    my $altiInfo = new AltibaseInfo();
	my $file_ext = $altiInfo->get_file_ext();

    my $have_tc = grep /\/TC/, $pwd;
    my $have_atc = grep /\/atc/, $pwd;

    my $out_file = "";
    my @now_path = "";
    my $is_add_path = 0;

    my $final_case_path = "";
    my $final_result_path = "";

    my $lst_file = "";

    ###################################################
    # atc/TC에서 viewdiff.pl을 실행시킨 경우,
    # ATAF_TEST_CASE와 ATAF_TEST_RESULT의 PATH를 찾아서 
    # lst와 out을 비교해야 한다.
    ###################################################
    # lst의 경로 구하는 부분
    ###################################################
    if ( $have_tc == 1 && $have_atc == 1 )
    {
        # out file의 경로를 test_result의 경로에 맞게 치환하는 작업
        @now_path = split( /\//, $pwd );

        my $i = 0;
        my $token = "";
        my $token2 = "";

        while( @now_path )
        {
            $token = shift @now_path ;

            if ( $token eq "TC" || $is_add_path == 1 )
            {
                # TC부터 그 이후에 나오는 path
                $token2 = $token2 . "/" . $token;
                $is_add_path = 1;
            }
        }
        $final_case_path = $test_case_path . $token2 . "/";
    }

    my $file_name1 = "";
    my $file_name2 = "";
    my $file_name3 = "";
    my $file_name4 = "";
    my $file_name5 = "";
    my $file_name6 = "";

    if($altiInfo->{"bit"} == 64)
    {
	$file_name1 = $file_wo_ext . "_" . $altiInfo->{"endian"} . $file_ext . ".lst";
        $file_name2 = $file_wo_ext . "_" . $altiInfo->{"os"} . $file_ext . ".lst";
        $file_name3 = $file_wo_ext . $file_ext . ".lst";

        if(-e $final_case_path . $file_name1)
        {
            $lst_file = $final_case_path . $file_name1;
        }

        elsif(-e $final_case_path . $file_name2)
        {
            $lst_file = $final_case_path . $file_name2;
        }

        elsif(-e $final_case_path . $file_name3)
        {
            $lst_file = $final_case_path . $file_name3;
        }
    }
    else
    {
        $file_name1 = $file_wo_ext . "_" . $altiInfo->{"endian"} . $file_ext . ".lst";
        $file_ext =~ s/32$/64/;
        $file_name2 = $file_wo_ext . "_" . $altiInfo->{"endian"} . $file_ext . ".lst";
        $file_ext =~ s/64$/32/;
        $file_name3 = $file_wo_ext . "_" . $altiInfo->{"os"} . $file_ext . ".lst";
        $file_ext =~ s/32$/64/;
        $file_name4 = $file_wo_ext . "_" . $altiInfo->{"os"} . $file_ext . ".lst";
        $file_ext =~ s/64$/32/;
        $file_name5 = $file_wo_ext . $file_ext . ".lst";
        $file_ext =~ s/32$/64/;
        $file_name6 = $file_wo_ext . $file_ext . ".lst";

        if(-e $final_case_path . $file_name1)
        {
            $lst_file = $final_case_path . $file_name1;
        }
        elsif(-e $final_case_path . $file_name2)
        {
            $lst_file = $final_case_path . $file_name2;
        }
        elsif(-e $final_case_path . $file_name3)
        {
            $lst_file = $final_case_path . $file_name3;
        }
        elsif(-e $final_case_path . $file_name4)
        {
            $lst_file = $final_case_path . $file_name4;
        }
        elsif(-e $final_case_path . $file_name5)
        {
            $lst_file = $final_case_path . $file_name5;
        }
        elsif(-e $final_case_path . $file_name6)
        {
            $lst_file = $final_case_path . $file_name6;
        }
    }

    $is_add_path = 0;

    ###################################################
    # atc/TC에서 viewdiff.pl을 실행시킨 경우,
    # ATAF_TEST_CASE와 ATAF_TEST_RESULT의 PATH를 찾아서 
    # lst와 out을 비교해야 한다.
    ###################################################
    # lst의 경로 구하는 부분
    ###################################################
    if ( $have_tc == 1 && $have_atc == 1 )
    {
        # out file의 경로를 test_result의 경로에 맞게 치환하는 작업 
        @now_path = split( /\//, $pwd );

        my $i = 0;
        my $token = "";
        my $token2 = "";

        while( @now_path )
        {
            $token = shift @now_path ;
            #print "!!! $token\n";

            if ( $token eq "TC" || $is_add_path == 1 )
            {
                # TC부터 그 이후에 나오는 path
                $token2 = $token2 . "/" . $token;
                $is_add_path = 1;
            }
        }
        $final_result_path = $test_result_path . $token2 . "/";

        $out_file = $final_result_path . $file_wo_ext . $altiInfo->get_file_ext . ".out";

        print "TEST_ORACLE_PATH: $lst_file\n";
        print "TEST_RESULT_PATH: $out_file\n\n";
    }
    else
    {
        $out_file = $file_wo_ext . $altiInfo->get_file_ext . ".out";

        print "TEST_ORACLE_PATH: $lst_file\n";
        print "TEST_RESULT_PATH: $out_file\n\n";
    }

        my $src_file = $file_wo_ext . ".sql";

	my $cmd_str  = '';

	if ($opt eq 'o')
	{
		$cmd_str = "vi $out_file";
		$need_out = 1;
	}
	elsif ($opt eq 'l')
	{
		$cmd_str = "vi $lst_file";
		$need_lst = 1;
	}
	elsif ($opt eq 's')
	{
		$cmd_str = "vi $src_file";
		$need_src = 1;
	}
	else 
	{
		 $cmd_str = "tkdiff $lst_file $out_file";
		 $need_out = 1;   
                 $need_lst = 1; 
		
	}


    if ($need_lst == 1 && ! -e $lst_file)   
    { 
=change   
                 if ($file_ext =~ /32$/)   
                 {   
                     $file_ext =~ s/32$/64/;   
                     $lst_file = $file_wo_ext . $file_ext . ".lst";   
=cut 
			if ($opt eq 'l')
			{
				$cmd_str = "vi $lst_file";
			}
			else
                        {
                                $cmd_str = "tkdiff $lst_file $out_file";
		        }
=change
		}
=cut
		if ( ! -e $lst_file)
		{
			 print "There is no such LST file ($lst_file)\n";
			 exit -1;
		}
	}

	if ($need_out == 1 && ! -e $out_file)   
     	{ 
         print "There is no such OUT file ($out_file)\n";   
         exit -1;   
        } 
					

	

    if ($need_src == 1 && ! -e $src_file)
    {
        print "There is no such SCRIPT file ($src_file)\n";
        exit -1;
    }

	exec($cmd_str) if ($file != -1) ;



