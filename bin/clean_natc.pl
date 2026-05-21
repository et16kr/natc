#!/usr/local/bin/perl -w

# BUG-15182 디스크 공간 최적화

# 테스트 수행후 디프가 발생하지 않은 테스트 케이스의 생성된 파일을 삭제하는 프로그램

# 이프로그램의 역활은 파일 한개를 입력으로 받아 이보다 나중에 생성된 파일및 디렉토리를
# 지우는 역활을 합니다.
#
# 지울수 있는 조건은 그 디렉토리 또는 하위 디렉토리에 전혀 out 파일이 생성되어 있지 않아
# 야 합니다. 
# 때문에 diff가 많이 날 경우, 즉 fail이 많이 날경우에는 성능이 그렇게 좋지 않을 수도 있
# 습니다.
#
#
#
#
# 동작 하는 방법을 설명하겠습니다.
#
# 만약 SM.ts를 돌린후 이것으로 인해 생성된 파일을 지우겠다라고 한다면,
#    SM.ts파일의 처음부분에 clean_natc_start.sql을 적고
#    마지막 부분에 clean_natc_end.sql을 적습니다. 
#
#    각각의 역활은 
#    clean_natc_start.sql에서는 atc 수행전에 임시 파일을 만들고, (이때 생성하는 파일이
#	    clean_natc.tmp입니다. 만약 이파일이 이미 존재한다면, 이것을 지우게 되므로, 같은 이름의
#	    파일이 없도록 해야 합니다. )
#    clean_natc_end.sql에서는 이 임시파일을 clean_natc.pl에 입력으로 주어서 이후에 생성되고
#    diff가 없는( 즉, 지워도 상관없는) 생성파일들을 삭제합니다.   


# 사용자가 임의로 만든 디렉토리는 그 디렉토리가 속한 모든 디렉토리와 하위 디렉토리에
# diff가 하나도 없을 때에만 삭제하게 됩니다. 
#�

# 즉, bug1, bug2, bug3, db 라는 것이 prj1 이라는 디렉토리에 존재하고 이것들이 모두 디렉
# 토리라고 가정할때,
#
#    +prj1
#    |  +--- bug1
#    |  +--- bug2
#    |  +--- bug3
#    |  +--- db
#    +prj2
#       +----bug10
#          +----bug11
#
#	     
# db및 그 하위 내용을 지우는 조건은 
# bug1, bug2, bug3 하위 내용에 전혀 out파일이 생성되지 않았을때 지우게 됩니다. 
# 그리고 prj2및 그 하위 디렉토리의 디프 여부는 db 삭제에 전혀 영향을 끼치지 않습니다. 



if( $ARGV[0] )
{
    $begin_file_name=$ARGV[0];
}
else
{
    print "missing input file\n";
    return;
}

#입력으로 받은 파일의 생성시간을 구한후, 전역 변수로 그 값을 유지
@begin_file_info = stat($begin_file_name);
$begin_file_mtime = $begin_file_info[9];

sub is_out_file
{
    local($fname);
    $fname = shift;

    $fname = lc($fname);
    chomp($fname);

    if($fname =~ /\S+\.out$/ )
    {
	return True;
    }
    return False;
}


#디렉토리를 탐색할때, 무시할 파일및 디렉토리를 설정
sub is_ignore
{
    local($fname);
    $fname = shift;

    $fname = lc($fname);
    chomp($fname);

    if($fname =~ /^\.\S+/ ) #ignore hided file
    {
	return True;
    }
    elsif( $fname eq "." || $fname eq "..")
    {
	return True;
    }
    elsif( -l $fname ) #ignore symbolic link
    {
	return True;
    }
    else
    {
	return False;
    }
}

#테스트 케이스 파일인지 여부를 검사.
#현재 lst, ts, sql로 끝나는 파일만을 테스트 케이스 파일이라고 여긴다.
sub is_testcase_file
{
    local($fname);
    $fname = shift;

    $fname = lc($fname);
    chomp($fname);

    if($fname =~ /\S+\.lst$/ )
    {
	return True;
    }
    elsif($fname =~ /\S+\.ts$/ )
    {
	return True;
    }
    elsif($fname =~ /\S+\.sql$/ )
    {
	return True;
    }
    else
    {
	return False;
    }
}

sub later_created_file
{
    local($fname, @file_info, $file_mtime );
    $fname = shift;

#지우고자 하는 파일의 생성시간을 가져옴
    @file_info = lstat($fname);
    $file_mtime= $file_info[9];

#이것의 생성시간이 위에서 설정한 생성시간보다 크다면,
#즉, 테스트 케이스 수행중 만들어진 파일이라면
    if( $begin_file_mtime < $file_mtime )
    {
	return True;
    }
    return False;
}


#현재디렉토리및 하위파일들을 삭제한다.
#디렉토리의 경우 그 하위 디렉토리까지 내려가서 모든 파일을 삭제한다.
#dfs 방식으로 삭제를 수행
sub delete_all
{
    local(@allfiles);

    opendir(DEL_ALL_DIR, ".");
    @allfiles=readdir(DEL_ALL_DIR);
    closedir(DEL_ALL_DIR);

    foreach(@allfiles)
    {
	if( is_ignore($_) eq True)
	{
	    next;
	}

	if( later_created_file($_) eq True )
	{
	    if( -d $_ )
	    {
		chdir $_ || die "Can't cd to $_";
		delete_all();
		chdir "..";
		
		print "rmdir ".`pwd`.$_." in delete_all\n";
		rmdir $_ || print "cannot delete file  ".$_."\n";
	    }
	    else
	    {
		print "unlink ".`pwd`.$_." in delete_all\n";
		unlink $_ || print "cannot delete file  ".$_."\n";
	    }
	}
    }
}


#인자로 받은 모든 디렉토리의 내용을 깨끗이 삭제한다.
sub delete_force
{
    foreach(@_)
    {
	print "force ".$_."\n";
	chdir $_ || die "Can't cd to $_";
	delete_all($_);
	chdir "..";
    }
}

#현재 디렉토리내의 파일중에서 테스트가 시작된 이후에 생성된 파일을 삭제한다.
#이함수가 수행되기 위해서는 이 디렉토리 아래에
#out파일이 생성되지 않았어야 한다.
#이함수는 디렉토리가 나올경우 그 아래까지 내려가서 삭제를 수행하지 않는다. 
sub delete_created_files
{
    local(@allfiles, @file_info, $file_mtime);
    opendir(DEL_DIR, ".");
    @allfiles=readdir(DEL_DIR);
    closedir(DEL_DIR);

    foreach(@allfiles)
    {
	if( is_ignore($_) eq True)
	{
	    next;
	}

	if( later_created_file($_) eq True )
	{
	    if( -d $_ )
	    {
		print "rmdir ".`pwd`.$_."\n";
		rmdir $_ || print "cannot delete file  ".$_."\n";
	    }
	    else
	    {
		print "unlink ".`pwd`.$_."\n";
		unlink $_ || print "cannot delete file  ".$_."\n";
	    }
	}
    }
}

#실제 디렉토리를 탐색하면서 이것이 삭제할 디렉토리인지 판단하는 함수
#여기에서 삭제를 명령한다.
sub process_dir
{
    local(@allfiles);
    local($special_dir, $out_file , $testcase_file);
    local(@special_dir_list );

    opendir(DIR, ".");
    @allfiles=readdir(DIR);
    closedir(DIR);

    $special_dir = True;
#현재 디렉토리의 하위 디렉토리중에서 하나도 테스트케이스 파일을 가지고 �
#있지 않는 디렉토리를 special_dir 이라 칭하고, 그들의 리스트를 가지는 변수
    @special_dir_list = (); 
#현재 디렉토리에 out파일이 한개라도 존재하는지 여부
#만약 out파일이 존재한다면, 현재 디렉토리에 있는 어떤것도 지우지 않는다.
#이것은 하위디렉토리에 out파일이 있는지 여부도 포함한다.
    $out_file = False;
#현재 디렉토리에 하나라도 테스트케이스 파일이 존재하는지 여부
    $testcase_file = False;
    foreach(@allfiles)
    {
	if( is_ignore( $_ ) eq True )
	{
	    next;
	}

	if( -d $_ )	#directory
	{
	    chdir $_ || die "Can't cd to $_";
	    ($out_file, $special_dir) = process_dir();
	    chdir "..";

#만약 하위디렉토리가 special_dir이라면, 즉, 그 디렉토리내에 전혀 테스트케이스
#파일이 없다면 이것은 일단 리스트에 넣는다. 이것을 지울수 있는 조건은
#현재 디렉토리 및 하위 디렉토리에 전혀 out파일이 없었어야 하고,
#현재 디렉토리에 테스트케이스 파일이 한개라도 존재해야 한다. 즉, 현재 디렉토리는
#special_dir이 아니어야 한다..
	    if( $special_dir eq True )
	    {
		push @special_dir_list, $_;
	    }
	}
	else		#normal file
	{
#하나라도 out파일이 있을경우 
	    if(is_out_file($_) eq True)
	    {
		$out_file = True;
	    }
	    if( is_testcase_file($_) eq True)
	    {
		$testcase_file = True;
	    }
	}
    }

    #만약 자신의 디렉토리내에 한개도 테스트케이스 파일이 없다면
    #현재 디렉토리의 내용을 전혀 삭제하지 않고 special_dir을 true로 리턴함
    if($special_dir eq True && $testcase_file eq False )
    {
	print `pwd`."  special dir\n";
	return (False,True);
    }

#하나의 out파일도 현재 디렉토리 내에 존재하지 않음.
#즉 현재 디렉토리의 내용은 지워도 상관없음
    if( $out_file eq False )
    {
	if( @special_dir_list )
	{
#special_dir의 경우엔 다른 디렉토리들과 다르게( 다른디렉토리는 삭제를 하면서 올라옴)
#전혀 삭제를 수행하지 않았기 때문에 delete_force로 모든 디렉토리를 깨끗하게 삭제한다.
	    print `pwd`."  deleteforce\n";
	    print join ",", @special_dir_list;
	    delete_force(@special_dir_list); 
	}

	delete_created_files();
    }
    return ($out_file, False );
}

process_dir();

