#!/usr/bin/env bash
# shellcheck disable=SC1090
source "$(dirname "$0")/../../.utils"
mkdir tmp/io/dirs -p
cd tmp/io/dirs || fail "Could not change dir"
setup
# shellcheck disable=SC1091
source .mould

require io/files/dirs

declare -a tests

tests=("io.dirs.create_dir" "io.dirs.create_dir_local" "io.dirs.dir_exists")
tests+=("io.dirs.rename_dir" "io.dirs.move_dir")
tests+=("io.dirs.copy_dir")
tests+=("io.dirs.delete_dir" "io.dirs.delete_dir_and_files")
tests+=("io.dirs.perms" "io.dirs.perms_recursive")
tests+=("io.dirs.invalid_perms")
tests+=("io.dirs.copy_perms" "io.dirs.copy_perms_recursive")
tests+=("io.dirs.owner")
# The safe variants replace the functions above, so they have to come last
tests+=("io.dirs.safe.rename_dir" "io.dirs.safe.copy_dir")
tests+=("io.dirs.safe.delete_dir" "io.dirs.safe.delete_dir_and_files")

function mode_of {
    stat -c '%a' "$1"
}

function io.dirs.create_dir {
    intro "io.dirs.create_dir"
    dirs.create_dir nested/dir "$PWD"
    test -d "$PWD/nested/dir" || fail "Directory was not created"
    rm -r nested
    success
}

function io.dirs.create_dir_local {
    intro "io.dirs.create_dir_local"
    dirs.create_dir_local local/dir
    test -d local/dir || fail "Directory was not created"
    rm -r local
    success
}

function io.dirs.dir_exists {
    intro "io.dirs.dir_exists"
    mkdir exists
    assert_true "Existing directory was not found" dirs.dir_exists exists
    assert_false "Missing directory was found" dirs.dir_exists missing
    touch file.txt
    assert_false "A file was reported as directory" dirs.dir_exists file.txt
    rm -r exists file.txt
    success
}

function io.dirs.rename_dir {
    intro "io.dirs.rename_dir"
    mkdir old
    touch old/leaf.txt
    dirs.rename_dir old new
    test ! -e old || fail "Old directory still exists"
    test -f new/leaf.txt || fail "Renamed directory lost its content"
    rm -r new
    success
}

function io.dirs.move_dir {
    intro "io.dirs.move_dir"
    mkdir -p source target
    touch source/leaf.txt
    dirs.move_dir source target/moved
    test ! -e source || fail "Source directory still exists"
    test -f target/moved/leaf.txt || fail "Moved directory lost its content"
    rm -r target
    success
}

function io.dirs.copy_dir {
    intro "io.dirs.copy_dir"
    mkdir -p source/sub
    touch source/sub/leaf.txt
    dirs.copy_dir source copy
    test -f copy/sub/leaf.txt || fail "Copy misses nested file"
    test -f source/sub/leaf.txt || fail "Source disappeared"
    rm -r source copy
    success
}

function io.dirs.delete_dir {
    intro "io.dirs.delete_dir"
    mkdir empty full
    touch full/leaf.txt
    dirs.delete_dir empty
    test ! -e empty || fail "Empty directory was not deleted"
    dirs.delete_dir full 2>/dev/null
    test -e full/leaf.txt || fail "Directory with content was deleted"
    rm -r full
    success
}

function io.dirs.delete_dir_and_files {
    intro "io.dirs.delete_dir_and_files"
    mkdir -p tree/sub
    touch tree/sub/leaf.txt
    dirs.delete_dir_and_files tree
    test ! -e tree || fail "Directory tree was not deleted"
    success
}

function io.dirs.perms {
    intro "io.dirs.dir_set_perms and friends"
    mkdir permdir
    dirs.dir_set_perms permdir "u=rwx,go=rx"
    assert_equals "755" "$(mode_of permdir)" "dir_set_perms"
    dirs.dir_set_all_read_only_clear permdir
    assert_equals "444" "$(mode_of permdir)" "dir_set_all_read_only_clear"
    dirs.dir_set_all_write_only_clear permdir
    assert_equals "222" "$(mode_of permdir)" "dir_set_all_write_only_clear"
    dirs.dir_set_all_execute_only_clear permdir
    assert_equals "111" "$(mode_of permdir)" "dir_set_all_execute_only_clear"
    chmod 000 permdir
    dirs.dir_set_all_read_only permdir
    assert_equals "444" "$(mode_of permdir)" "dir_set_all_read_only"
    dirs.dir_set_all_write_only permdir
    assert_equals "666" "$(mode_of permdir)" "dir_set_all_write_only"
    dirs.dir_set_all_execute_only permdir
    assert_equals "777" "$(mode_of permdir)" "dir_set_all_execute_only"
    rm -r permdir
    success
}

function io.dirs.perms_recursive {
    intro "io.dirs.dir_set_perms_recursive and friends"
    mkdir -p permdir/sub
    dirs.dir_set_perms_recursive permdir "u=rwx,go=rx"
    assert_equals "755" "$(mode_of permdir)" "top directory"
    assert_equals "755" "$(mode_of permdir/sub)" "nested directory"
    dirs.dir_set_all_execute_only_clear_recursive permdir
    assert_equals "111" "$(mode_of permdir/sub)" "dir_set_all_execute_only_clear_recursive"
    dirs.dir_set_all_read_only_recursive permdir
    assert_equals "555" "$(mode_of permdir/sub)" "dir_set_all_read_only_recursive"
    dirs.dir_set_all_write_only_recursive permdir
    assert_equals "777" "$(mode_of permdir/sub)" "dir_set_all_write_only_recursive"
    rm -r permdir
    success
}

function io.dirs.invalid_perms {
    intro "io.dirs.dir_set_perms with invalid perms"
    mkdir permdir
    chmod 700 permdir
    dirs.dir_set_perms permdir "not a perm" >/dev/null
    assert_equals "700" "$(mode_of permdir)" "Invalid perms changed the directory mode"
    rm -r permdir
    success
}

function io.dirs.copy_perms {
    intro "io.dirs.dir_copy_perms"
    mkdir reference target
    chmod 750 reference
    chmod 700 target
    dirs.dir_copy_perms target reference
    assert_equals "750" "$(mode_of target)" "Perms were not copied"
    rm -r reference target
    success
}

function io.dirs.copy_perms_recursive {
    intro "io.dirs.dir_copy_perms_recursive"
    mkdir -p reference target/sub
    chmod 750 reference
    chmod 700 target target/sub
    dirs.dir_copy_perms_recursive target reference
    assert_equals "750" "$(mode_of target)" "Top directory perms were not copied"
    assert_equals "750" "$(mode_of target/sub)" "Nested directory perms were not copied"
    rm -r reference target
    success
}

function io.dirs.owner {
    intro "io.dirs.dir_change_owner*"
    if ! __is_root; then
        echo "Skipped, changing owners needs root"
        success
        return
    fi
    mkdir -p owned/sub reference
    dirs.dir_change_owner_group owned root root
    assert_equals "root:root" "$(stat -c '%U:%G' owned)" "dir_change_owner_group"
    dirs.dir_change_owner_group_recursive owned root root
    assert_equals "root:root" "$(stat -c '%U:%G' owned/sub)" "dir_change_owner_group_recursive"
    dirs.dir_change_owner owned root
    dirs.dir_change_owner_recursive owned root
    dirs.dir_copy_owner owned reference
    dirs.dir_copy_owner_recursive owned reference
    assert_equals "root:root" "$(stat -c '%U:%G' owned/sub)" "dir_copy_owner_recursive"
    rm -r owned reference
    success
}

function io.dirs.safe.rename_dir {
    intro "io.dirs.safe.rename_dir"
    require io/files/dirs/safe
    mkdir one two
    touch one/leaf.txt
    dirs.rename_dir one two
    test -f one/leaf.txt || fail "Directory was renamed onto an existing target"
    dirs.rename_dir missing other
    test ! -e other || fail "Missing source created a target"
    rm -r one two
    success
}

function io.dirs.safe.copy_dir {
    intro "io.dirs.safe.copy_dir"
    mkdir -p one
    echo "original" >one/leaf.txt
    dirs.copy_dir one copy
    assert_equals "original" "$(cat copy/leaf.txt)" "Directory was not copied"
    echo "changed" >one/leaf.txt
    dirs.copy_dir one copy
    assert_equals "original" "$(cat copy/leaf.txt)" "Existing file in the copy was overwritten"
    rm -r one copy
    success
}

function io.dirs.safe.delete_dir {
    intro "io.dirs.safe.delete_dir"
    mkdir empty spared
    yes | dirs.delete_dir empty >/dev/null 2>&1
    test ! -e empty || fail "Directory was not deleted after confirmation"
    yes n | dirs.delete_dir spared >/dev/null 2>&1
    test -e spared || fail "Directory was deleted without confirmation"
    rm -r spared
    success
}

function io.dirs.safe.delete_dir_and_files {
    intro "io.dirs.safe.delete_dir_and_files"
    mkdir tree
    yes | dirs.delete_dir_and_files tree >/dev/null 2>&1
    test ! -e tree || fail "Directory was not deleted after confirmation"
    success
}

echo "Testing io/files/dirs"

for test in "${tests[@]}"; do
    "$test"
done

teardown
