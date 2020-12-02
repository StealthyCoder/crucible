#!/usr/bin/env bash

shopt -s dotglob
for f in $(ls src/$1/**/*)
do
  if [ -f $f ]; 
  then 
    shellcheck $f -x -s $1; 
  fi
done

for f in $(ls test/$1/**/*)
do
  if [ -f $f ]; 
  then 
    shellcheck $f -x -s $1; 
  fi
done

shellcheck test/.utils -s $1

shellcheck .sh/*.sh -s $1

