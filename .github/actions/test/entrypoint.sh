#!/usr/bin/env bash
export PATH=$PATH:$PWD/src/$1/bin
env | sort

# Runs every test, also in subdirectories, and fails when any of them fails
status=0
while IFS= read -r f; do
  echo "=== $f"
  timeout 300 "$1" "$f" || {
    echo "FAILED: $f"
    status=1
  }
done < <(find "test/$1" -type f | sort)
exit "$status"
