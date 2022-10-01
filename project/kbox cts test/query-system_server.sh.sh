#!/bin/bash

#query-system_server.sh

start_num=$1
stop_num=$2
for num in $(seq ${start_num} ${stop_num})
do
{
	CONTAINER_NAME="kbox_$num"
	echo ${CONTAINER_NAME}:
    docker exec -it ${CONTAINER_NAME} ps -A | grep system_server
	sleep 0.5
}

done
