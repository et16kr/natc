#!/usr/local/bin/perl
use strict;
use IO::File;
use Data::Dumper;

my $fd = new IO::File $ENV{ATC_WORK}. '/log/report.log', 'r';

my $flag = 0;

while (<$fd>)
{
    if (/ABRUPT EXIT REPORT/)
    {
        $flag = 1;
    }

    if ($flag == 1)
    {
        print $_;
    }
}
