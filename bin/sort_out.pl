#!/usr/local/bin/perl
use strict;
use integer;

$^W=1;

use IO::File;
use Data::Dumper;

my $lst_in = load_lst_file_db($ARGV[0]);
my $sect ; 


 foreach $sect (0..1000)
  {
   last unless defined $lst_in->{$sect};
   print "--+SECTOR $sect ; $lst_in->{$sect}{desc}\n"  ;
   foreach  (@{ $lst_in->{$sect}{lst} })
    {
     print $_,"\n";
    }

  } 

exit 0;






sub load_lst_file_db {
    my $tc_lst = shift || return undef ;
    my (
        %diffs,
        $sect_ptr
     );
    # -* Set for nodesc *- #
    $sect_ptr  =  0;
    $diffs{$sect_ptr}{desc}= '';

    # -* Make FileName *- #

    my $lst = new IO::File($tc_lst,'r') || do {
                        print  "I can't Read LST file $tc_lst!\n";
                        return undef
                          };

 while  (<$lst>)
  {
       chomp;
       next  unless $_;
       if(/^\-\-\+SECTOR\s+(.*)\;/)
        {
         $_ = $1;
         my $desc = $';
         /^(\d+)[,\s]*.*/;
         $sect_ptr = int $1;
         $diffs{$sect_ptr}{desc}=$desc;
        }
     else
       {
        push @{ $diffs{$sect_ptr}{lst} },$_;
       };
  } ; # end while
   $lst->close;
 return \%diffs;
};
