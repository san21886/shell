#!/bin/bash

current_dir=`dirname $0`

. $current_dir/common_envs.sh

disk_status=$(df -h|egrep -v 'none|tmpfs|udev')
while read email_id
do
	$current_dir/mail.sh $email_id $MAIL_SENDER "$NODE_NAME(`hostname`): Disk Report" "$disk_status"
done < $current_dir/mail_recepients
