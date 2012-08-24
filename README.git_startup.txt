git config --global user.name "Santosh Kumar"
git config --global user.email "sk21886-mygit@yahoo.co.in"

$mkdir ~/santosh_bin_shell
$cd ~/santosh_bin_shell
[santosh_bin_shell]$git init
[santosh_bin_shell]$git remote add origin https://github.com/san21886/shell

now open file ~/santosh_bin_shell/.git/config
and put below configs int the file:

[branch "master"]
        remote = origin
        merge = refs/heads/master

[santosh_bin_shell]$vim README.txt
[santosh_bin_shell]$git add README.txt
[santosh_bin_shell]$git commit -m "readme added"
[santosh_bin_shell]$git pull #only for first time
[santosh_bin_shell]$git push 

