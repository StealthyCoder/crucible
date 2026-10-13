#!/usr/bin/env bash
# shellcheck disable=SC1090
source "$(dirname "$0")/../../.utils"
SRC="$(cd "$(dirname "$0")/../../../src/bash/io/files" && pwd)"
mkdir tmp/io/permissions -p
cd tmp/io/permissions || fail "Could not change dir"
setup
# shellcheck disable=SC1091
source .mould

declare -a tests

tests=("io.permissions.name_matches_perms" "io.permissions.class_matches_file")
tests+=("io.permissions.add_and_remove_are_complete")
tests+=("io.permissions.behaviour")

# The variants are generated from their name: <verb>_<classes>_<perms>_only[_clear]
# These helpers derive what chmod string a name promises, independent of the source.

function sorted {
    echo "$1" | grep -o . | sort | tr -d '\n'
}

function normalise {
    # u=rw,og-x -> sorted classes, operator, sorted perms per clause
    local clause out
    out=""
    for clause in ${1//,/ }; do
        [[ "$clause" =~ ^([ugo]+)([-+=])([rwx]+)$ ]] || {
            echo "UNPARSEABLE:$1"
            return
        }
        out+="$(sorted "${BASH_REMATCH[1]}")${BASH_REMATCH[2]}$(sorted "${BASH_REMATCH[3]}"),"
    done
    echo "${out%,}"
}

function expected_perms {
    local name clear tokens token verb op classes perms complement letter
    name="$1"
    clear=""
    case "$name" in
    *_clear)
        clear=1
        name="${name%_clear}"
        ;;
    esac
    name="${name%_only}"
    IFS=_ read -ra tokens <<<"$name"
    verb="${tokens[0]}"
    classes=""
    perms=""
    for token in "${tokens[@]:1}"; do
        case "$token" in
        user) classes+=u ;;
        group) classes+=g ;;
        other) classes+=o ;;
        read) perms+=r ;;
        write) perms+=w ;;
        execute) perms+=x ;;
        *)
            echo "UNPARSEABLE:$token"
            return
            ;;
        esac
    done
    case "$verb" in
    add) op="+" ;;
    remove) op="-" ;;
    set) op="=" ;;
    *)
        echo "UNPARSEABLE:$verb"
        return
        ;;
    esac
    if [ -n "$clear" ]; then
        complement=""
        for letter in u g o; do
            [[ "$classes" == *"$letter"* ]] || complement+="$letter"
        done
        normalise "$classes$op$perms,$complement-rwx"
    else
        normalise "$classes$op$perms"
    fi
}

function variants {
    # prints: <file kind>|<class>|<name without prefix>|<chmod string>|<chmod function>
    local kind class file prefix
    for kind in files dirs; do
        for class in user group other; do
            if [ "$kind" = "files" ]; then
                file="$SRC/${class/user/users}.sh"
                prefix="files.file_"
            else
                file="$SRC/dirs/$class.sh"
                prefix="dirs.dir_"
            fi
            awk -v kind="$kind" -v class="$class" -v prefix="$prefix" '
                /^function / { name = $2; sub("^" prefix, "", name) }
                $1 ~ /(file|dir)_set_perms/ { gsub(/"/, "", $3); print kind "|" class "|" name "|" $3 "|" $1 }
            ' "$file"
        done
    done
}

function io.permissions.name_matches_perms {
    intro "io.permissions: every function promises the chmod string its name says"
    local kind class name perms setter wrong count recursive
    wrong=""
    count=0
    while IFS='|' read -r kind class name perms setter; do
        count=$((count + 1))
        recursive=""
        case "$name" in
        *_recursive)
            recursive=1
            name="${name%_recursive}"
            ;;
        esac
        if [ "$(normalise "$perms")" != "$(expected_perms "$name")" ]; then
            wrong+="$kind/$class $name uses [$perms] "
        fi
        if [ "$kind" = "dirs" ]; then
            if [ -n "$recursive" ] && [[ "$setter" != *_recursive ]]; then
                wrong+="$kind/$class $name is not recursive "
            elif [ -z "$recursive" ] && [[ "$setter" == *_recursive ]]; then
                wrong+="$kind/$class $name is recursive "
            fi
        fi
    done < <(variants)
    test "$count" -gt 100 || fail "Only parsed $count variants, the parser is broken"
    test -z "$wrong" || fail "Mismatching variants: $wrong"
    success
}

function io.permissions.class_matches_file {
    intro "io.permissions: every function belongs to the file of a class it names"
    local kind class name wrong
    wrong=""
    while IFS='|' read -r kind class name _ _; do
        [[ "$name" == *"_${class}_"* || "$name" == *"_${class}" ]] || wrong+="$kind/$class defines $name "
    done < <(variants)
    test -z "$wrong" || fail "Functions in the wrong file: $wrong"
    success
}

function io.permissions.add_and_remove_are_complete {
    intro "io.permissions: add and remove exist for every permission combination"
    local kind class verb combo missing defined
    missing=""
    for kind in files dirs; do
        for class in user group other; do
            defined="$(variants | awk -F'|' -v kind="$kind" -v class="$class" '$1 == kind && $2 == class { print $3 }')"
            for verb in add remove; do
                for combo in read write execute read_write read_execute write_execute read_write_execute; do
                    for suffix in "" _recursive; do
                        [ "$kind" = "files" ] && [ -n "$suffix" ] && continue
                        echo "$defined" | grep -qx "${verb}_${class}_${combo}_only${suffix}" || missing+="$kind/$class ${verb}_${class}_${combo}_only${suffix} "
                    done
                done
            done
        done
    done
    test -z "$missing" || fail "Missing variants: $missing"
    success
}

function io.permissions.behaviour {
    intro "io.permissions: a few variants really change the mode"
    require io/files/users
    require io/files/group
    require io/files/other
    touch variant.txt
    chmod 000 variant.txt
    files.file_add_user_read_write_only variant.txt
    test "$(stat -c '%a' variant.txt)" = "600" || fail "file_add_user_read_write_only"
    files.file_add_group_read_only variant.txt
    test "$(stat -c '%a' variant.txt)" = "640" || fail "file_add_group_read_only"
    files.file_add_other_write_execute_only variant.txt
    test "$(stat -c '%a' variant.txt)" = "643" || fail "file_add_other_write_execute_only"
    files.file_remove_user_read_only variant.txt
    test "$(stat -c '%a' variant.txt)" = "243" || fail "file_remove_user_read_only"
    files.file_set_user_read_only_clear variant.txt
    test "$(stat -c '%a' variant.txt)" = "400" || fail "file_set_user_read_only_clear"
    rm -f variant.txt
    success
}

echo "Testing io/files permission variants"

for test in "${tests[@]}"; do
    "$test"
done

teardown
