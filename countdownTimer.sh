#!/bin/bash
# a countdown timer

secs=$1
counter=0

echo "Countdown in every 30 seconds now..."
echo -n "$secs..."
while [ $secs -gt 0 ]; do
 secs=$(($secs - 1))
 counter=$(($counter + 1))
 if [ $counter -ge 30 ]; then
   echo -n "$secs..."
   counter=0
 fi 
 sleep 1
done
echo ""

exit 0
