#!/bin/bash
# count number of CPUs and cores

numcpus=`grep "physical id" /proc/cpuinfo | sort -u | wc -l`
numcorespercpu=`grep "cpu cores" /proc/cpuinfo | head -1 | awk '{print $4}'`
numcores=$(( numcpus * numcorespercpu ))
numthreads=`grep "^processor" /proc/cpuinfo | wc -l`
cpumodel=`grep "^model name" /proc/cpuinfo | head -1 | cut -f 2 -d ':' | tr -s " " | sed "s/^ //"`

if [[ $numthreads == $numcores ]]; then
    echo "$numcpus $cpumodel CPUs with $numcorespercpu cores each => $numcores total cores, no HyperThreading"
  else
    echo "$numcpus $cpumodel CPUs with $numcorespercpu cores each => $numcores total cores, HyperThreaded to $numthreads"
fi
