#!/usr/bin/env bash

# Runs the tests against the working tree that is mounted in /srv.
# The optional argument is a regular expression that selects test files.
install -m 755 /srv/src/bash/bin/crucible /usr/local/bin/crucible
status=0
while IFS= read -r f; do
  echo "=== $f"
  timeout 300 bash "$f" || {
    echo "FAILED: $f"
    status=1
  }
done < <(find /srv/test/bash -type f | sort | grep -E "${1:-.}")
exit "$status"
