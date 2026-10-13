#!/usr/bin/env bash
# shellcheck disable=SC1090
source "$(dirname "$0")/../../.utils"
mkdir tmp/io/files -p
cd tmp/io/files || fail "Could not change dir"
setup
# shellcheck disable=SC1091
source .mould

require io/files/files

declare -a tests

tests=("io.files.create_file" "io.files.file_exists")
tests+=("io.files.rename_file" "io.files.move_file")
tests+=("io.files.copy_file" "io.files.update_file")
tests+=("io.files.delete_file")
tests+=("io.files.list")
tests+=("io.files.change_dir")
tests+=("io.files.delete_dir_and_files")
tests+=("io.files.perms" "io.files.invalid_perms")
tests+=("io.files.copy_perms")
tests+=("io.files.owner")
# The safe variants replace the functions above, so they have to come last
tests+=("io.files.safe.create_file" "io.files.safe.rename_file")
tests+=("io.files.safe.copy_file" "io.files.safe.delete_file")
tests+=("io.files.safe.delete_dir_and_files")

function mode_of {
    stat -c '%a' "$1"
}

function io.files.create_file {
    intro "io.files.create_file"
    files.create_file created.txt
    test -f created.txt || fail "File was not created"
    rm created.txt
    success
}

function io.files.file_exists {
    intro "io.files.file_exists"
    touch exists.txt
    assert_true "Existing file was not found" files.file_exists exists.txt
    assert_false "Missing file was found" files.file_exists missing.txt
    rm exists.txt
    success
}

function io.files.rename_file {
    intro "io.files.rename_file"
    echo "content" >old.txt
    files.rename_file old.txt new.txt
    test ! -e old.txt || fail "Old file still exists"
    assert_equals "content" "$(cat new.txt)" "Renamed file lost its content"
    rm new.txt
    success
}

function io.files.move_file {
    intro "io.files.move_file"
    mkdir target
    echo "content" >moving.txt
    files.move_file moving.txt target/moved.txt
    test ! -e moving.txt || fail "Source file still exists"
    assert_equals "content" "$(cat target/moved.txt)" "Moved file lost its content"
    rm -r target
    success
}

function io.files.copy_file {
    intro "io.files.copy_file"
    echo "content" >src.txt
    files.copy_file src.txt copy.txt
    assert_equals "content" "$(cat copy.txt)" "Copy has wrong content"
    test -f src.txt || fail "Source file disappeared"
    rm src.txt copy.txt
    success
}

function io.files.update_file {
    intro "io.files.update_file"
    echo "old" >target.txt
    echo "new" >src.txt
    touch -d '2 days ago' target.txt
    files.update_file src.txt target.txt
    assert_equals "new" "$(cat target.txt)" "Older target was not updated"
    echo "newer target" >target.txt
    touch -d '2 days ago' src.txt
    files.update_file src.txt target.txt
    assert_equals "newer target" "$(cat target.txt)" "Newer target was overwritten"
    rm src.txt target.txt
    success
}

function io.files.delete_file {
    intro "io.files.delete_file"
    touch doomed.txt
    files.delete_file doomed.txt
    test ! -e doomed.txt || fail "File was not deleted"
    success
}

function io.files.list {
    intro "io.files.list_*"
    mkdir -p listing/sub
    touch listing/visible.txt listing/.hidden listing/sub/deep.txt
    assert_equals "sub visible.txt" "$(files.list_dir listing | tr '\n' ' ' | sed 's/ $//')" "list_dir"
    files.list_dir_hidden listing | grep -q '^.hidden$' || fail "list_dir_hidden misses hidden file"
    files.list_dir_recursive listing | grep -q '^deep.txt$' || fail "list_dir_recursive misses nested file"
    files.list_dir_detailed listing | grep -q 'visible.txt' || fail "list_dir_detailed misses file"
    files.change_dir listing
    files.list_current_dir | grep -q '^visible.txt$' || fail "list_current_dir misses file"
    files.list_current_dir_hidden | grep -q '^.hidden$' || fail "list_current_dir_hidden misses hidden file"
    files.list_current_dir_recursive | grep -q '^deep.txt$' || fail "list_current_dir_recursive misses nested file"
    files.list_current_dir_detailed | grep -q 'visible.txt' || fail "list_current_dir_detailed misses file"
    files.change_dir_unwind
    rm -r listing
    success
}

function io.files.change_dir {
    intro "io.files.change_dir"
    local start
    start="$PWD"
    mkdir -p one/two
    files.change_dir one
    assert_equals "$start/one" "$PWD" "Did not change into one"
    files.change_dir two
    assert_equals "$start/one/two" "$PWD" "Did not change into two"
    files.change_dir_history | grep -q "$start/one" || fail "History misses visited directory"
    files.change_dir_unwind
    assert_equals "$start/one" "$PWD" "Did not unwind to one"
    files.change_dir_unwind
    assert_equals "$start" "$PWD" "Did not unwind to start"
    files.change_dir_history_clear
    rm -r one
    success
}

function io.files.delete_dir_and_files {
    intro "io.files.delete_dir_and_files"
    mkdir -p tree/sub
    touch tree/sub/leaf.txt
    files.delete_dir_and_files tree
    test ! -e tree || fail "Directory tree was not deleted"
    success
}

function io.files.perms {
    intro "io.files.file_set_perms and friends"
    touch perms.txt
    files.file_set_perms perms.txt "u=rw,go=r"
    assert_equals "644" "$(mode_of perms.txt)" "file_set_perms"
    files.file_set_all_read_only_clear perms.txt
    assert_equals "444" "$(mode_of perms.txt)" "file_set_all_read_only_clear"
    files.file_set_all_write_only_clear perms.txt
    assert_equals "222" "$(mode_of perms.txt)" "file_set_all_write_only_clear"
    files.file_set_all_execute_only_clear perms.txt
    assert_equals "111" "$(mode_of perms.txt)" "file_set_all_execute_only_clear"
    chmod 000 perms.txt
    files.file_set_all_read_only perms.txt
    assert_equals "444" "$(mode_of perms.txt)" "file_set_all_read_only"
    files.file_set_all_write_only perms.txt
    assert_equals "666" "$(mode_of perms.txt)" "file_set_all_write_only"
    files.file_set_all_execute_only perms.txt
    assert_equals "777" "$(mode_of perms.txt)" "file_set_all_execute_only"
    rm perms.txt
    success
}

function io.files.invalid_perms {
    intro "io.files.file_set_perms with invalid perms"
    touch perms.txt
    chmod 600 perms.txt
    files.file_set_perms perms.txt "not a perm" >/dev/null
    assert_equals "600" "$(mode_of perms.txt)" "Invalid perms changed the file mode"
    rm perms.txt
    success
}

function io.files.copy_perms {
    intro "io.files.file_copy_perms"
    touch reference.txt target.txt
    chmod 640 reference.txt
    chmod 600 target.txt
    files.file_copy_perms target.txt reference.txt
    assert_equals "640" "$(mode_of target.txt)" "Perms were not copied"
    rm reference.txt target.txt
    success
}

function io.files.owner {
    intro "io.files.file_change_owner*"
    if ! __is_root; then
        echo "Skipped, changing owners needs root"
        success
        return
    fi
    touch owned.txt reference.txt
    files.file_change_owner_group owned.txt root root
    assert_equals "root:root" "$(stat -c '%U:%G' owned.txt)" "file_change_owner_group"
    files.file_change_owner owned.txt root
    assert_equals "root:root" "$(stat -c '%U:%G' owned.txt)" "file_change_owner"
    files.file_copy_owner owned.txt reference.txt
    assert_equals "root:root" "$(stat -c '%U:%G' owned.txt)" "file_copy_owner"
    rm owned.txt reference.txt
    success
}

function io.files.safe.create_file {
    intro "io.files.safe.create_file"
    require io/files/safe
    echo "precious" >exists.txt
    files.create_file exists.txt
    assert_equals "precious" "$(cat exists.txt)" "Existing file was touched"
    files.create_file fresh.txt
    test -f fresh.txt || fail "File was not created"
    rm exists.txt fresh.txt
    success
}

function io.files.safe.rename_file {
    intro "io.files.safe.rename_file"
    echo "one" >one.txt
    echo "two" >two.txt
    files.rename_file one.txt two.txt
    assert_equals "two" "$(cat two.txt)" "Existing target was overwritten"
    files.rename_file missing.txt other.txt
    test ! -e other.txt || fail "Missing source created a target"
    rm one.txt two.txt
    success
}

function io.files.safe.copy_file {
    intro "io.files.safe.copy_file"
    echo "one" >one.txt
    echo "two" >two.txt
    files.copy_file one.txt two.txt
    assert_equals "two" "$(cat two.txt)" "Existing target was overwritten"
    files.copy_file one.txt three.txt
    assert_equals "one" "$(cat three.txt)" "Copy has wrong content"
    rm one.txt two.txt three.txt
    success
}

function io.files.safe.delete_file {
    intro "io.files.safe.delete_file"
    touch doomed.txt
    yes | files.delete_file doomed.txt >/dev/null 2>&1
    test ! -e doomed.txt || fail "File was not deleted after confirmation"
    touch spared.txt
    yes n | files.delete_file spared.txt >/dev/null 2>&1
    test -e spared.txt || fail "File was deleted without confirmation"
    rm spared.txt
    success
}

function io.files.safe.delete_dir_and_files {
    intro "io.files.safe.delete_dir_and_files"
    mkdir -p tree
    touch tree/leaf.txt
    yes n | files.delete_dir_and_files tree >/dev/null 2>&1
    test -e tree/leaf.txt || fail "Directory was deleted without confirmation"
    yes | files.delete_dir_and_files tree >/dev/null 2>&1
    test ! -e tree || fail "Directory was not deleted after confirmation"
    success
}

echo "Testing io/files/files"

for test in "${tests[@]}"; do
    "$test"
done

teardown
