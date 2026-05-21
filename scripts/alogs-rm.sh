if [ $# -ne 1 ]
then
   echo "Usage : alogs-rm.sh <Altibase Home>"
   exit;
fi

ALTI_HOME=$1

for d in arch_logs arch_logs1 arch_logs2
do
   rm $ALTI_HOME/$d/* >> alogs-rm.log
done
