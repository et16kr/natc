#!/usr/local/bin/perl
use lib $ENV{ATC_HOME} . '/lib' ;

use strict;

use TSmap;

my $tsmap = new TSmap;

$tsmap->make_TS_map(@ARGV);
