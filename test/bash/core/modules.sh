#!/usr/bin/env bash
# shellcheck disable=SC1090
source "$(dirname "$0")/../../.utils"
SRC="$(cd "$(dirname "$0")/../../../src/bash" && pwd)"
mkdir tmp/core/modules -p
cd tmp/core/modules || fail "Could not change dir"
setup
# shellcheck disable=SC1091
source .mould

declare -a tests

tests=("modules.requires_resolve" "modules.load_all" "modules.download_failure_is_fatal")

function modules.requires_resolve {
    intro "Checking that every require points at an existing module"
    local file module missing
    missing=""
    while IFS= read -r line; do
        file="${line%%:*}"
        module="$(echo "${line#*:}" | cut -d' ' -f2)"
        test -f "$SRC/${module%.sh}.sh" || missing+="$module (required in ${file#"$SRC"/}) "
    done < <(grep -rn '^require ' "$SRC" | sed -E 's/^([^:]+):[0-9]+:/\1:/')
    test -z "$missing" || fail "Unresolvable requires: $missing"
    success
}

function modules.load_all {
    intro "Checking that every module can be required"
    local file module
    while IFS= read -r file; do
        module="${file#"$SRC"/}"
        module="${module%.sh}"
        require "$module"
    done < <(find "$SRC" -name '*.sh' -not -path "$SRC/bin/*" -not -path "$SRC/core/mould.sh" | sort)
    success
}

function modules.download_failure_is_fatal {
    intro "Checking that requiring a missing module fails loudly"
    local output status
    output="$( (require does/not/exist) 2>&1)"
    status=$?
    test "$status" -ne 0 || fail "Requiring a missing module did not fail"
    test -n "$output" || fail "Requiring a missing module printed nothing"
    test ! -s "$(grep 'shared_dir' .crucible | cut -d'=' -f2)/does/not/exist" || fail "A broken module file was left behind"
    success
}

echo "Testing core/modules"

for test in "${tests[@]}"; do
    "$test"
done

teardown
