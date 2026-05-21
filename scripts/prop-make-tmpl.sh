cd $ALTIBASE_HOME/conf

sed -e "/LOG_FILE_GROUP_COUNT/d" altibase.properties |   \
sed -e "/PAGE_LIST_GROUP_COUNT/d" |   \
sed -e "/^LOG_DIR/d" |                                    \
sed -e "/^#/d" |                                    \
sed -e "/LOG_BUFFER_TYPE/d" |                            \
sed -e "/ARCHIVE_DIR/d" > altibase.properties.tmpl
