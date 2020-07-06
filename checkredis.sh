#!/bin/bash

# author: ryk

#/ Usage: on local redis server, run:
#/   checkredis.sh <warn_threshold> <critical_threshold>
#/ Description: monitor redis availability and memory usage, to be called
#/   by NRPE or some other monitoring tool
#/ Arguments: $1 - the WARNING percentage of allowable memory usage
#/            $2 - the CRITICAL percentage of allowable memory usage
#/ Assumptions: this is a redis cluster and the monitoring user has
#/   sudo privileges to run this command.
#/ Examples: ./checkredis.sh 85 95
#/ Options:
#/   --help: Display this help message

function usage {
    grep '^#/' "$0" | cut -c4-
    exit 0
}
expr "$*" : ".*--help" > /dev/null && usage

if [[ -z "$1"  || -z "$2" ]]; then
  echo "This script must be run with paramaters. Run with --help for more information."
  exit 99
fi

pctmemusage_warn="$1"
pctmemusage_crit="$2"

# modify this if you are not running a cluster or don't have redis-cli locked down to root
rediscli="sudo redis-cli -c"

function checkredis {
    frc="$1"
    fdesc="$2"
    foutput="$3"
    fexpected="$4"

        if [[ ! $frc == 0 ]] || [[ ! $foutput == "$fexpected" ]]; then
            echo "CRITICAL - $fdesc failed, please escalate to Systems/DevOps"
            exit 2
        fi
}

# first check redis's built-in ping
desc="Redis ping"
output="`$rediscli ping`"
expected="PONG"
rc=$?

checkredis "$rc" "$desc" "$output" "$expected"

# set a key
desc="Setting a redis key"
output="`$rediscli set monitoringtestkey 'testkeydata'`"
expected="OK"
rc=$?

checkredis "$rc" "$desc" "$output" "$expected"

# get the key
desc="Getting the redis key"
output="`$rediscli get monitoringtestkey`"
expected="success"
rc=$?

# delete the key
desc="Deleting the redis key"
output="`$rediscli del monitoringtestkey`"
expected="1"
rc=$?

checkredis "$rc" "$desc" "$output" "$expected"

# define memory statistics
read -r used_memory_rss maxmemory <<<`$rediscli info memory | egrep "used_memory_rss:|maxmemory:" | cut -f 2 -d ':'`
mempctusage=`echo "scale=2; 100 * $used_memory_rss / $maxmemory" | tr -d $'\r' | bc`
mempctusageint="`echo $mempctusage | cut -f 1 -d '.'`"

# check mem usage against thresholds
if [[ "$mempctusageint" -gt "$pctmemusage_crit" ]]; then
    echo "CRITICAL - Redis is using ${mempctusage}% of its available memory, critical threshold is set to ${pctmemusage_crit}%."
    exit 1
  elif [[ "$mempctusageint" -gt "$pctmemusage_warn" ]]; then
    echo "WARNING - Redis is using ${mempctusage}% of its available memory, warn threshold is set to ${pctmemusage_warn}%."
    exit 1
fi

# if we got this far, nothing failed; give the all-clear
echo "OK - Redis is healthy and is using ${mempctusage}% of its available memory"
exit 0
