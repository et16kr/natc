#!/usr/local/bin/perl

use File::Basename;


for( $sI = 0; $sI <= $#ARGV; $sI++ )
{
    doFile($ARGV[$sI], 0);
}

sub doFile($aFullName, $aLevel)
{
    my $aFullName = $_[0];
    my $aLevel    = $_[1];

    my @sWholeLines;
    my $sLine;
    my $sLineCount;
    my @sFullLine;
    my $sFullName;
    my $sFileName, $sFileDir, $sFileType;
    my $sArgDir;
    my $sI;

    if( open(sFH,$aFullName) )
    {
        @sWholeLines = <sFH>;
        close(sFH);
    }
    else
    {
        print "Cannot open $aFullName, $!\n" ;
        return;
    }

    for( $sLineCount = 1; $sLineCount <= $#sWholeLines; $sLineCount++ )
    {
        $sLine = $sWholeLines[$sLineCount];
        $a = substr( $sLine, 0, 1 );
        if( $a eq "!" )
        {
             substr( $sLine, 0, 1 ) = "";

        }

        $sLine =~ s/\[.*\]//;
        $sLine =~ s/#.*$//;
        $sLine =~ s/^\s*//;

        if( !($sLine =~ /^-/) && !($sLine =~ /^~/) && !($sLine =~ /^\s*$/) )
        {
            @sFullLine = split(/\s/,$sLine);
            $sFullName = $sFullLine[0];

            $sArgDir = dirname($aFullName);

            for( $sI = 0; $sI < $aLevel; $sI++)
            {
                print("  ");
            }
            print($sArgDir."/"."$sFullName\n");

            ($sFileName, $sFileDir, $sFileType) = fileparse($sFullName, '\..*');
            if( $sFileType eq ".ts" )
            {
                doFile($sArgDir."/".$sFullName, $aLevel+1);
            }
       }
    }
}
