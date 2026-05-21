#!/usr/local/bin/perl
package DiffOut;
use strict;
use IO::File;
use Data::Dumper;

#my $diffOut = new DiffOut;
#$diffOut->processDiffOut;
#$diffOut->writeFile;

sub new
{
    my $class = shift;
    my $self = {
         new_diff_file => $ENV{ATAF_TEST_RESULT}."/work".'/TS999999.ts',
         old_diff_file => $ENV{ATAF_TEST_RESULT}."/work".'/TS999999.ts.yesterday',
         out_file_name => $ENV{ATAF_TEST_RESULT}."/work".'/diff_out.txt',
         new_diff_tc => [],
         old_diff_tc => [],
         rem_diff_tc => [],
         header_line_diff_file => 3,
    };

    bless($self, $class);
    return $self;
};

sub writeFile
{
    my $self=shift;

    my $cnt = 0;
    my $index = 0;

=for testing
    if ( !defined @{$self->{new_diff_tc}}[$index] &&
         !defined @{$self->{rem_diff_tc}}[$index] &&
         !defined @{$self->{old_diff_tc}}[$index] )
    {
        return $cnt;
    }
=cut
    my $out_fd = new IO::File $self->{out_file_name}, 'w';
    return -1 unless $out_fd;

    print $out_fd "[NEW DIFF]\n";
    while (defined @{$self->{new_diff_tc}}[$index])
    {
        print $out_fd @{$self->{new_diff_tc}}[$index];
        $index++;
        $cnt++;
    }

    print $out_fd "[REMOVED DIFF]\n";
    $index = 0;
    while (defined @{$self->{rem_diff_tc}}[$index])
    {
        print $out_fd @{$self->{rem_diff_tc}}[$index];
        $index++;
        $cnt++;
    }

    print $out_fd "[OLD DIFF]\n";
    $index = 0;
    while (defined @{$self->{old_diff_tc}}[$index])
    {
        print $out_fd @{$self->{old_diff_tc}}[$index];
        $index++;
    }

    $out_fd->close;
    return $cnt;
};

sub processDiffOut
{
    my $self = shift;
    
    my $new_fd= new IO::File $self->{new_diff_file},'r';
       return -1 unless $new_fd ;
    my @new_lines = $new_fd->getlines;   
    my $old_fd= new IO::File $self->{old_diff_file},'r';
    my @old_lines=[];
    if ($old_fd)
    {
        @old_lines = $old_fd->getlines;   
    }
    my $index = $self->{header_line_diff_file};

    my @current_line;
    my @find_lines;
    while (defined $new_lines[$index])
    {
       my @current_line = split /#/, $new_lines[$index];
       my @find_lines = grep /^$current_line[0]/, @old_lines;
       if (defined @find_lines && length($find_lines[0]) > 0)
       {
           push @{$self->{old_diff_tc}}, $new_lines[$index];
       }
       else
       {
           push @{$self->{new_diff_tc}}, $new_lines[$index];
       }
       $index++;
    }

    $index = $self->{header_line_diff_file};

    while (defined $old_lines[$index])
    {
       my @current_line = split /#/, $old_lines[$index];
       my @find_lines = grep /^$current_line[0]/, @new_lines;
       if (!defined @find_lines || length($find_lines[0]) == 0)
       {
           push @{$self->{rem_diff_tc}}, $old_lines[$index];
       }
       $index++;
    }
    $new_fd->close;
    $old_fd->close if $old_fd;
#print Dumper $self;
};
1;
