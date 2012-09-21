#!/bin/bash

function install_vagrant_and_download_box
{
	echo "installing vagrant gem" >&2
	gem install vagrant
	if [[ $? != 0 ]];then
		echo "failed to install vagrant gem" >&2
		exit 1
	fi

	echo "downloading vagrant box...." >&2
	vagrant box add lucid32 http://files.vagrantup.com/lucid32.box
	if [[ $? != 0 ]];then
		echo "downloading failed" >&2
		exit 1
	else
		echo "vagrant box download complete."
	fi
}

function project_setup
{
	project_dir=$1
	if [[ ! -d $project_dir ]];then
		mkdir -p $project_dir
	fi

	if [[ $? != 0 ]];then
		echo "could not create project dir:$project_dir" >&2
		exit 1
	fi

	cd $project_dir && vagrant init
	if [[ $? != 0 ]];then
		echo "project set up failed" >&2
		exit 1
	else
		echo "project initialized." >&2
		echo "project dir has a conf file: Vagrantfile, make sure to specify the right base box name: config.vm.box=<base_box_name>" >&2
		echo "if you have downloaded the VM using install_vagrant_and_download_box, then box name is lucid32" >&2
		echo "you can also modify this configuration file to forward port, use chef, please visit:http://vagrantup.com/" >&2
		echo "you can log in to virtual machine using command: cd $project_dir && vagrant up" >&2
	fi
}

function usage
{
	echo "$0 install_vagrant_and_download_box" >&2
	echo "$0 project_setup <project_dir>" >&2
}

if [[ $1 == "install_vagrant_and_download_box" ]];then
	install_vagrant_and_download_box
elif [[ $# == 3 ]] && [[ $1 == "project_setup" ]];then
	project_setup $2
else
	usage
fi
