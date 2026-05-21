#!/usr/local/bin/perl
package ConvName;
use strict;
use IO::File;

my $name = codeToName("sys1.sql");
print "name = $name\n";
#my $name = codeToName("TC000001");
#print "name = $name\n";
#$name = codeToName("TC00001");
#print "name = $name\n";
#$name = nameToCode("server_restart.sql");
#print "code = $name\n";
#$name = nameToCode("server_restat.sql");
#print "code = $name\n";

sub codeToName
{
    my $code = shift;
    
    my $fd= new IO::File $ENV{ATC_HOME}.'/conf/atc.conf','r';
       return -1 unless $fd ;
    my @conf = grep /^DBT_MAP/,$fd->getlines;   
    my $tc_no;
       $fd->close; 
       # -* Parse conf file *- #
       $conf[$#conf] =~ /[=\s\t]+(\S+)[\s\t]*$/;
       $fd= new IO::File $ENV{ATC_HOME}.'/'.$1,'r';
       return -1 unless $fd ;
       
       if ( $code =~ /^\d+$/ )
       {
           $tc_no = sprintf "TC%06d", $code;
       }
       else
       {
           $tc_no = $code;
       }
  
       @conf = grep /[|\s\/]+($tc_no)[\|\s]+/,$fd->getlines;
       $fd->close;
    my (undef,$tc,$file) = split /[\s\|]+/, $conf[$#conf];
        
       if ( $tc and $file )
       {    
    	return "$file" ;
       }
       else
       {
    	return -1;
       };
};
sub nameToCode
{
    my $name = shift;
    
    my $fd= new IO::File $ENV{ATC_HOME}.'/conf/atc.conf','r';
       return -1 unless $fd ;
    my @conf = grep /^DBT_MAP/,$fd->getlines;   
    my $tc_no;
       $fd->close; 
       # -* Parse conf file *- #
       $conf[$#conf] =~ /[=\s\t]+(\S+)[\s\t]*$/;
       $fd= new IO::File $ENV{ATC_HOME}.'/'.$1,'r';
       return -1 unless $fd ;
       
       if ( $name =~ /^\d+$/ )
       {
           $tc_no = sprintf "TC%06d", $name;
       }
       else
       {
           $tc_no = $name;
       }
    
       @conf = grep /[|\s\/]+($name)[\|\s]+/,$fd->getlines;
       $fd->close;
    my (undef,$tc,$file) = split /[\s\|]+/, $conf[$#conf];
        
       if ($tc and $file )
       {    
    	return "$tc" ;
       }
       else
       {
    	return -1;
       };
};
1;
