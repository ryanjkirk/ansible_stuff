#!/bin/bash
# author: ryk
# show free mem in % from sar

#/ Usage: Either with no parameters, or optionally specifiy the date
#/ Description: calculates and displays percent free memory
#/ Examples: ./mempctfree_sar.sh 13
#/ Options:
#/   --help: Display this help message

function usage {
    grep '^#/' "$0" | cut -c4-
    exit 0
}
expr "$*" : ".*--help" > /dev/null && usage

# strict mode
IFS=$'\n\t'
#set -euo pipefail

date=$1

# option to show stats for a particular day
if [[ -n $1 ]]; then
    function sarcmd {
        sar -r -f /var/log/sa/sa"${date}"
    }
  else
    function sarcmd {
        sar -r
    }
fi

for entry in `sarcmd | egrep -v "Average|kbmemfree|Linux|2017|x86_64|CPU"`; do
     time=`echo $entry | awk '{print $1, $2}'`
     free=`echo $entry | awk '{print $3}'`
     buffers=`echo $entry | awk '{print $6}'`
     cache=`echo $entry | awk '{print $7}'`
     totfree="`expr $free + $buffers + $cache`"
     totmem=`free -k | head -2 | tail -1 | awk '{print $2}'`
     pctfree=$(( 100 * totfree / totmem ))
     totmemgb=$(( totmem / 1024 / 1024 ))
     totfreegb=$(( totfree / 1024 / 1024 ))
     echo "$time $pctfree % free  ($totfreegb GB out of $totmemgb GB)"
done
