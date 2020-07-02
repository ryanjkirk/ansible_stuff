#!/bin/bash
# output CPU and MEM % free stats on a row at a specified interval
# optional parameters: $1 output interval (otherwise runs just one)
# author: ryk

IFS=$'\n\t'

interval=$1

function pctmemfree {
    totmem=`free -m | head -2 | tail -1 | awk '{print $2}'`
    freemem=`free -m | head -3 | tail -1 | awk '{print $4}'`
#   pctfree=`echo "scale=2; $freemem / $totmem * 100" | bc`
    pctfree=$(( 100 * freemem / totmem ))
    printf "mem ${pctfree}%% free    "
}

function pctcpuidle {
#   idlecpu=`top -b -n 1 | head -3 | tail -1 | awk '{print $5}' | sed 's/%id,//'`
    idlecpu=`mpstat | tail -1 | awk '{print $12}' | cut -f 1 -d '.'`
    printf "cpu ${idlecpu}%% idle\n"
}

while true; do
    printf "`date` :    "
    pctmemfree
    pctcpuidle
    if [[ -n $interval ]]; then
        sleep $interval
      else
        break
    fi
done
