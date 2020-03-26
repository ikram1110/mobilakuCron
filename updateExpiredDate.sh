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
# psql -h localhost -U devkg -d kg_mobilaku -c "UPDATE \"transactionInvoices\" SET \"paid\"=2 where \"paid\"=0 and now() > \"datetimeExpired\"::timestamp"

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