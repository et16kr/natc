#!/usr/local/bin/perl
use lib $ENV{ATC_HOME} . '/lib' ;

use strict;

use DiffOut;

my $diffOut = new DiffOut;
$diffOut->processDiffOut;
exit $diffOut->writeFile;
