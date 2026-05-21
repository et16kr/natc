#!/usr/bin/perl
use vars qw(@ISA @EXPORT @EXPORT_OK $VERSION);

use Exporter;
@ISA=qw(Exporter);
@EXPORT=qw( error warning );

# Show help and exit...

my @error=(					# Eroor Code
    "Not enough command-line options",		# 1 
    "Please specify not more than  once",	# 2
    "Sorry I cant Open Config File",		# 3
    "Incorrect command line options",		# 4
    
);



sub error {
 my $error=shift;     
    if(defined($error)) { print $main::ERR "Error: $error[$error-1]\n" }
   else { $error=0 }
  exit($error);
 }

# Take warn KEY;

sub warning 
 {
   my $key;

 };



1;
