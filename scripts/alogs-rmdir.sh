if [ $# -ne 1 ]
then
   echo "Usage : alogs-rmdir.sh <Altibase Home>"
   exit;
fi

ALTI_HOME=$1

for d in arch_logs arch_logs1 arch_logs2
do
   rm -rf $ALTI_HOME/$d >> alogs-rmdir.log
done
