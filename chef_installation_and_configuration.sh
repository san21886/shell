#!/bin/bash

function add_opscode_apt_repo
{
	#Debian users will likely need to run 'apt-get install sudo wget lsb-release' as root before running below command.
	echo "deb http://apt.opscode.com/ `lsb_release -cs`-0.10 main" | sudo tee -a /etc/apt/sources.list.d/opscode.list >&2
	if [[ $? != 0 ]];then
		echo "failed to add opscode apt repo" >&2
		exit 1
	else
		echo "opscode apt repo added successfully" >&2
	fi
}


function add_apt_trusted_gpg_key
{
	if [ ! -d "/etc/apt/trusted.gpg.d/" ];then
		echo "creating gpg dir:/etc/apt/trusted.gpg.d/" >&2
		sudo mkdir -p /etc/apt/trusted.gpg.d/
	fi

	if [[ $? != 0 ]];then
		echo "failed to create gpg dir" >&2
		exit 1
	fi

	echo "adding gpg key" >&2
	gpg --keyserver keys.gnupg.net --recv-keys 83EF826A
	gpg --export packages@opscode.com | sudo tee -a /etc/apt/trusted.gpg.d/opscode-keyring.gpg >&2
	if [[ $? != 0 ]];then
		echo "failed to add gpg key" >&2
		exit 1
	else
		echo "updating apt-get with new repo" >&2
		sudo apt-get update
		if [[ $? == 0 ]];then
			echo "installing opscode keyring" >&2
			sudo apt-get install opscode-keyring 
		else
			echo "failed to apt update" >&2
			exit 1
		fi
	fi
}

function install_chef_server
{
	
	echo "installing chef-server" >&2
	sudo apt-get install chef chef-server
	if [[ $? != 0 ]];then
		echo "failed to install chef-server" >&2
		exit 1
	fi
	#chef-server installation will have following effects:
	#Install all the dependencies for Chef Server, including Merb, CouchDB, RabbitMQ, etc.
	#Starts CouchDB (via the couchdb package).
	#Starts RabbitMQ (via the rabbitmq-server package).
	#Start chef-server-api via /etc/init.d/chef-server, running a merb worker on port 4000
	#Start chef-server-webui via /etc/init.d/chef-server-webui, running a merb worker on port 4040
	#Start chef-solr-indexer via /etc/init.d/chef-solr-indexer, connecting to the rabbitmq-server
	#Start chef-solr via /etc/init.d/chef-solr, using the distro package for solr-jetty
	#Start chef-client via /etc/init.d/chef-client
	#Add configuration files in /etc/chef for the client, server, solr/solr-indexer and solo
	#Create all the correct directory paths per the configuration files
}

function configure_knife_on_chef_server
{
	#shell array declaration
	servers=( 'chef-server-webui' 'chef-server (api)' 'chef-expander' 'chef/solr' 'rabbitmq' 'couchdb' )
	#array size: ${#servers[@]}
	#array all elements: "${servers[@]}"
	#array element at index i: "${servers[$i]}"
	for index in $(seq 0 $(expr "${#servers[@]}" \- 1))
	do
		process=$(ps auxx|grep -v grep|grep  "${servers[$index]}")
		if [[ -z $process ]];then
			echo "${servers[$index]} is not running"
			exit 1
		fi
	done

	echo "creating $USER chef dir ~/.chef" >&2
	mkdir -p ~/.chef
	if [[ $? != 0 ]];then
		echo "failed to create chef dir" >&2
		exit 1
	fi

	echo "copying authentication files to chef dir: ~/.chef" >&2
	sudo cp /etc/chef/validation.pem /etc/chef/webui.pem ~/.chef
	if [[ $? != 0 ]];then
		echo "failed to copy authentication files to chef dir" >&2
		exit 1
	fi
	echo "changing chef validation files user" >&2
	sudo chown -R $USER ~/.chef
	if [[ $? != 0 ]];then
		echo "failed to change chef validation files user" >&2
		exit 1
	fi
	
	echo "going to run knife interactive configuration command" >&2
	echo "for configuration help pease visit: http://wiki.opscode.com/display/chef/Installing+Chef+Server+on+Debian+or+Ubuntu+using+Packages" >&2
	echo "Please enter the location of the existing admin client's private key: [/etc/chef/webui.pem] .chef/webui.pem" >&2
	echo "Please enter the location of the validation key: [/etc/chef/validation.pem] .chef/validation.pem" >&2
	knife configure -i
	if [[ $? == 0 ]];then
		echo "server knife configuration done." >&2
	else
		echo "server knife configuration failed." >&2
	fi
}

function usage
{
	echo "$0 install_chef_server"
	echo "$0 configure_knife_on_chef_server"
}

if [[ $1 == "install_chef_server" ]];then
	add_opscode_apt_repo
	add_apt_trusted_gpg_key
	install_chef_server
elif [[ $1 == "configure_knife_on_chef_server" ]];then
	configure_knife_on_chef_server
else
	usage
fi
