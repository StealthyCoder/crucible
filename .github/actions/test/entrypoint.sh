#!/usr/bin/env bash
export PATH=$PATH:$PWD/src/$1/bin/crucible
env | sort

for f in $(ls test/$1/**/*)
do
  if [ -f $f ]; 
  then 
    $1 $f
  fi
done

