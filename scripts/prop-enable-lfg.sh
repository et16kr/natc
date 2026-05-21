
if [ $# -eq 1 ]
then
    LFG_COUNT=$1
    echo "Setting up altibase_home to use $LFG_COUNT LFG(s)."
    # Create Directories
    lfg-mk-paths.sh $LFG_COUNT
    # Create property template
    prop-make-tmpl.sh
    # Copy property template to altibase.properties
    prop-init.sh
    # Set LOG_FILE_GROUP_COUNT property
    prop-lfg-count.sh $LFG_COUNT
    # Set LOG_DIR properties
    prop-log-dirs.sh $LFG_COUNT
    # Set ARCHIVE_DIR properties
    prop-archive-dirs.sh $LFG_COUNT
else
    echo "Usage : prop-enable-lfg.sh [ LFG Count ]"
    echo "        Setup altibase_home to use Log File Group. "
fi

