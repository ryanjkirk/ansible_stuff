#!/bin/bash
# echos the commands to reset the root passwords upon proper connection validation

group=$1
red=`tput setaf 1`
green=`tput setaf 2`
yellow=`tput setaf 3`
magenta=`tput setaf 5`
nocolor=`tput setaf 7`

if [[ -z $group ]]; then
    cat << EOF 

 ***** PRE-task (a) *****
 ----- Generate host lists and create backdoor user on all hosts
 ----- Copy below lines and enter the ${magenta}OLD (current)${nocolor} root password:
$green ./geninvfiles.sh
 ansible-playbook -i ./el6 manage_root_pw.yml -u root -k -e "hosts=all backdoor_state=present" $nocolor

 ***** PRE-task (b) *****
 ----- Insert groups into the inventory file in order to change passwords in batches
$green # [do this manually] $nocolor

 ***** Complete password reset steps, one batch at a time *****
 ----- Supply a group name that corresponds to your inventory file for the per-batch commands. Example:
$green $0 group1 $nocolor
 ----- ${yellow}Fix all errors as you go, after each command. $nocolor
$green $0 group2 $nocolor
       ...etc

 ***** POST-task (a) *****
 ----- Remove backdoor user on all hosts
 ----- enter the ${magenta}NEW${nocolor} root password:
$green ansible-playbook -i ./el6 manage_root_pw.yml -u root -k -e "hosts=all backdoor_state=absent" $nocolor

EOF

elif [[ -n $group ]]; then
    cat << EOF 

 %%%%% For each batch, perform the following steps %%%%%

 ***** Step 1 *****
 ----- Run the following command to validate backdoor root access
 ----- type in the ${magenta}backdoor password${nocolor}:
$green ansible-playbook -i ./el6 ping.yml --private-key="~/.tmp" -u backdoor -b -e "hosts=${group}" $nocolor

 ***** Step 2 *****
 ----- ${yellow}Fix all errors on the previous run before running the next command! $nocolor
 ----- Once all hosts can connect as backdoor, run the following to ${red}reset the root password${nocolor}:
 ----- type in the ${magenta}backdoor password${nocolor}:
$green ansible-playbook -i ./el6 manage_root_pw.yml -u backdoor -k -b -e "hosts=${group} backdoor_state=present setrootpw=true" $nocolor

 ***** Step 3 *****
 ----- Run the following and validate all hosts are accessible via the new root password:
 ----- type in the ${magenta}NEW root${nocolor} password:
$green ansible-playbook -i ./el6 ping.yml -k -u root -e "hosts=${group}" $nocolor
 
EOF
fi
