#!/usr/bin/perl
use vars qw(@ISA @EXPORT @EXPORT_OK $VERSION);

use Exporter;
use File::Basename;
@ISA=qw(Exporter);
@EXPORT=qw( help );

sub help { 
 my $help=shift; ## May be in future we used that for Help Systems
 my $text_v = "\nTestDriver ALTIBASE inc.\n";
 my $progname = basename($0);
 my $here = <<EOF;
========================================
Usage:  $progname  TC... TS... TL...

 -h,   --help, -?       Show this help
 -c,   --conf           <Config  file>  (by Default conf/$progname.conf )
 -sh   --shell		After start go to perl shell mode    
			it can execute any programm like   isql() ... e.t.c
 -v    --verbose	Verbouse  mode  0 1/2/3
 -p    --port 		PORT Servers
 -s    --server		PORT Servers
 -d    --debug    	DEBUG Level bitwise 1|2|4 (-d 1+2+4)
					    1 - lock/unlock state between process
					    2 - internal lock/unlock for each stmt
					    4 - statment and timing show
					    
 -lst  --listing 	Make Listing 'lst'  1 - file 
					    2 - in sql_db
 -pl   --printlevel			    Print level for PRINT stmt in SQL
					    
       --ok_diff        Method of ok_diff   1 - Fast Compare and Make Output 
    					    2 - Make diff structure		    
    			
EOF

  $text_v.=$here;
  print $text_v;
 exit 0; 
}


1;
