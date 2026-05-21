#!/usr/local/bin/perl
package TSmap;

use strict;
use File::Basename;
use IO::File;

sub new {
    my ($class) = shift;
    my $self = { 
		           map_fd => '',
                   ts_map_file => "$ENV{ATC_HOME}/TL/ts.map",
                   dir_map_file => "$ENV{ATC_HOME}/dir.map",
		       };
    bless ($self, $class);

	return $self;
}

sub make_TS_map
{
	my $self = shift;
	#my @a_tl_list = shift;
	my @a_tl_list = @ARGV;

	$self->{map_fd} = new IO::File $self->{ts_map_file}, 'w';
	unless ($self->{map_fd})
	{
		return;
	}

    foreach my $tl_file (@a_tl_list)
	{
		$self->read_tl_file($tl_file);
	}
	$self->{map_fd}->close;
}

sub read_ts_file
{
	my $self = shift;
	my $a_ts_file = shift;

	print "> TS :: $a_ts_file###\n";
	my $fd = new IO::File $ENV{ATC_HOME} . '/' . $a_ts_file, 'r';
	unless ($fd)
	{
		return;
	};

	while (<$fd>)
	{
		chomp;

		next if /^\s*$/;

		s/^\s*//;
		s/\s*$//;

		if (/^[\t\s]*TestListDescription/)
		{
			# skip
		}
		elsif ( /^[\t\s]*\#/ || /^[\t\s]*\n/ )
		{
			# skip
		}
		else
		{
			if (/^\S*\.ts/)
			{
				my @ts_name = split /\S*#\S*/,$_, 2;
				$ts_name[0] =~ s/[\t\s]*$//;
				my ($ts_fname, $ts_path, $ts_suffix) =
				                         fileparse($a_ts_file, '\.ts');

				my $ts_full_name = $ts_path . $ts_name[0];
				$self->{map_fd}->print( $ts_full_name . " # " . $ts_name[1] . "\n");

				$self->read_ts_file($ts_full_name);
			}
		}

	}
	$fd->close;
	return ;
};

sub read_tl_file
{
	my $self = shift;
	my $a_tl_file = shift;

	my $fd = new IO::File $a_tl_file, 'r';
	unless ($fd)
	{
		return;
	};

	while (<$fd>)
	{
		chomp;

		next if /^\s*$/;

		s/^\s*//;
		s/\s*$//;

		if (/^[\t\s]*TestListDescription/)
		{
			# skip
		}
		elsif ( /^[\t\s]*\#/ || /^[\t\s]*\n/ )
		{
			# skip
		}
		else
		{
			if (/^\S*\.tl/)
			{
				# load another tl file
				my @tl_name = split /\S*#\S*/,$_, 2;

				$self->read_tl_file($tl_name[0]);
			}
			elsif (/^\S*\.ts/)
			{
				my @ts_name = split /\S*#\S*/,$_, 2;
				$ts_name[0] =~ s/[\t\s]*$//;
				my $ts_full_name = $ts_name[0];
				$self->{map_fd}->print( $ts_full_name . " # " . $ts_name[1] . "\n");
				$self->read_ts_file($ts_full_name);
			}
		}

	}
	$fd->close;
	return ;
};

sub find_TS_map
{
	my $self = shift;
	my $a_ts_name = shift;

	#print ">>> map :: $self->{ts_map_file} \n";
	#print ">>> find :: $a_ts_name \n";
	my $fd = new IO::File $self->{ts_map_file}, 'r';
	unless ($fd)
	{
		return;
	};

	while (<$fd>)
	{
		chomp;

		next if /^\s*$/;

		s/^\s*//;
		s/\s*$//;

		#print ">>> line :: $_\n";
		if ( $_ =~ $a_ts_name)
		{
		    my @par = split /\S*#\S*/;
			my $find_name = $par[0];
            $find_name =~ s/\s*$//;
			#print ">>> $ENV{ATC_HOME}/$find_name\n";
	        $fd->close;
			return $ENV{ATC_HOME}."/".$find_name;
		}
	}
	$fd->close;
	#print ">>> $a_ts_name :: not found\n";
	return ;
};

sub find_path_TS_map
{
	my $self = shift;
	my $a_ts_name = shift;

	#print ">>> find :: $a_ts_name \n";

	my $fd = new IO::File $self->{ts_map_file}, 'r';
	unless ($fd)
	{
		return;
	};

	while (<$fd>)
	{
		chomp;

		next if /^\s*$/;

		s/^\s*//;
		s/\s*$//;

		#print ">>> line :: $_\n";
		if ( $_ =~ $a_ts_name)
		{
		    my @par = split /\S*#\S*/;
			my $find_name = $par[0];
            $find_name =~ s/\s*$//;
			my ($ts_name, $ts_path, $ts_suffix) =
			                       fileparse($find_name, '\.ts');

	        $fd->close;
			#print ">>> $ENV{ATC_HOME}/$ts_path\n";
			return $ENV{ATC_HOME}."/".$ts_path;
		}
	}
	$fd->close;
	#print ">>> $a_ts_name :: not found\n";
	return ;
};

sub find_path_dir_map
{
	my $self = shift;
	my $a_dir_name = shift;

        $a_dir_name =~ s/\*/\\S*/g;
        
	#print ">>> find :: $a_dir_name \n";

	my $fd = new IO::File $self->{dir_map_file}, 'r';
	unless ($fd)
	{
		return;
	};

	while (<$fd>)
	{
		chomp;

		next if /^\s*$/;

		s/^\s*//;
		s/\s*$//;

		#print ">>> line :: $_\n";
		if ( $_ =~ $a_dir_name)
		{
		    my @par = split /\S*#\S*/;
			my $find_name = $par[0];
            $find_name =~ s/\s*$//;
	        $fd->close;
			#print ">>> $fine_name\n";
			return $find_name;
		}
	}
	$fd->close;
	#print ">>> $a_ts_name :: not found\n";
	return ;
};

1;


