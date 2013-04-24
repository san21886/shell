#!/bin/bash
current_dir=`dirname $0`
. $current_dir/common_envs.sh

disk_status=$(df -h|egrep -v 'none|tmpfs|udev'|xargs -L1 echo -e|grep -v "Filesystem Size Used")
headers=$(df -h|head -1)

OIFS="${IFS}"
NIFS=$'\n'
 
IFS="${NIFS}"
#critical_drives=("$headers")
 
count=1
warn_percent_usage=80
body=$headers
for LINE in ${disk_status} ; do
    IFS="${OIFS}"
    percent_used=$(echo "${LINE}"|awk '{print $5}'|sed 's/%//g')
    drive=$(echo "${LINE}"|awk '{print $6}')
    if [[ $percent_used -gt $warn_percent_usage ]];then
	#critical_drives[$count]=$LINE
	body="$body \n $LINE"
	count=$(($count + 1))
    fi
    IFS="${NIFS}"
done


if [[ $count != 1 ]];then
	while read email_id
	do	
		echo "sending mail to $email_id" >&2
		$current_dir/mail.sh $email_id $MAIL_SENDER "$NODE_NAME(`hostname`): Warn Disk Size." "`echo -e $body`"
	done < $current_dir/mail_recepients
fi
IFS="${OIFS}"
