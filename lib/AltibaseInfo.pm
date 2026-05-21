#!/usr/local/bin/perl
package AltibaseInfo;
use strict;
use IO::File;

#my $a_info = new AltibaseInfo();
#print ">>> ". $a_info->get_file_ext() . "\n";
#getInfo();

sub new  {
    my $class = shift;
    my $self = {
        full_version    => '',
        major_version   => '',
        bit             => '',
        platform        => '',
        endian            => '',
        os              => '',
        @_                   ,
    };
    bless( $self,$class);
    my $fd= new IO::File $ENV{ATAF_TEST_RESULT}."/work".'/altibase.info','r';
       return -1 unless $fd ;
      
    my $info_line = $fd->getline;
    my @info = split /[\s\ ]+/, $info_line;

    $self->{full_version} = $info[1];
    my @sub_info = split /[\s\.]+/, $info[1];
    $self->{major_version} = $sub_info[0];
	@sub_info = split /-/, $info[2];
    $sub_info[1] =~ s/bit//;
	$self->{bit} = $sub_info[1];
    $info[3] =~ s/^\(//;
    $info[3] =~ s/\)$//;
    $self->{platform} = $info[3];
	
    # Little Endian Check
    $self->{endian} = "Little";


    # OS CHECK 
    my @tmp = split /_/, $sub_info[0];
    $self->{os} = $tmp[0] . "_". $tmp[1];
    return  $self;
}

sub get_file_ext
{
    my $self = shift;
	return '_A' . $self->{major_version}.'_'.$self->{bit};
}

sub get_diskfile_ext
{
    my $self = shift;
        return "_". $self->{endian}.'_A' . $self->{major_version}.'_'.$self->{bit};
}

sub GetPlatForm 
{
    my $self = shift;
    return "_".$self->{os}.'_A' . $self->{major_version}.'_'.$self->{bit};
}

1;
