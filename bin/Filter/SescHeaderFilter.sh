cat $1 | sed "s/^ *//g" | awk '{ n++; if (n > 6) print $0;}' > $1.tmp
mv $1.tmp $1
