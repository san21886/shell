#!/bin/bash

while read line 
do
	seventh_colmn=$(echo $line|awk -F'|' '{print $7}')
	if [[ $seventh_colmn == '"A"' ]];then
		echo $seventh_colmn
		for count in $(seq 0 9); do
			nl=$(echo $line|awk 'BEGIN { FS="|"; OFS="|" } {sub("A",'$count',$7);print}')
echo $nl
		done
	else
		echo $line
	fi
done <$1
