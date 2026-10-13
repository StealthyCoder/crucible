#!/usr/bin/env bash
# shellcheck disable=SC1090
source "$(dirname "$0")/../../.utils"
mkdir tmp/search/search -p
cd tmp/search/search || fail "Could not change dir"
setup
# shellcheck disable=SC1091
source .mould

require search/search

declare -a tests

tests=("search.search.fixtures")
tests+=("search.search.find_files_by_filename")
tests+=("search.search.find_files_by_filename_ignore_case")
tests+=("search.search.find_files_by_extension")
tests+=("search.search.find_files_by_extension_ignore_case")
tests+=("search.search.find_files_containing")
tests+=("search.search.find_files_containing_ignore_case")
tests+=("search.search.find_files_containing_in_binaries")
tests+=("search.search.nothing_found")
tests+=("search.search.missing_location")
tests+=("search.search.does_not_load_files_module")

function search.search.fixtures {
    intro "Creating a tree to search through"
    mkdir -p tree/sub/deep "tree/with space"
    echo "alpha needle" >tree/a.txt
    echo "Beta NEEDLE" >tree/notes.TXT
    echo "gamma" >tree/sub/b.log
    echo "needle deep" >tree/sub/deep/c.txt
    echo "nothing here" >tree/other.md
    echo "needle spaced" >"tree/with space/s.txt"
    mkdir -p txt-directory
    echo "needle in a directory named like a file" >txt-directory/readme
    success
}

function search.search.find_files_by_filename {
    intro "search.find_files_by_filename"
    assert_equals "tree/a.txt
tree/sub/deep/c.txt
tree/with space/s.txt" "$(search.find_files_by_filename tree txt | sort)" "Case sensitive filename search"
    assert_equals "tree/sub/b.log" "$(search.find_files_by_filename tree b.log | sort)" "Single filename"
    assert_equals "" "$(search.find_files_by_filename txt-directory txt | sort)" "Only the filename counts, not the directories above it"
    success
}

function search.search.find_files_by_filename_ignore_case {
    intro "search.find_files_by_filename_ignore_case"
    assert_equals "tree/a.txt
tree/notes.TXT
tree/sub/deep/c.txt
tree/with space/s.txt" "$(search.find_files_by_filename_ignore_case tree txt | sort)" "Case insensitive filename search"
    assert_equals "" "$(search.find_files_by_filename_ignore_case tree xyz | sort)" "No match must not match everything"
    success
}

function search.search.find_files_by_extension {
    intro "search.find_files_by_extension"
    assert_equals "tree/a.txt
tree/sub/deep/c.txt
tree/with space/s.txt" "$(search.find_files_by_extension tree .txt | sort)" "Case sensitive extension search"
    assert_equals "tree/sub/b.log" "$(search.find_files_by_extension tree log | sort)" "Extension without dot"
    success
}

function search.search.find_files_by_extension_ignore_case {
    intro "search.find_files_by_extension_ignore_case"
    assert_equals "tree/a.txt
tree/notes.TXT
tree/sub/deep/c.txt
tree/with space/s.txt" "$(search.find_files_by_extension_ignore_case tree .txt | sort)" "Case insensitive extension search"
    success
}

function search.search.find_files_containing {
    intro "search.find_files_containing"
    assert_equals "tree/a.txt
tree/sub/deep/c.txt
tree/with space/s.txt" "$(search.find_files_containing tree needle | sort)" "Case sensitive content search"
    success
}

function search.search.find_files_containing_ignore_case {
    intro "search.find_files_containing_ignore_case"
    assert_equals "tree/a.txt
tree/notes.TXT
tree/sub/deep/c.txt
tree/with space/s.txt" "$(search.find_files_containing_ignore_case tree needle | sort)" "Case insensitive content search"
    success
}

function search.search.find_files_containing_in_binaries {
    intro "search.find_files_containing in binaries"
    local token
    mkdir bin
    cp "$(command -v ls)" bin/program
    token="$(strings -d bin/program | awk 'length > 8 { print; exit }')"
    test -n "$token" || fail "Could not find a string inside the binary to look for"
    assert_equals "bin/program" "$(search.find_files_containing bin "$token" | sort)" "Search in a binary"
    rm -r bin
    success
}

function search.search.nothing_found {
    intro "search with nothing to find"
    assert_equals "" "$(search.find_files_containing tree "this is nowhere" | sort)" "Content search"
    assert_equals "" "$(search.find_files_by_extension tree .nope | sort)" "Extension search"
    success
}

function search.search.missing_location {
    intro "search in a location that does not exist"
    local output status
    output="$(search.find_files_by_filename does-not-exist txt)"
    status=$?
    test "$status" -ne 0 || fail "A missing location should fail"
    test -n "$output" || fail "A missing location should be reported"
    success
}

function search.search.does_not_load_files_module {
    intro "requiring search does not load the safe files module"
    # The safe files module makes deleting interactive, a side effect nobody asked for
    if declare -F files.delete_file >/dev/null; then
        fail "search must not pull in the files module"
    fi
    success
}

echo "Testing search/search"

for test in "${tests[@]}"; do
    "$test"
done

teardown
