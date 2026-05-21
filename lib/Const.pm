package Const;
require Exporter;
@ISA = qw (Exporter);
@EXPORT = qw( );
@EXPORT_OK = qw(QUEUE WAIT BLOCK);

use strict;

# -*- READY & BLOCK for wait state dead loop test ... -*- #

use constant BLOCK 	=>  1;  	# 1 iSQL in BLOK state jast do sql statment
use constant QUEUE      =>  2;		# 2 iSQL have got Queue for execute
use constant WAIT 	=>  4;  	# 4 iSQL in WAIT state command ctatment 

# Sector PARAMETR sets
use constant IGNORE     =>  1;		# IGNORE for SECTOR command constant
1;
