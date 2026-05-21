if [ $# -ne 1 ]
then
   echo "Usage : logs-rm.sh <Altibase Home>"
   exit;
fi

ALTI_HOME=$1

for d in logs logs1 logs2
do
   rm $ALTI_HOME/$d/* >> logs-rm.log
done
