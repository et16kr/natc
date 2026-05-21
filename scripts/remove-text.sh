if [ $# -ne 1 ]
then 
   echo "Usage : remove-text.sh <text to remove>"
   exit
fi

TEXT=$1
sed -e "s|${TEXT}||g" 
