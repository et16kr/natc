if [ $# -ne 1 ]
then
   echo "Usage : logs-cp-from-alogs.sh <Altibase Home>"
   exit;
fi

ALTI_HOME=$1

for d in logs logs1 logs2
do
   cp $ALTI_HOME/arch_$d/* $ALTI_HOME/$d >> logs-cp-from-alogs.txt
done
