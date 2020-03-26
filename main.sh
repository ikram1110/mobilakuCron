#!/bin/bash
echo "*****************"
echo "**             **"
echo "**   main.sh   **"
echo "**             **"
echo "*****************"
day=$(date +%A)
echo day ${day}

export PGPASSWORD=devDBmobilaku;
#update expired date payment
psql -h localhost -U devkg -d kg_mobilaku -c "UPDATE \"transactionInvoices\" SET \"paid\"=2 where \"paid\"=0 and now() > \"datetimeExpired\"::timestamp"

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
  if [ $diffSecBegin -lt 0  -a  $diffSecBegin -ge -900 ]
  then
    echo "lelang dimulai"
    psql -h localhost -U devkg -d kg_mobilaku -c "UPDATE \"cars\" SET \"refStatusId\"=6 where \"refStatusId\"=5"
    psql -h localhost -U devkg -d kg_mobilaku -c "UPDATE \"biddingLogs\" SET \"active\"=0"
  elif [ $diffSecBegin -gt 0  -a  $diffSecBegin -le 3600 ]
  then
    echo "1 jam lagi lelang akan dimulai"
    #broadcast sms
  else
    if [ $diffSecEnd -lt 0  -a  $diffSecEnd -ge -900 ]
    then
      echo "lelang selesai"
      psql -h localhost -U devkg -d kg_mobilaku -c "UPDATE \"cars\" SET \"refStatusId\"=10 where \"refStatusId\"=6"
      psql -h localhost -U devkg -d kg_mobilaku -c "UPDATE \"cars\" SET \"refStatusId\"=8 where \"refStatusId\"=7"
      psql -h localhost -U devkg -d kg_mobilaku -c "UPDATE \"maxBiddingLogs\" SET \"active\"=0"

      psql -h localhost -U devkg -d kg_mobilaku -t -c "SELECT id from \"cars\" WHERE \"refStatusId\"=8 ORDER BY id" | while read id; do
      win=$(psql -h localhost -U devkg -d kg_mobilaku -t -c "SELECT \"dealerId\" FROM \"biddingLogs\" WHERE \"carId\"=$id ORDER by id DESC LIMIT 1")
      echo $win
      if [ $id == "id" -o $id == "----" -o $id == "(0 rows) " -o $id == "" ]
      then
        echo "cars not found"
      else
        echo "id: $id"
        psql -h localhost -U devkg -d kg_mobilaku -t -c "SELECT DISTINCT \"dealerId\" from \"biddingLogs\" WHERE \"carId\"=$id AND active=1 AND \"dealerId\"<>$win ORDER BY \"dealerId\"" | while read dealerId; do
          echo "dealerId: $dealerId"
          if [ $id == "id" -o $id == "----" -o $id == "(0 rows) " ]
          then
            echo "another dealer not found"
          else
            ticket=$(psql -h localhost -U devkg -d kg_mobilaku -t -c "SELECT \"ticket\" FROM \"dealers\" WHERE \"id\"=$dealerId")
            ticket++
            echo "ticket: $ticket"
            psql -h localhost -U devkg -d kg_mobilaku -c "UPDATE \"dealers\" SET \"ticket\"=$ticket where \"id\"=$dealerId"
          fi
        done
      fi
    done
    fi
  fi
else
  echo "Tidak ada lelang hari ini"
fi