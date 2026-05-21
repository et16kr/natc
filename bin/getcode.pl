#!/usr/local/bin/perl
use lib $ENV{ATC_HOME} . '/lib' ;

use strict;
use IO::File;
use ConvName;

if ($#ARGV == -1 || $ARGV[0] =~ "-h")
{
   print "==================================================\n";
   print "[getcode.pl] usage\n";
   print "==================================================\n";
   print "getcode.pl options test_case_name\n";
   print "\n";
   print "options:\n";
   print "           -h : help\n";
   print "\n";
   print "test_case_name = the name of a test case file\n";
   print "\n";
   print "eg) getcode.pl aggregation1.sql\n";
   print "==================================================\n";

   exit;
}

my $cmd;
my $file = "$ENV{ATC_HOME}/".ConvName::nameToCode($ARGV[0]);
   if ( $file != -1)
   {    
       print "$file\n" ;
   }
   else
   {
       print "There is no script file for TestCase #$ARGV[0]\n";
   };
