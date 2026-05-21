if [ $# -ne 2 ]
then
   echo "Usage : alogs-cp.sh <Src Altibase Home> <Dest Altibase Home>"
   exit;
fi

SRC_HOME=$1
DST_HOME=$2

for d in arch_logs arch_logs1 arch_logs2
do
   cp $SRC_HOME/$d/* $DST_HOME/$d >> alogs-cp.txt
done
