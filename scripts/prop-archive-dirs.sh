cd $ALTIBASE_HOME/conf

if [ $# -eq 1 ]
then
    DIR_COUNT=$1
    i=1
    while [ $i -le $DIR_COUNT ]
    do
        prop="ARCHIVE_DIR=?/arch_logs$i"
        echo "adding $prop to altibase.properties"
        echo "$prop" >> altibase.properties
        i=`expr $i + 1`
    done
    
    lines=`grep "ARCHIVE_DIR" altibase.properties | wc -l`
    if [ $lines -eq $DIR_COUNT ]
    then
        echo "The ARCHIVE_DIR properties has been added successfully.";
    else
        echo "ERROR : \"ARCHIVE_DIR\" property exists $lines times";
    fi
else
    echo "Usage : prop-archive-dirs.sh [ ARCHIVE_DIR_COUNT ]"
fi
