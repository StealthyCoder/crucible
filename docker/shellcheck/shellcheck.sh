#!/usr/bin/env bash

# Checks every script, also in subdirectories, and fails when any has a finding
shopt -s globstar dotglob
status=0
for f in /srv/crucible/bash/**/* /srv/crucible-test/bash/**/* /srv/crucible-test/.utils /srv/.sh/*.sh; do
  [ -f "$f" ] || continue
  shellcheck -x -s bash --severity=warning "$f" || status=1
done
exit "$status"
