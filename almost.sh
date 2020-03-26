#!/bin/bash
echo "*****************"
echo "**             **"
echo "**  almost.sh  **"
echo "**             **"
echo "*****************"
day=$(date +%A)
echo day ${day}

export PGPASSWORD=devDBmobilaku;
# check auction or not
active=$(psql -h localhost -U devkg -d kg_mobilaku -t -c "SELECT \"active\" FROM \"auctionTimers\" WHERE day='$day'")
if [ $active -eq 1 ]
then
  # check begin time
  begin=$(psql -h localhost -U devkg -d kg_mobilaku -t -c "SELECT \"timeBegin\" FROM \"auctionTimers\" WHERE day='$day'")
  end=$(psql -h localhost -U devkg -d kg_mobilaku -t -c "SELECT \"timeEnd\" FROM \"auctionTimers\" WHERE day='$day'")
  now=$(date +%H:%M:%S)
  echo now $now

  secBegin=`date +%s -d ${begin}`
  secEnd=`date +%s -d ${end}`
  secNow=`date +%s -d ${now}`

  diffSecBegin=`expr ${secBegin} - ${secNow}`
  diffSecEnd=`expr ${secEnd} - ${secNow}`
  echo Took ${diffSecBegin} seconds.
  echo Took ${diffSecEnd} seconds.

  # And use date to convert the seconds back to something more meaningful
  # echo Took `date +%H:%M:%S -ud @${diffSecBegin}`
  if [ $diffSecBegin -gt 0  -a  $diffSecBegin -le 900 ]
  then
    echo "15 menit lagi lelang akan dimulai"
  elif [ $diffSecEnd -gt 0  -a  $diffSecEnd -le 900 ]
  then
    echo "15 menit lagi lelang akan selesai"
  fi
else
  echo "Tidak ada lelang hari ini"
fi