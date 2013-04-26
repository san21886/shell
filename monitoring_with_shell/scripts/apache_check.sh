#!/bin/bash

current_directory=`dirname $0`
. $current_directory/common_envs.sh

mail_recepients_list=$current_directory/mail_recepients
if [[ $1 == "--test" ]];then
	mail_recepients_list=$current_directory/mail_test
fi

apache_status=$(/etc/init.d/apache2 status|grep "Apache2 is running"|grep -v 'grep')
if [[ -z $apache_status ]];then
	while read email_id
	do	
		echo "mail: $email_id"
		$current_directory/mail.sh $email_id $MAIL_SENDER "$NODE_NAME(`hostname`): Urgent Attention Required. Apache is down" ""
	done < $mail_recepients_list
fi
