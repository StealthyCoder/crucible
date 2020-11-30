#!/usr/bin/env bash
cd $GITHUB_WORKSPACE
for f in $(ls $1/**/*)
do
  if [ -f $f ]; 
  then 
    bash $f
  fi
done

