#!/usr/local/bin/perl
package CheckList;

use strict;

use Data::Dumper;
use File::Basename;
use IO::File;
use Getopt::Long;

my $chk = new CheckList;

Getopt::Long::Configure('no_auto_abbrev');

GetOptions(
	"dir|d:s"          => \$chk->{start_dir},
	"mode|m:s"         => \$chk->{mode},
	"period|p:i"       => \$chk->{period}
) || error(4);

$chk->make_list;
$chk->set_chk_file;
$chk->make_cl_structure;
$chk->print_summary;
$chk->remove_list;
#print Dumper $chk;
#print Dumper $chk->{list}{TC}{list}{Server}{list}{qp2};

sub new {
    my ($class) = shift;
    my $self = { 
		          list => {},
				  mode => 'brief',
				  start_check_name=> "TC",
				  check_list_path => $ENV{ATC_HOME}.'/',
		          check_list_file => $ENV{ATC_HOME}.'/'.'CHECKLIST.report',
		       };
    bless ($self, $class);

	return $self;
}

sub make_list
{
	my $self = shift;

	my $command = "find ";

	if ($self->{start_dir} eq '.')
	{
		$command .= '. ';
	}
	else
	{
		$command .= 'TC ';
	}

	my $condition = ' \( -name "CHECKLIST.txt" ';
	if ($self->{period})
	{
		$condition .= '-a -ctime ' . $self->{period} ;
	}
	$condition .= ' \) -print ';

	$command .= $condition . ' > CHECKLIST.report ';

	#print ">>> $command\n";
	system($command);
}

sub remove_list
{
	my $self = shift;
	system("rm CHECKLIST.report");

}


sub set_chk_file
{
	my $self = shift;

	if ($self->{start_dir} =~ /^\./ )
	{
		$self->{check_list_file} = $ENV{PWD}.'/'.'CHECKLIST.report';
		$self->{check_list_path} = $ENV{PWD}.'/';
		$self->{start_check_name} = '.';
	}
	else
	{
		$self->{check_list_file} = $ENV{ATC_HOME}.'/'.'CHECKLIST.report';
		$self->{check_list_path} = $ENV{ATC_HOME}.'/';
	}
}

sub make_cl_structure
{
	my $self = shift;
	
	my $fd = new IO::File $self->{check_list_file}, 'r';
	unless ($fd)
	{
		print "There is no $self->{check_list_file}.\n";
		exit(255);
	}

	while (<$fd>)
	{
		chomp;

	    next if /^\s*$/;

		s/^\s*//;
		s/\s*$//;

		my $cl_file = $_;
		my ($fname, $fpath, $fsuffix) = fileparse($cl_file, '\.txt');

		my @path_layer = split /\//, $fpath;

		#print ">>> $_\n";
		my $prev = $self;
		foreach my $subdir ( @path_layer)
		{
			#print $subdir . ":";
			my $item = {};
			if (!$prev->{list}{$subdir} )
			{
			    $prev->{list}{$subdir} = $item;
				$prev->{sub_cnt}++;
			    $prev = $item;
			}
			else
			{
			    $prev = $prev->{list}{$subdir} ;
			}
		}

		my $chk_file_info = $self->read_chk_file($cl_file, $self->{mode});
		$prev->{subject} = ( $chk_file_info->{subject} )
		                   ?  $chk_file_info->{subject} 
						   :  " ";
		$prev->{object} = ( $chk_file_info->{object} )
		                   ?  $chk_file_info->{object} 
						   :  " ";
		$prev->{items}  = ( $chk_file_info->{items} )
		                   ?  $chk_file_info->{items} 
						   :  " ";
		$prev->{sub_cnt} = ( $chk_file_info->{sub_cnt} )
		                   ?  $chk_file_info->{sub_cnt}
						   :  0 ;
		$prev->{tot_item} = ( $chk_file_info->{tot_item} )
		                   ?  $chk_file_info->{tot_item}
						   :  0 ;
		$prev->{fin_item} = ( $chk_file_info->{fin_item} )
		                   ?  $chk_file_info->{fin_item}
						   :  0 ;
		$prev->{yet_item} = ( $chk_file_info->{yet_item} )
		                   ?  $chk_file_info->{yet_item}
						   :  0 ;
		#print "\n";
		#print Dumper $self;
	}

	$self->acct_list($self->{list}{$self->{start_check_name}});
}

sub acct_list
{
	my $self = shift;
	my $item = shift;

	my $acct_cnt = 0;

	my @list = (keys %{$item->{list}});
	foreach my $one ( @list)
	{
		if ($item->{list}{$one}{list})
		{
		    $self->acct_list($item->{list}{$one});
		}
		else
		{
			$item->{list}{$one}{sub_acc} = $item->{list}{$one}{sub_cnt};
			$item->{list}{$one}{tot_acc} = $item->{list}{$one}{tot_item};
			$item->{list}{$one}{fin_acc} = $item->{list}{$one}{fin_item};
			$item->{list}{$one}{yet_acc} = $item->{list}{$one}{yet_item};
		}
		$item->{sub_acc} += $item->{list}{$one}{sub_acc};
		$item->{tot_acc} += $item->{list}{$one}{tot_acc};
		$item->{fin_acc} += $item->{list}{$one}{fin_acc};
		$item->{yet_acc} += $item->{list}{$one}{yet_acc};
	}
	$item->{sub_acc} += $item->{sub_cnt};
	$item->{tot_acc} += $item->{tot_item};
	$item->{fin_acc} += $item->{fin_item};
	$item->{yet_acc} += $item->{yet_item};
}

sub read_chk_file
{
	my $self = shift;
	my $chk_file = shift;

	my $chk_file_info;

	$chk_file_info->{items} = [];

	my $fd = new IO::File $self->{check_list_path} . $chk_file, 'r';
	unless ($fd)
	{
		print "There is no $chk_file.\n";
		exit(255);
	}

	my $line;
	while (<$fd>)
	{
		chomp;

	    next if /^[\t\s]*$/;

		$line = $_;
		s/^\s*//;
		s/\s*$//;

		#print ">>> $_\n";
        if (/^[\t\s]*#/)
		{
            my @par = split /:/, $_;
			if (/Subject/)
			{
			    $chk_file_info->{subject} = $par[1];
			}
			elsif (/Object/)
			{
				$chk_file_info->{object} = $par[1];
			}
		}
		else
		{
            $chk_file_info->{tot_item}++;
			if (/^[\t\s]*\+/)
			{
				$chk_file_info->{fin_item}++;
			}
			elsif (/^[\t\s]*\-/)
			{
				$chk_file_info->{yet_item}++;
			}
			if ($self->{mode} =~ /full/)
			{
				push @{$chk_file_info->{items}}, $line;
			}
		}
	}
	return $chk_file_info;
}

sub print_item
{
	my $self = shift;
	my $item = shift;
	my $depth = shift;

	#print ">>> now print\n";
	my @list = sort (keys %{$item->{list}});
	foreach my $one ( @list)
	{
		my $fin = ( $item->{list}{$one}{yet_item} > 0 )
		          ? "- "
				  : "+ ";
		print " "x($depth*4) . $fin . $one ;
		print "  (";
		print "D: " . $item->{list}{$one}{sub_cnt} . "/";
		print $item->{list}{$one}{sub_acc} . ", ";
		print "T: " . $item->{list}{$one}{tot_item} . "/";
		print $item->{list}{$one}{tot_acc} . ", ";
		print "F: " . $item->{list}{$one}{fin_item} . "/";
		print $item->{list}{$one}{fin_acc} . ", ";
		print "Y: " . $item->{list}{$one}{yet_item} . "/";
		print $item->{list}{$one}{yet_acc} ;
		print ")  ";
		print "\n";

		if ($self->{mode} =~ /full/ || $self->{mode} =~ /desc/ )
		{
			print " "x($depth*4 + 2);
			print "| Subject : " . $item->{list}{$one}{subject}. "\n";
			print " "x($depth*4 + 2);
			print "| Object  : " . $item->{list}{$one}{object}. "\n";
			print " "x($depth*4 + 2);
			print "| Items   : \n";

			foreach my $one_item ( @{$item->{list}{$one}{items}})
			{
			    print " "x($depth*4 + 4);
				print $one_item . "\n";
			}

		}
		if ($item->{list}{$one}{list})
		{
		    $self->print_item($item->{list}{$one}, $depth+1, $self->{mode});
		}
	}
}

sub print_summary
{
	my $self = shift;

	my $start_chk = $chk->{list}{$self->{start_check_name}};

	print " < CHECKLIST SUMMARY >\n";
	print " " . "-"x70 . "\n";
	print " |    D : the number of subdirectory\n";
	print " |    T : the total number of items\n";
	print " |    F : the number of completed item\n";
	print " |    Y : the number of remains\n";
	print " |    (cnt1/cnt2) : \n";
	print " |       cnt1 is the number of its own items.\n";
	print " |       cnt2 is the accumulated number including child recursively.\n";
	print " " . "-"x70 . "\n";
	print "  (";
	print "D :" . $start_chk->{sub_cnt} . "/";
	print $start_chk->{sub_acc} . ", ";
	print "T :" . $start_chk->{tot_item} . "/";
	print $start_chk->{tot_acc} . ", ";
	print "F :" . $start_chk->{fin_item} . "/";
	print $start_chk->{fin_acc} . ", ";
	print "Y :" . $start_chk->{yet_item} . "/";
	print $start_chk->{yet_acc} ;
	print ")\n";

    $self->print_item ( $start_chk,1, $self->{mode});
}

1;

