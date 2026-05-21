#!/usr/local/bin/perl

use File::Basename;


for( $sI = 0; $sI <= $#ARGV; $sI++ )
{
    doFile($ARGV[$sI], 0, "");
}

sub doFile($aFullName, $aLevel, $aParentName)
{
    my $aFullName   = $_[0];
    my $aLevel      = $_[1];
    my $aParentName = $_[2];

    my @sWholeLines;
    my $sLine;
    my $sLineCount;
    my @sFullLine;
    my $sFullName;
    my $sFileName, $sFileDir, $sFileType;
    my $sArgDir;
    my $sI;
    my $isBlocked;

    if( open(sFH,$aFullName) )
    {
        @sWholeLines = <sFH>;
        close(sFH);
    }
    else
    {
        print "Cannot open $aFullName, $! \t# $aParentName\n" ;
        return;
    }

    for( $sLineCount = 1; $sLineCount <= $#sWholeLines; $sLineCount++ )
    {
        $sLine     = $sWholeLines[$sLineCount];
        $a         = substr( $sLine, 0, 1 );
        $isBlocked = 0;
        if( $a eq "#" )
        {
             $isBlocked = 1;
             substr( $sLine, 0, 1 ) = "";
        }
        if( $a eq "!" )
        {
             substr( $sLine, 0, 1 ) = "";
        }

	$sLine =~ s/\[.*\]//;
        $sLine =~ s/#.*$//;
        $sLine =~ s/^\s*//;

        if( !($sLine =~ /^-/) && !($sLine =~ /^~/) && !($sLine =~ /^\s*$/) && !($sLine =~ /^##/))
        {
            @sFullLine = split(/\s/,$sLine);
            $sFullName = $sFullLine[0];

            $sArgDir = dirname($aFullName);

            if($isBlocked == 1)
            {
#                for( $sI = 0; $sI < $aLevel; $sI++) { print("  "); }

                print($sArgDir."/".$sFullName."\t# ".$aFullName."\n");
            }

            ($sFileName, $sFileDir, $sFileType) = fileparse($sFullName, '\..*');
            if( $sFileType eq ".ts" )
            {
                doFile($sArgDir."/".$sFullName, $aLevel+1, $aFullName);
            }

       }
    }
}
