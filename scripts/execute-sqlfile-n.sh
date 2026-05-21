#!/usr/bin/sh

if [ $# -lt 2 ]
then
    echo "Usage : execute-sqlfile-n.sh <times> <filename>"
    exit;
fi

times=$1

i=0
while [ 1 ]
do
    if [ `bash is-server-dead.sh` -eq 1 ]
    then
        echo "server is dead. exiting execute-sqlfile-n.sh"
        break;
    fi

    is -f $2

    i=`echo "$i +1" | bc`
    if [ $i -eq $times ]
    then
        echo "execution finished. exiting execute-sqlfile-n.sh"
        break;
    fi
done
