if [ $# -ne 2 ]
then
   echo "Usage : logs-cp.sh <Src Altibase Home> <Dest Altibase Home>"
   exit;
fi

SRC_HOME=$1
DST_HOME=$2

for d in logs logs1 logs2
do
   cp $SRC_HOME/$d/* $DST_HOME/$d >> logs-cp.txt
done
