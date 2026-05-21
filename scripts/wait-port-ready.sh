WAIT_PORT=$1
if [ $# -eq 1 ]
then
    echo "Waiting for port $i to be ready for binding."

    connected=1
    while [ $connected -ne 0 ]
    do
        telnet localhost $WAIT_PORT > telnet.log &
        telnet_pid=$!

        sleep 1
        echo "killing telnet process(pid:$telnet_pid)."
        kill -9 $telnet_pid
        connected=`grep "Connected" telnet.log | wc -l`
    done

    echo "Port $WAIT_PORT is ready for binding."
else
    echo "Usage : wait-port-ready.sh <Port No.> "
fi

