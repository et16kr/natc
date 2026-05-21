#!/usr/local/bin/perl
use lib $ENV{ATC_HOME} . '/lib' ;

use strict;

use TSmap;

my $tsmap = new TSmap;

print $ENV{ATAF_TEST_RESULT} . "/" . $tsmap->find_path_dir_map(@ARGV);
