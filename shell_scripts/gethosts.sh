#!/bin/bash
# generate inventory file
# author: ryk

# TODO: convert to getopts and add usage(), and add option for the following:
# ./gethosts.sh Prod ans | grep ny5pweb | xargs | sed 's/ /,/g'`
env=$1
ansible=$2

baseurl="https://ny5pvinv01.cheetahmail.com/assetdb/default/hosts?_export_type=csv_with_hidden_cols"
filter_online="hosts.build_complete+%3D+%22Y%22"
filter_active="hosts.retired+%3D+%22N%22"
stdurl="${baseurl}&keywords=${filter_online}+and+${filter_active}"
envurl="${baseurl}&keywords=${filter_online}+and+${filter_active}+and+hosts.environment+%3D+%22${env}%22"

# toggle between all hosts or a specific env
if [[ -z $env ]] || [[ $env == all ]]; then
    url="$stdurl"
  else
    url="$envurl"
fi

# db table column key
#  1 host_name
#  2 domain_name
#  9 conn_name
#  6 environment
#  3 os
#  4 os_version
#  5 hardware_type
#  7 platform
# 19 patch_baseline
# 20 owner_email
# 21 notes

function getallhosts {
curl -ks "$url" \
    | awk -F, '{print $1, $2, $9, $6, $3, $4, $5, $7}' \
    | egrep -v "os_version" \
    | sed -e 's/ /./' -e 's/ N//' \
    | sed -e 's/ <NULL>$//' -e 's/ Prod$//' -e 's/ / ansible_host=/' \
    | sed -e 's/ansible_host=<NULL>/NA/' -e 's/ansible_host= /NA /'  \
    | sed -e 's/\.cheetahmail.com//g' \
    | awk '{printf "%-29s %-29s %-8s %-12s %-2s %-8s %-10s %-10s %-7s\n", $1, $2, $3, $4, $5, $6, $7, $8, $9}' \
    | sort
}

function ansible_list {
    getallhosts | awk '{printf "%-29s %-26s\n", $1, $2}' | sed 's/NA//'
}

if [[ -n $ansible ]]; then
    ansible_list
  else
    getallhosts
fi
