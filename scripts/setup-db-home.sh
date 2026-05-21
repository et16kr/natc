if [ $# -eq 2 ]
then
    LFG_ALTIBASE_HOME=$1
    LFG_COUNT=$2
    rm -rf $LFG_ALTIBASE_HOME
    mkdir $LFG_ALTIBASE_HOME
    mkdir $LFG_ALTIBASE_HOME/dbs
    mkdir $LFG_ALTIBASE_HOME/logs
    mkdir $LFG_ALTIBASE_HOME/trc

    i=1
    while [ $i -le $LFG_COUNT ]
    do
        mkdir $LFG_ALTIBASE_HOME/logs$i
        mkdir $LFG_ALTIBASE_HOME/arch_logs$i
        i=`expr $i + 1`
    done

    for dir in conf
    do
        cp -r $ALTIBASE_HOME/$dir $LFG_ALTIBASE_HOME/$dir
    done

    for dir in admin audit bin include install lib msg nproc sample 
    do
        ln -s $ALTIBASE_HOME/$dir $LFG_ALTIBASE_HOME/$dir
    done
else
    echo "Usage : setup-db-home.sh [altibase-home-path] [log file group count]"
fi
