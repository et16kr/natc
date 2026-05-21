cd $ALTIBASE_HOME/conf

if [ $# -eq 1 ]
then
    DIR_COUNT=$1
    i=1
    while [ $i -le $DIR_COUNT ]
    do
        prop="LOG_DIR=?/logs$i"
        echo "adding $prop to altibase.properties"
        echo "$prop" >> altibase.properties

        prop="LOG_BUFFER_TYPE=0"
        echo "adding $prop to altibase.properties"
        echo "$prop" >> altibase.properties

        i=`expr $i + 1`
    done
    
    lines=`grep '\<LOG_DIR' altibase.properties | wc -l`
    if [ $lines -eq $DIR_COUNT ]
    then
        echo "The LOG_DIR properties has been added successfully.";
    else
        echo "ERROR : \"LOG_DIR\" property exists $lines times";
    fi
else
    echo "Usage : prop-log-dirs.sh [ LOG_DIR_COUNT ]"
fi
cd $ALTIBASE_HOME/conf

