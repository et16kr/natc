if [ $# -ne 1 ]
then
   echo "Usage : logs-mkdir.sh <Altibase Home>"
   exit;
fi

ALTI_HOME=$1

for d in logs logs1 logs2
do
   mkdir $ALTI_HOME/$d >> logs-mkdir.log
done
