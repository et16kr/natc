cd $ALTIBASE_HOME/conf

if [ $# -eq 1 ]
then
    LFG_COUNT=$1

    echo "LOG_FILE_GROUP_COUNT=$LFG_COUNT" >> altibase.properties
    echo "PAGE_LIST_GROUP_COUNT=$LFG_COUNT" >> altibase.properties
    
    lines=`grep "LOG_FILE_GROUP_COUNT" altibase.properties | wc -l`
    if [ $lines -eq 1 ]
    then
        echo "The LOG_FILE_GROUP_COUNT property has been added successfully.";
    else
        echo "ERROR : \"LOG_FILE_GROUP_COUNT\" property exists $lines times";
    fi

    lines=`grep "PAGE_LIST_GROUP_COUNT" altibase.properties | wc -l`
    if [ $lines -eq 1 ]
    then
        echo "The PAGE_LIST_GROUP_COUNT property has been added successfully.";
    else
        echo "ERROR : \"PAGE_LIST_GROUP_COUNT\" property exists $lines times";
    fi


else
    echo "Usage : prop-lfg-count.sh [ LOG_FILE_GROUP_COUNT ]"
fi
