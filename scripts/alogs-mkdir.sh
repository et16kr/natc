if [ $# -ne 1 ]
then
   echo "Usage : alogs-mkdir.sh <Altibase Home>"
   exit;
fi

ALTI_HOME=$1

for d in arch_logs arch_logs1 arch_logs2
do
   mkdir $ALTI_HOME/$d >> alogs-mkdir.log
done
