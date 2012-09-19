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
	#run this chef server
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
	sudo knife configure -i
	if [[ $? == 0 ]];then
		echo "server knife configuration done." >&2
		echo "YOU CAN RUN KNIFE COMMAND TO CHECK IF CONFIGURED: knife client list" >&2
	else
		echo "server knife configuration failed." >&2
	fi
}

function configure_knife_client_on_mylaptop
{
	chef_server=$1
	user_name=$2
	echo "creating chef client on server" >&2
	ssh $chef_server knife client $user_name -d -a -f /tmp/$user_name.pem
	if [[ $? != 0 ]];then
		echo "failed to create client:$user_name on chef server" >&2
		exit 1
	else
		echo "client created:$user_name on chef server, the private key is stored in file $chef_server:/tmp/$user_name.pem" >&2
		echo "testing client:" >&2
		ssh $chef_server knife client show $user_name
	fi

	echo "creating chef dir ~/.chef" >&2
	mkdir -p ~/.chef
	if [[ $? != 0 ]];then
		echo "failed to create chef dir" >&2
		exit 1
	fi

	echo "copying the key just created on server" >&2
	scp $chef_server:/tmp/$user_name.pem ~/.chef/$user_name.pem
	if [[ $? != 0 ]];then
		echo "failed to copy client key from server" >&2
		exit 1
	fi

	echo "installing chef-client, ruby gem" >&2
	gem install chef --no-ri --no-rdoc
	if [[ $? != 0 ]];then
		echo "failed to install ruby gem: chef-client" >&2
		exit 1
	fi

	echo "When prompting for chef-server url, please enter the chef server URL: [http://localhost:4000] http://chef-server.example.com:4000" >&2
	echo "When prompting for uername or client name please specify the username just created or any existing user" >&2
	
	knife configure
	if [[ $? == 0 ]];then
		echo "chef-client configuration done." >&2
		echo "YOU CAN RUN KNIFE COMMAND TO CHECK IF CONFIGURED: knife client list" >&2
	else
		echo "chef-client configuration failed." >&2
	fi
}

function configure_node_knife_client
{
	echo "assuming ruby/rubygem/ is installed with their dependicies, else please visit:http://wiki.opscode.com/display/chef/Installing+Chef+Client+on+Ubuntu+or+Debian"
	chef_server=$1
	echo "installing chef-client, ruby gem" >&2
	gem install chef --no-ri --no-rdoc
	if [[ $? != 0 ]];then
		echo "failed to install ruby gem: chef-client" >&2
		exit 1
	fi

	echo "creating chef dir :/etc/chef" >&2
	sudo mkdir -p /etc/chef
	if [[ $? != 0 ]];then
		echo "failed to create chef dir" >&2
		exit 1
	fi

	echo "creating client.rb and validation.pem on chef-server" >&2
	ssh $chef_server knife configure client /tmp
	if [[ $? != 0 ]];then
		echo "failed to create client.rb and validation.pem" >&2
		exit 1
	fi

	echo "copying client.rb and validation.pem from chef-server" >&2
	sudo scp $chef_server:/tmp/client.rb /etc/chef && sudo scp $chef_server:/tmp/validation.pem /etc/chef
	if [[ $? != 0 ]];then
		echo "failed to copying client.rb and validation.pem from chef-server" >&2
		exit 1
	else
		echo "node chef-client configured." >&2
	fi 
}

function usage
{
	echo "$0 install_chef_server"
	echo "$0 configure_knife_on_chef_server"
	echo "$0 configure_knife_client_on_mylaptop <chef_server_address> <new_chef_user_name>"
	echo "$0 configure_node_knife_client <local_chef_client_address|chef_server_address>"
}

if [[ $1 == "install_chef_server" ]];then
	add_opscode_apt_repo
	add_apt_trusted_gpg_key
	install_chef_server
elif [[ $1 == "configure_knife_on_chef_server" ]];then
	configure_knife_on_chef_server
elif [[ $# == 4 ]] && [[ $1 == "configure_knife_client_on_mylaptop" ]];then
	#use this if yourlaptop itself is not the server.
	#When working with chef, you will spend a lot of time editing recipes and other files, and you'll find it much more convenient to edit them on your laptop/desktop (your management workstation), where you have your editor configured just to your liking. To facilitate this mode of working, we recommend you create a knife client to use knife on your development machine.
	#Make sure you've configured knife on your chef server before proceeding with this step.
	configure_knife_client_on_mylaptop $2 $3
elif [[ $# == 3 ]] && [[ $1 == "configure_node_knife_client" ]];then
	#configure nodes that will be managed by chef
	configure_node_knife_client $2
else
	usage
fi
