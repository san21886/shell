#!/bin/bash


function get_associated_pids_info
{
	local parent_pid=
	local associatedpsinfo=
	if [ -f $1 ]; then #if pid is obtained from a file, like in god
		parent_pid=$(cat $1) 
	elif [ ! -z $1 ];then #if argument passed is pid
		parent_pid=$1
	fi

	if [ ! -z $parent_pid ];then
		#pstree -a -p $pid
		local associatedpsinfo=`pstree  -p $parent_pid|sed s/\-/' '/g`
	fi
	#return in bash function only accepts numeric argument. To return a string, echo will help perform return operation on srring. 
	echo $associatedpsinfo
}


function generate_kill_file
{
	#get_associated_pids_info $1
	[ ! -d "/tmp/sdf_kill_files" ] && mkdir -pv "/tmp/sdf_kill_files"
	associatedpsinfo=$(get_associated_pids_info $1)
	for pid in $associatedpsinfo 
	do
		pid=$(echo $pid|cut -d'(' -f2|cut -d')' -f1|grep '[0-9]')
		[ ! -z $pid ] &&  touch "/tmp/sdf_kill_files/sdf_monitor_pid_"$pid"_kill" && echo "/tmp/sdf_kill_files/sdf_monitor_pid_"$pid"_kill" >&2
	done
}

function kill_process
{
	associatedpsinfo=$(get_associated_pids_info $1)
	for pid in $associatedpsinfo 
	do
		pid=$(echo $pid|cut -d'(' -f2|cut -d')' -f1|grep '[0-9]')
		[ ! -z $pid ] &&  kill $pid && echo "killed $pid" >&2
	done
}

function kill_process_force
{
	associatedpsinfo=$(get_associated_pids_info $1)
	for pid in $associatedpsinfo  
	do
		pid=$(echo $pid|cut -d'(' -f2|cut -d')' -f1|grep '[0-9]')
		[ ! -z $pid ] &&  kill -9 $pid && echo "killed $pid, with flag 9" >&2
	done
}

function usage
{
	echo "$0 generate_kill_file <pid_file>|<pid>" >&2
	echo "$0 kill_process <pid_file>|<pid>" >&2
	echo "$0 kill_process_force <pid_file>|<pid>" >&2
}


if [[ $1 == "generate_kill_file" ]];then
	generate_kill_file $2
elif [[ $1 == "kill_process" ]];then
	kill_process $2
elif [[ $1 == "kill_process_force" ]];then
	kill_process_force $2
else
	usage
fi
