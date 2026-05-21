if [ $# -eq 1 ]
then
    PROP_NAME=$1
    cd $ALTIBASE_HOME/conf

    sed -e "/$PROP_NAME/d" altibase.properties > altibase.properties.removed.$PROP_NAME

    cp altibase.properties.removed.$PROP_NAME altibase.properties
    rm altibase.properties.removed.$PROP_NAME
else
    echo "Usage : prop-remove.sh [ Property Name ]"
fi
