#!/usr/local/bin/perl
package main;
$^W=1;
# -*- Find module in local library -*- #

use lib $ENV{ATC_HOME}.'/lib';

# load modules
use strict;
use Data::Dumper;
use vars qw($IN $OUT  $ERR $LOG $REP  
	    @TestCase $tsh $ces $cfg $ex );
#use EServer();
use  TFSh;
$|=1;
$IN	= \*STDIN;
$OUT	= \*STDOUT;
$ERR	= \*STDERR; 
$LOG    = $ERR;
$REP    = $OUT;

use vars qw ($AUTOLOAD);

 $tsh=new TFSh (
	HistSize    => 100,		      # History Size 256 by default
	HistFile    => '.perlsh_history',# History File
	Strict      => 0,                     # No Strict Access to All varables
	InputStream => $IN ,		      # Input stream 
        OutputStream=> $OUT,		      # Output Stream
	PerlRC      => '.perlshrc',       # Resurce file Start and do after Load Module !!
	         			      # Your Cane Overload any Parametr from thea   !!
 );

## -*- Find any function not from package in shell  -*- ## 
## -*- Now your can start any program like function -*- ##

sub AUTOLOAD {
     my 	$program = $AUTOLOAD;
		$program =~ s/.*:://;  # trim package name
     my 	$pid = system($program, @_);
} 

#### -*- Do some RC file
if ( -f '.perlshrc') {do ".perlshrc"; print $ERR $@ };

Event::loop();
exit 0;

