#!/bin/sh

if [ $# != 1 ]; then
    echo "usage: getEndLogOffset.sh LFG_ID"
    exit
fi

ISQL="${ALTIBASE_HOME}/bin/isql -s 127.0.0.1 -u sys -p MANAGER -silent"

${ISQL} << EOF | grep -v "CUR" | grep -v "select"  | grep '^[0-9]' > log.txt
SELECT CUR_WRITE_LF_NO, CUR_WRITE_LF_OFFSET FROM V\$LFG;
EXIT;
EOF

${ISQL} << EOF | grep -v "CUR" | grep -v "select"  | grep '^[0-9]' > size.txt
SELECT VALUE1 FROM V\$PROPERTY WHERE NAME = 'LOG_FILE_SIZE';
EXIT;
EOF

fileID=`cat log.txt | awk '{print $1}'`
offset=`cat log.txt | awk '{print $2}'`
logsize=`cat size.txt | awk '{print $1}'`

totalsize=`expr $logsize \* $fileID + $offset`

echo $totalsize
