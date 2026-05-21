#!/usr/local/bin/perl
use lib $ENV{ATC_HOME} . '/lib' ;

use strict;

use TSmap;

my $tsmap = new TSmap;

print $ENV{ATC_HOME} . "/" . $tsmap->find_path_dir_map(@ARGV);
