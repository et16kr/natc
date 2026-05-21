#!/usr/local/bin/perl

#$^W =1 ;

use strict;
#use lib qw ( .lib ..lib );
use lib $ENV{ATC_HOME} . '/lib' ;
use IO::File;
use AltibaseInfo;

my $work_dir = '$ENV{ATC_HOME}/work';
   $work_dir = $ENV{ATC_WORK} if $ENV{ATC_WORK};

my $df = $ARGV[0]|| $work_dir . '/DF';

local (*DIRH);
opendir(*DIRH,$df) || die "I can't open this dir $df;\n";
my @dl = grep /.out$/,readdir(DIRH);
closedir(DIRH);

foreach (@dl){&_print_out($_)};


exit 0;



sub _print_out {
# -* open file descriptor *- #
my ($tc) = shift;
my  $Out =     _get_diff($work_dir.'/DF/'. $tc);
my  $ofd = new IO::File ($work_dir.'/DF/'. $tc,'w');
    $tc  =~ s/out$/lst/;
my $altibase_info = new AltibaseInfo();
my  $fn = $ENV{ATC_HOME}."/LS/A$altibase_info->{major_version}/".$tc;
my  $lfd = new IO::File ($fn,'r');
   
die "Can't open file: $fn\n" unless $lfd;

# -* scan file *- #
my ($l_str,$i_str);

# Default SECTOR
my $sec = 0;

# -* Scan Lst and restore out *- #

LINE2:while ($l_str = $lfd->getline)
 { 

  if  ($l_str =~ /^\-\-\+SECTOR\s+(.*)\;/)
   { 
      $_ = $1;
      /^\s*(\d+)[,\s]*.*/;
      $sec = int $1;
    };

  if ($Out->{$sec})
     { 
      $ofd->print($l_str) if $l_str=~/^\-\-\+SECTOR/ ;
      while ($l_str = $lfd->getline  )  { last if ($l_str =~ /^\-\-\+SECTOR*/)};
      while ($_ = shift @{$Out->{$sec}} ) { $ofd->print($_)			    };
      delete $Out->{$sec};
      redo LINE2;
     };
 
  $ofd->print($l_str);
  };
   $lfd->close;
  $ofd->close;
  
 return 0;
 };


sub _get_diff 
 {  my $fn = shift;
    my $fd = new IO::File($fn,'r') || return undef;
    my %Out;
    my $sec = 0;
    LINE:while ($_ = $fd->getline)
    {
     if  (/^\-\-\+SECTOR\s+(.*)\;/) 
	 {
	   $_ = $1;
	   /^\s*(\d+)[,\s]*.*/;
	   $sec = int $1;
	   next LINE;
	  };
	push @{$Out{$sec}},$_;
    }
   $fd->close;
  return \%Out;
 }


1;
