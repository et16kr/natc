ls -l *.out | awk '{print "mv " $9 " " $9}' | sed 's/out$/lst/' > ./ttt
chmod +x ./ttt
sh ./ttt
rm ./ttt
