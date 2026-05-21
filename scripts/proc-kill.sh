#/usr/local/bin/bash

if [ "x$1" == "x" ]
then
    echo "argument required!!"
    exit 0
fi

ps -ef | grep $LOGNAME | grep $1 | grep -v grep | awk '{print "kill -9 " $2}' | sh

