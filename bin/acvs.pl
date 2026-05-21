#!/usr/local/bin/perl
use lib $ENV{ATC_HOME} . '/lib' ;

use strict;
use IO::File;
use File::Basename;

    if ($#ARGV == -1 || $ARGV[0] =~ "-h")
    {
       print "==================================================\n";
       print "usage\n";
       print "==================================================\n";
       exit;
    }

    my $type = '';
    my $addLines = 0;
    my $chgLines = 0;
    my $chgLines_old = 0;
    my $chgLines_new = 0;
    my $delLines = 0;
    my $cmd_str = "cvs diff -bw -r 1.3 -r 1.4 smnDef.h";
    open(CVSIN, 'cvs diff -bw -r 1.5 -r 1.6 smnDef.h |');
    while (<CVSIN>)
    {
        #print $_;
        if (/^(\d,*\d*)*(d|c|a)(\d)+/)
        {
            if ($2 =~ 'a')
            {
                $type = 'ADD';
            }
            elsif ($2 =~ 'd')
            {
                $type = 'DEL';
            }
            elsif ($2 =~ 'c')
            {
                $type = 'CHG';
            }
            next;
        }
        if (!/\$Id/)
        {
            if ($type =~ 'ADD')
            {
                $addLines++;
            }
            elsif ($type =~ 'DEL')
            {
                $delLines++;
            }
            elsif ($type =~ 'CHG')
            {
                if (/^\>/)
                {
                    $chgLines_new++;
                }
                elsif (/^\</)
                {
                    $chgLines_old++;
                }
            }
        }
    }
    print "ADD : $addLines\n";
    print "CHG : $chgLines_old -> $chgLines_new\n";
    print "DEL : $delLines\n";



