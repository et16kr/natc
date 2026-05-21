#!/bin/sh

if [ -f $ALTIBASE_HOME/install/altibase_env.mk ]
then
	env_file="$ALTIBASE_HOME/install/altibase_env.mk"
else
	env_file="$ATC_HOME/../altidev/env.mk"
fi

# Get the product class of altibase server
echo exit | dbadmin | grep Ver | awk '{print "ALTIBASE_PRODUCT=A" substr($4,1,1)}'

# Get the version number of altibase server
echo exit | dbadmin | grep Ver | awk '{print "ALTIBASE_VERSION=" $4}'

# Get the bit info of altibase server
grep -i "compile64=" $env_file | awk '{FS="="; printf "ALTIBASE_BIT="; if ($2 == "" ) { print "32";} else {print "64"}}'

# Get the build mode of altibase server
grep "BUILD_MODE=" $env_file | awk '{FS="=";print "ALTIBASE_BUILD=" $2}'

# Get the os info for altibase server
grep "OS_TARGET=" $env_file | awk '{FS="=";print "ALTIBASE_OS=" $2}'

# Get the os major version info for altibase server
grep "OS_MAJORVER=" $env_file | awk '{FS="=";print "ALTIBASE_OS_MAJOR=" $2}'

# Get the os minor version info for altibase server
grep "OS_MINORVER=" $env_file | awk '{FS="=";print "ALTIBASE_OS_MINOR=" $2}'
