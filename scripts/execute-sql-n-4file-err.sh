#!/usr/local/bin/bash
if [ $# -lt 2 ]
then 
    echo "Usage : execute-sql-n.sh <times> <cmd1> <cmd2> <cmd3>"
    exit;    
fi


times=$1
cmd1="$2;"
cmd2="$3;"
cmd3="$4;"

if [ "$cmd1" = "<EOS>" ]
then
    # Do not execute anything if the statement is <EOS>
    # EOS means end of statement
    return;
fi

function runit
{
    command=$1
    if [ "$command" != ";" ]
    then
       echo "$command" | ${ALTIBASE_HOME}/bin/isql -s 127.0.0.1 -u sys -p MANAGER | grep ERR | sed -e 's/\/.*\///g'
    fi
}

i=0
while [ 1 ] 
do
    if [ `bash is-server-dead.sh` -eq 1 ]
    then
        echo "server is dead. exiting execute-sql-n.sh"
        break;
    fi
    runit "$cmd1"
    runit "$cmd2"
    runit "$cmd3"

    i=`echo "$i +1" | bc`
    if [ $i -eq $times ]
    then
        break;
    fi
done
