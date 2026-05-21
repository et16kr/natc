if [ $# -ne 1 ]
then
   echo "Usage : logs-rmdir.sh <Altibase Home>"
   exit;
fi

ALTI_HOME=$1

for d in logs logs1 logs2
do
   rm -rf $ALTI_HOME/$d >> logs-rmdir.log
done
