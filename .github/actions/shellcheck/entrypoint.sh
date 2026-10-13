#!/usr/bin/env bash

# Checks every script, also in subdirectories, and fails when any has a finding
shopt -s globstar dotglob
status=0
for f in src/"$1"/**/* test/"$1"/**/* test/.utils .sh/*.sh; do
  [ -f "$f" ] || continue
  shellcheck -x -s "$1" --severity=warning "$f" || status=1
done
exit "$status"
