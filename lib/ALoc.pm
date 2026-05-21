#!/usr/local/bin/perl
package ALoc;

use strict;
use Data::Dumper;
use IO::File;
use File::Basename;

my $g_depth = $main::depth;

sub new {
    my $class = shift;

    my $self = {
            fileSep=> '/',
			fileList => [],
			moduleList => [],
			depth => 0,
            #@_,
        };
    bless ($self, $class);

    return $self;
}

sub process_sh
{
    my $self = shift;
    my $file_name = shift;
    my $full_file_name = shift;
    my $ext = shift;

    my $type = '';
    $ext =~ s/\.//;
    my $_obj = { 
                 type=>'SHELL',
                 subtype=>$ext,
                 codeLine=>0,
                 blankLine=>0,
		 commentLineC=>0,
		 commentLineCPP=>0,
		 commentedLineC=>0,
		 commentedLineCPP=>0
			    };

    my $fd = new IO::File $full_file_name, 'r';
    unless ( $fd )
    {
        print "Not found ... $full_file_name \n";
        exit -1;
    }
    
    while (<$fd>)
    {
        chomp;
    
        $type = '';
        if (/^\s*\#/)
        {
            $type = "COMMENT_BEGIN";
        }
        if ($type =~ "COMMENT_BEGIN") 
        {
            $_obj->{commentLineCPP}++;
            #print "Comment\n";
        }
        else
        {
            if (/\#.*$/)
            {
                $_obj->{commentedLineCPP}++;
                #print "Commented\n";
            }
            elsif (/^\s*$/)
            {
                $_obj->{blankLine}++;
                #print "blank\n";
            }
            else
            {
                #print "000" . $_ . "\n";
            }
            $_obj->{codeLine}++;
        }
    }
    $fd->close();
    my $fileItem = {name=>$file_name, info=>$_obj};
    push @{$self->{fileList}}, $fileItem;
}
    
sub process_c
{
    my $self = shift;
    my $file_name = shift;
    my $full_file_name = shift;
    my $ext = shift;

    my $type = '';
    $ext =~ s/\.//;
    my $_obj = { 
                 type=>'SOURCE',
                 subtype=>$ext,
                 codeLine=>0,
                 blankLine=>0,
		 commentLineC=>0,
		 commentLineCPP=>0,
		 commentedLineC=>0,
		 commentedLineCPP=>0
			    };

    my $fd = new IO::File $full_file_name, 'r';
    unless ( $fd )
    {
        print "Not found ... $full_file_name \n";
        exit -1;
    }
    
    while (<$fd>)
    {
        chomp;
    
        #print $_ . "\n";
        if (/^\s*\/\*/ && $type !~ "COMMENT_BEGIN")
        {
            $type = "COMMENT_BEGIN";
            #print $type. "\n";
        }
        if ($type =~ "COMMENT_BEGIN") 
        {
            $_obj->{commentLineC}++;
            if (/\*\/.*$/)
            {
                $type = "COMMENT_END";
                #print $type. "\n";
            }
            #print ">>> IT'S COMMENT\n";
        }
        else
        {
            if (/\/\*.*\*\//)
            {
                $_obj->{commentedLineC}++;
                #print "%%% " . $_ . "\n";
            }
            elsif (/^\s*\/\//)
            {
                $_obj->{commentLineCPP}++;
            }
            elsif (/\/\//)
            {
                $_obj->{commentedLineCPP}++;
            }
            elsif (/^\s*$/)
            {
                $_obj->{blankLine}++;
            }
            else
            {
                #print "000" . $_ . "\n";
            }
            $_obj->{codeLine}++;
        }
    }
    $fd->close();
    my $fileItem = {name=>$file_name, info=>$_obj};
    push @{$self->{fileList}}, $fileItem;
}
    


sub getLoc
{
    my $self = shift;
    my $file_name = shift;
    my $path = shift || '.';
    my $depth = shift || 0;

	#print "::: $file_name\n";



    my $full_file_name = $path . $self->{fileSep} . $file_name;
    $file_name =~ /\.\w+$/;

    my $ext = $&;

    if ($file_name eq "CVS")
    {
        return;
    }

    if ( -d $full_file_name)
    {

        my $subModule = new ALoc;

		$subModule->{depth} = $depth + 1;

        opendir(DIR, $path . $self->{fileSep} . $file_name);
        my @files = readdir(DIR);
        foreach my $file (@files)
        {
            if ( $file ne "." && $file ne ".." && $file ne "CVS")
            {
                $subModule->getLoc($file, 
		               $path . $self->{fileSep} . $file_name, $depth +1);
            }
			#print Dumper $subModule;
        }
        my $fileItem = {name=>$file_name, path=>$path, info=>$subModule};
        push @{$self->{moduleList}}, $fileItem;
    }
	elsif ( -B $full_file_name )
	{
		# do nothing
	}
    else
    {
        my $find_name = $file_name;
        $find_name =~ s/\+/\\\+/g;
        my @found = grep(/$find_name/, @main::g_except_files);
        if (length($found[0]) == 0)
        {
            if ($ext eq '.c' || $ext eq '.cpp' || 
                $ext eq '.h' ||
                $ext eq '.l' || $ext eq '.y' ||
                $ext eq '.java')
            {
                $self->process_c($file_name, $full_file_name, $ext);
            }
            else
            {
                #$self->process_sh($file_name, $full_file_name, $ext);
            }
        }
      
    }
    return 0;
};

sub getModuleLoc
{
    my $self = shift;
	my $name = shift || '';

    my $commentRatio;
    my $blankRatio;

	my $codeLine = 0;
	my $commentLineC = 0;
	my $commentLineCPP = 0;
	my $commentedLineC = 0;
	my $commentedLineCPP = 0;
	my $blankLine = 0;


	foreach my $module (@{$self->{moduleList}})
	{
		my ($t_codeLine, $t_blankLine, $t_commentLineC,
			$t_commentedLineC, $t_commentLineCPP, $t_commentedLineCPP) 
            = $module->{info}->getModuleLoc($module->{name});
        $codeLine += $t_codeLine;
        $blankLine += $t_blankLine;
        $commentLineC += $t_commentLineC;
		$commentedLineC += $t_commentedLineC;
        $commentLineCPP += $t_commentLineCPP;
		$commentedLineCPP += $t_commentedLineCPP;
	}

    foreach my $file (@{$self->{fileList}})
    {
        $codeLine += $file->{info}->{codeLine};
        $blankLine += $file->{info}->{blankLine};
        $commentLineC += $file->{info}->{commentLineC};
	$commentedLineC += $file->{info}->{commentedLineC};
        $commentLineCPP += $file->{info}->{commentLineCPP};
	$commentedLineCPP += $file->{info}->{commentedLineCPP};

        if ($main::mode eq 'FILE')
        {
	     $self->print($file->{name},
                          $file->{info}->{type},
                          $file->{info}->{subtype},
	                  $file->{info}->{codeLine},
	                  $file->{info}->{blankLine},
	                  $file->{info}->{commentLineC},
	                  $file->{info}->{commentLineCPP},
	                  $file->{info}->{commentedLineC},
	                  $file->{info}->{commentedLineCPP},
	                  $file->{path},
	                  $self->{depth}+1
	                 );
        }
    }
    $self->print($name,
                 'MODULE',
                 '',
		 $codeLine,
	         $blankLine,
		 $commentLineC,
		 $commentLineCPP,
		 $commentedLineC,
		 $commentedLineCPP,
		 $self->{path},
		 $self->{depth}
		);
    return ($codeLine, $blankLine, $commentLineC,
			$commentedLineC, $commentLineCPP, $commentedLineCPP);
    
};    

sub printModule
{
	my $self = shift;
	my $name = shift || '';
	
	$name = 'TOTAL';
	my ($t_codeLine, $t_blankLine, $t_commentLineC,
		$t_commentedLineC, $t_commentLineCPP, $t_commentedLineCPP) 
        = $self->getModuleLoc($name);
};

sub print
{
    my $self = shift;
	my $name = shift;
	my $type = shift;
	my $subtype = shift;
	my $codeLine = shift || 0;
	my $blankLine = shift || 0;
	my $commentLineC = shift || 0;
	my $commentLineCPP = shift || 0;
	my $commentedLineC = shift || 0;
	my $commentedLineCPP = shift || 0;
	my $path = shift || '';
	my $depth = shift || 0;

	my $commentLine = 0;
	my $commentedLine = 0;
	my $totalLine = 0;
	my $totalCommentLine = 0;
    my $commentRatio = 0;
    my $blankRatio = 0;

	if ($g_depth < $depth - 1)
	{
		return;
	}
    $commentLine = $commentLineC + $commentLineCPP;
    $commentedLine = $commentedLineC + $commentedLineCPP;
    $totalLine = $codeLine + $commentLine + $blankLine;
    $totalCommentLine = $commentLine + $commentedLine;
    $commentRatio = ($totalLine == 0) ? 0 : $totalCommentLine / $totalLine * 100;
    $blankRatio   = ($totalLine == 0 )? 0 : $blankLine / $totalLine * 100;
	
    print "DEPTH          : $depth\n";
    print "FILE NAME      : $name\n";
    print "TYPE           : $type\n";
    print "SUB_TYPE       : $subtype\n";
    print "CODE LINE      : $codeLine\n";
    print "COMMENT LINE   : $commentLine\n";
    print "COMMENTED LINE : $commentedLine\n";
    print "BLANK LINE     : $blankLine\n";
    print "TOTAL LINE     : $totalLine\n";
    print "TOTAL COMMENT  : $totalCommentLine\n";

    print "COMMENT RATIO  : $commentRatio %\n";
    print "BLANK RATIO    : $blankRatio %\n";
    print "C STYLE COMMENT  : $commentLineC   $commentedLineC\n";
    print "C++ STYLE COMMENT: $commentLineCPP   $commentedLineCPP\n";
    print "\n";
    return;
    
} ;    

1;
