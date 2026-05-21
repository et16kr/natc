#!/usr/local/bin/perl
$^W=1;
use lib $ENV{ATC_HOME} . '/lib';
use strict;
use Exporter;
use File::Basename;
use FileHandle;
use IO::File;

my $fileFullName = $ARGV[0] ? shift @ARGV 
    : die "File Name 을 지정하세요 ! \n";

$fileFullName =~ s/\s+$//;
$fileFullName =~ s/^\s+//;
my $path  = GetCwd($fileFullName);  
my $fdRead= new IO::File;

my $lines = 0;
my $chars = 0;
my $words = 0;
my @wordsSplit;

$fdRead->open($path.$fileFullName, "r")
    || die "Can't Open fileFullName : [$path$fileFullName] \n";

while(<$fdRead>)
{
    $_ =~ s/\r//g;
    
    $chars += length($_);
    $lines++;
    @wordsSplit = split ' ', $_;
    $words += @wordsSplit;
}    

print sprintf "%s    %s    %s    %s\n", $lines, $words, $chars, $fileFullName;

sub GetCwd()
{
    my ($fileName, $path, $suffix) = fileparse($_[0]);
    return $path;
};


