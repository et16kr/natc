#!/usr/local/bin/perl
use lib $ENV{ATC_HOME} . '/lib' ;

use ALoc;
use strict;
use IO::File;
use File::Basename;
use Getopt::Long;

Getopt::Long::Configure('no_auto_abbrev');

use vars qw($depth  $mode @g_except_files);
$depth = 0;
$mode = 'MODULE';

open EXCEPT_FILE, $ENV{ATC_HOME} . '/bin/' . 'aloc_except_files.cfg' or die;

@g_except_files = <EXCEPT_FILE>;
close EXCEPT_FILE;

GetOptions(
	"help|h|?" => \&help,
	"depth|d|=i" => \$depth,
	"mode|m|=s" => \$mode
) || error (4);


    $mode = uc($mode);
    my $file_name = '';
    my $aloc = new ALoc;

    foreach $file_name (@ARGV)
    {
        $aloc->getLoc($file_name);
    }
    $aloc->printModule();


sub help
{
    print "HELP for Altibase Line of Code\n";
    print "=====================================================================\n";
    print "It counts only the following files: \n";
    print "   .c .cpp .h .java .l .y \n";
    print "arguments: \n";
    print "help  | h | ? : help\n";
    print "depth | d number : assign display depth on module hierarchy\n";
    print "      *** default is 0.. So, only total is displayed.\n";
    print "mode  | m [MODULE | FILE] : assign display details\n";
    print "                  MODULE  : display module only\n";
    print "                  FILE    : display file together\n";
    print "      *** default is MODULE\n";
    print "=====================================================================\n";
    exit 1;
};
