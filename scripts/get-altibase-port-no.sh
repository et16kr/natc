IS_ENV_SET=`env | grep ALTIBASE_PORT_NO | wc -l`

if [ $IS_ENV_SET -eq 0 ]
then
    cat $ALTIBASE_HOME/conf/altibase.properties | sed 's/REPLICATION_PORT_NO//g' | grep PORT_NO | gawk 'BEGIN{FS="="}{print $2}' | sed 's/ //g'
else
    echo "$ALTIBASE_PORT_NO"
fi
