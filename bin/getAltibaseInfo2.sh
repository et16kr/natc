#!/bin/sh

if [ -f $ALTIBASE_HOME/install/altibase_env.mk ]
then
	env_file="$ALTIBASE_HOME/install/altibase_env.mk"
else
	env_file="$ATC_HOME/../altidev/env.mk"
fi

if [ "$1" = "product" ]
then
	echo exit | dbadmin | grep Ver | awk '{print substr($4,1,1)}'
fi

if [ "$1" = "version" ]
then
	echo exit | dbadmin | grep Ver | awk '{print $4}'
fi

if [ "$1" = "bit" ]
then
	grep -i "compile64=" $env_file | awk '{FS="="; if ($2 == "" ) { print "32";} else {print "64"}}'
fi

if [ "$1" = "build" ]
then
	grep "BUILD_MODE=" $env_file | awk '{FS="=";print $2}'
fi

if [ "$1" = "os" ]
then
	grep "OS_TARGET=" $env_file | awk '{FS="=";print $2}'
fi

if [ "$1" = "os_ver_major" ]
then
	grep "OS_MAJORVER=" $env_file | awk '{FS="=";print $2}'
fi

if [ "$1" = "os_ver_minor" ]
then
	grep "OS_MINORVER=" $env_file | awk '{FS="=";print $2}'
fi
