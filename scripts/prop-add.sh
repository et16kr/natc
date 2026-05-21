if [ $# -eq 1 ]
then
    PROP_NAME_EQ_VALUE=$1
    cd $ALTIBASE_HOME/conf

    echo "adding $PROP_NAME_EQ_VALUE to altibase.properties"
    echo "$PROP_NAME_EQ_VALUE" >> altibase.properties
else
    echo "Usage : prop-add.sh [ PropertyName=Value ]"
fi
