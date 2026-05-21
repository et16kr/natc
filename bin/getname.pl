#!/usr/local/bin/perl
use lib $ENV{ATC_HOME} . '/lib' ;

use strict;
use IO::File;
use ConvName;

if ($#ARGV == -1 || $ARGV[0] =~ "-h")
{
   print "==================================================\n";
   print "[getname.pl] usage\n";
   print "==================================================\n";
   print "getname.pl options test_case_no command\n";
   print "\n";
   print "options:\n";
   print "           -h : help\n";
   print "\n";
   print "test_case_no = TCxxxyyy | yyy, where x means 0.\n";
   print "\n";
   print "command = some program or shell program which takes the file_name.\n";
   print "\n";
   print "eg) getname.pl TC000023 or getname.pl 23\n";
   print "    getname.pl 23 vi\n";
   print "==================================================\n";

   exit;
}

my $cmd;
my $file = "$ENV{ATC_HOME}/".ConvName::codeToName($ARGV[0]);
my $dummy = shift @ARGV;
   foreach (@ARGV)
   {
       $cmd.=' '. $_; 
   };
   print("$cmd $file \n") if ($cmd and $file != -1) ;
   exec("$cmd $file ") if ($cmd and $file != -1) ;
   
   if ( $file != -1)
   {    
       print "$file\n" ;
   }
   else
   {
       print "There is no script file for TestCase #$ARGV[0]\n";
   };
