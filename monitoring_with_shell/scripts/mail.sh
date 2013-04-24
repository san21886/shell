#!/bin/bash

usage(){
	echo $0 "<to> <from> <subject> <body>"
	exit 255
}

if [[ $# != 4 ]];then
	usage
fi

TO_EMAIL_ID=$1
FROM_EMAIL_ID=$2
MAIL_SUBJECT=$3

MAIL_CONTENT=$4

cat << EOF|sendmail -f $FROM_EMAIL_ID -t $TO_EMAIL_ID
Subject: $MAIL_SUBJECT
$MAIL_CONTENT
EOF
