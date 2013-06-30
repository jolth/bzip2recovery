#!/usr/bin/env bash
#
# Author: Jorge Toro [jolthgs@gmail.com]
#
# usage: 
#        ./bzip2recovery.sh the_bad_backup.tar.bz2
#
declare -a BADFILES
arg1=$1
bad_dir="bad_files"
FILE="good_file"

# function imp
imp() {
    for c in $@; do
        echo $c
    done
}

## default blocksize bzip2
bzip2recover $arg1

# Corrupt file 
mkdir $bad_dir

n=0
for i in $(ls -l rec*bz2 | awk '{print $9}'); do
    bunzip2 -t $i 2> /dev/null 
    if [ "$?" != "0" ]; then
        echo "Bad File: " $i
        mv $i $bad_dir
        BADFILES[$n]=$i
        ((n++))
        echo >> $FILE
    else
        echo $i | sed s/\.bz2/\ / >> $FILE
    fi
done

echo "BAD FILES:"
imp ${BADFILES[@]}  

## DECOMPRESS
echo "DECOMPRESS:"
sleep 3
#bunzip2 rec*bz2
while read l; do
    f="$l.bz2"
    if [ -f "$f" ]; then
        echo $f
        bunzip2 $f
    fi
done < $FILE

## JOINs
echo "JOINs:"
declare -a PART
tarn=1
TAR_FILE="part_$tarn.tar"
while read x; do
    if [ -f "$x" ]; then
        echo "Add: $x into $TAR_FILE"
        cat $x >> $TAR_FILE
    else
        echo "End: $TAR_FILE"
        PART[$tarn]=$TAR_FILE
        ((++tarn))
        TAR_FILE="part_$tarn.tar"
        sleep 1
    fi
done < $FILE
PART[$tarn]=$TAR_FILE
#
echo "GOOD FILES:"
imp ${PART[@]}  

## RECOVERY
echo "RECOVERY"
sleep 3

for x in ${PART[@]}; do
   EXTF="process_$x"
   echo "Processing" $x 
   perl find_tar_headers.pl $x | tee recovery.log  
   pos=$(awk -F':' '{print $2}' recovery.log | head -n1)
   tail -c +${pos} $x > $EXTF
   echo "Extracting..." $EXTF
   tar xvf $EXTF
done

