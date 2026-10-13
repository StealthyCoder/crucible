#!/usr/bin/env bash
# shellcheck disable=SC1090
source "$(dirname "$0")/../../.utils"
REPO="$(cd "$(dirname "$0")/../../.." && pwd)"
mkdir tmp/sh/build -p
cd tmp/sh/build || fail "Could not change dir"
setup
# shellcheck disable=SC1091
source .mould

declare -a tests

tests=("sh.build.refuses_another_version" "sh.build.stamps_every_file")

# build.sh changes the files it sits next to, so it works on a copy. The copy
# gets its placeholders back, so that this also works in a tree that was built
# for a release and has none.
function copy_repo {
    mkdir -p copy
    cp -r "$REPO/src" "$REPO/.sh" copy/
    find copy/src -type f -exec sed -i -E \
        -e 's/^# CRUCIBLE_VERSION=.*$/# CRUCIBLE_VERSION={CRUCIBLE_VERSION}/' \
        -e 's/^# CRUCIBLE_CREATED=.*$/# CRUCIBLE_CREATED={CRUCIBLE_CREATED}/' {} +
}

function sh.build.refuses_another_version {
    intro "build.sh refuses a version that bin/crucible does not have"
    local before
    copy_repo
    before="$(grep -rl '{CRUCIBLE_VERSION}' copy/src | wc -l)"
    ( cd copy && echo "9.9.9" | bash .sh/build.sh >/dev/null 2>&1 )
    test $? -ne 0 || fail "A version that differs from bin/crucible should stop the build"
    assert_equals "$before" "$(grep -rl '{CRUCIBLE_VERSION}' copy/src | wc -l)" "nothing is stamped when the build is refused"
    rm -r copy
    success
}

function sh.build.stamps_every_file {
    intro "build.sh stamps every file, also in directories deep down"
    local version files left
    copy_repo
    version="$(grep '^CRUCIBLE_VERSION=' copy/src/bash/bin/crucible | cut -d'=' -f2)"
    files="$(find copy/src -type f | wc -l)"
    test "$(grep -rl '{CRUCIBLE_VERSION}' copy/src | wc -l)" -gt 20 || fail "Expected a source tree full of placeholders"
    ( cd copy && echo "$version" | bash .sh/build.sh >build.log 2>&1 ) || fail "build.sh failed: $(cat copy/build.log)"
    test ! -s copy/build.log || fail "build.sh printed errors: $(head -3 copy/build.log)"
    left="$(grep -rlE '\{CRUCIBLE_(VERSION|CREATED)\}' copy/src | tr '\n' ' ')"
    test -z "$left" || fail "Placeholders left in: $left"
    assert_equals "# CRUCIBLE_VERSION=$version" "$(sed -n 3p copy/src/bash/crypto/hash/sha/safe/sha256.sh)" "a file five directories down"
    [[ "$(sed -n 5p copy/src/bash/io/files/dirs/safe/user.sh)" =~ ^#\ CRUCIBLE_CREATED=[0-9]+$ ]] || fail "The creation time of a deep file is not a number"
    assert_equals "CRUCIBLE_LOCATION=v$version" "$(grep '^CRUCIBLE_LOCATION=' copy/src/bash/bin/crucible)" "location of the release"
    assert_equals "$files" "$(find copy/src -type f | wc -l)" "no file was added or lost"
    rm -r copy
    success
}

echo "Testing .sh/build.sh"

for test in "${tests[@]}"; do
    "$test"
done

teardown
