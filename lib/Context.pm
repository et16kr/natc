#!/usr/bin/perl -w
package Context;

use strict;
use IO::File;
use ServerObject;
use Data::Dumper;



#test();

sub test
{
    my $context = new Context;
    my $server_list = $context->readContext();
    my @server_name = keys %$server_list;

    use Data::Dumper;
    print Dumper @server_name;
    print Dumper $server_list;
    no Data::Dumper;
}

sub new
{
    my $class = shift;
    my $self = {};

    bless($self, $class);
    return $self;
}


sub readContext
{
    my $self        = shift;
    my $file_name = ( @_ == 1) 
                    ? shift 
                    : $ENV{ATC_HOME} . '/conf/atc.server.ctx';

#    my $fd = new IO::File $ENV{ATC_HOME}.'/conf/atc.server.ctx','r';
#    return -1 unless $fd;

    my $fd = new IO::File $file_name,'r';
    return -1 unless $fd;

    my $line;
    my @rec;
    my $server_name;
    my $server_rec;
    #    my $server_object;
    my $server_list;

    while (!$fd->eof())
    {
        $line = $fd->getline();

        next    if ( $line =~ /^\s*#/ );

        if ( $line =~ /^\s*\[/ )
        {
 		    $server_name = $line;
            $server_name =~ s/\[(\w+)\]\s*\n/$1/;

            $server_list->{$server_name}->{TMPL_NAME} = $server_name;
            #if ($server_name ne "GENERAL")
            #{
                #%server_list->{"GENERAL"}->copyProperty($server_object);
                #}
        }
        else
        {
            if ($line =~ /=/ )
            {
 		        @rec = split /=/, $line;
                $_ = $rec[0];
                s/\s*//g;
                $rec[0] = $_;

                $_ = $line;
                s/\s*//g;
                s/$rec[0]=//g;
                #$_ = $rec[1];
                #s/\s*//g;
                $rec[1] = $_;
                $server_list->{$server_name}->{$rec[0]} = $rec[1];
            }
        }
    }

    return $server_list;
}

1;
