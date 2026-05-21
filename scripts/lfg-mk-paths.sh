if [ $# -eq 1 ]
then
    LFG_COUNT=$1

    cd $ALTIBASE_HOME

    i=1
    while [ $i -le $LFG_COUNT ]
    do
        LOG_DIR=logs$i
        ARCHIVE_DIR=arch_logs$i

        echo "creating $LOG_DIR"
        echo "creating $ARCHIVE_DIR"

        mkdir $LOG_DIR
        mkdir $ARCHIVE_DIR
        i=`expr $i + 1`
    done
else
    echo "Usage : lfg-mk-paths.sh [log file group count]"
fi
