#!/bin/bash
#
#Runs a test 20 times 


if [ "$#" -eq "0" ] ; then
  echo "usage: $0 <test_name> "
  exit
fi

TEST=$1

# clean first
#mvn clean

for i in `seq 1 20`; do echo "##### SEQ $i ##### "; mvn test -Dtest=$TEST || break ; done
