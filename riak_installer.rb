 #!/bin/bash

download_dir="$HOME/riak"

if [[ ! -d $download_dir ]]; then
	mkdir -p $download_dir
fi

function install_erlang
{
	sudo apt-get install build-essential libncurses5-dev openssl libssl-dev
	wget http://erlang.org/download/otp_src_R14B03.tar.gz
	tar zxvf otp_src_R14B03.tar.gz
	rsync -avz otp_src_R14B03 $download_dir
	(cd $download_dir/otp_src_R14B03 && ./configure && make && sudo make install)
}

#http://wiki.basho.com/Building-a-Development-Environment.html
function install_riak
{
	sudo apt-get install build-essential libc6-dev-i386
	wget "http://downloads.basho.com/riak/CURRENT/riak-1.1.2.tar.gz"
	tar zxvf "riak-1.1.2.tar.gz"
	rsync -avz "riak-1.1.2" $download_dir
	(cd "$download_dir/riak-1.1.2" && make rel)
	(cd "$download_dir/riak-1.1.2" && make all)
	(cd "$download_dir/riak-1.1.2" && make devrel)
}

function start_riak_and_create_cluster
{
	#starting nodes
	for node in dev1 dev2 dev3 dev4
	do
		(cd "$download_dir/riak-1.1.2/dev" && $node/bin/riak start)
	done

	#making cluster
	for node in dev2 dev3 dev4
	do
		(cd "$download_dir/riak-1.1.2/dev" && $node/bin/riak-admin join "dev1@127.0.0.1")
	done
}

function usage
{
	echo "$0 install_erlang" >&2
	echo "$0 install_riak" >&2
	echo "$0 start_riak_and_create_cluster" >&2
}

if [[ $1 == "install_erlang" ]]; then
	install_erlang
elif [[ $1 == "install_riak" ]]; then
	install_riak
elif [[ $1 == "start_riak_and_create_cluster" ]]; then
	start_riak_and_create_cluster
else
	usage
fi

