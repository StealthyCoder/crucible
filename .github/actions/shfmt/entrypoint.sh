#!/usr/bin/env bash
export PATH=$PATH:$PWD/src/$1/bin

shopt -s globstar dotglob

shfmt -d src/$1/**