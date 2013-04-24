#!/bin/bash
current_dir=`dirname $0`
. $current_dir/common_envs.sh

while read email_id
do	
	$current_dir/mail.sh $email_id $MAIL_SENDER "$NODE_NAME(`hostname`): Urgent Attention: Node Rebooted" "REBOOTED"
done < $current_dir/mail_recepients
