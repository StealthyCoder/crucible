#!/usr/bin/env bash
cd $GITHUB_WORKSPACE

export PATH=$PATH:$GITHUB_WORKSPACE/src/$1/bin/crucible

for f in $(ls test/$1/**/*)
do
  if [ -f $f ]; 
  then 
    $1 $f
  fi
done

