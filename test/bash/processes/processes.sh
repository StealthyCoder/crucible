#!/usr/bin/env bash
# shellcheck disable=SC1090
source "$(dirname "$0")/../../.utils"
mkdir tmp/processes/processes -p
cd tmp/processes/processes || fail "Could not change dir"
setup
# shellcheck disable=SC1091
source .mould

require processes/processes

declare -a tests

tests=("processes.processes.sleep" "processes.processes.current")
tests+=("processes.processes.spawn_and_is_running")
tests+=("processes.processes.finished_is_not_running")
tests+=("processes.processes.wait" "processes.processes.wait_for")
tests+=("processes.processes.signal" "processes.processes.terminate")
tests+=("processes.processes.terminate_stubborn")
tests+=("processes.processes.inspect")
tests+=("processes.processes.list_and_find")
tests+=("processes.processes.run_with_timeout")
tests+=("processes.processes.invalid_arguments")

function processes.processes.sleep {
    intro "processes.sleep waits without a sleep process"
    local start elapsed
    start=$SECONDS
    processes.sleep 1
    elapsed=$((SECONDS - start))
    test "$elapsed" -ge 1 -a "$elapsed" -le 2 || fail "Slept $elapsed seconds instead of 1"
    start=$SECONDS
    processes.sleep 0.2
    test $((SECONDS - start)) -le 1 || fail "A fraction of a second took too long"
    success
}

function processes.processes.current {
    intro "processes.current and current_subshell"
    assert_equals "$$" "$(processes.current)" "current is the pid of the script"
    test "$(processes.current_subshell)" != "$$" || fail "A subshell has its own pid"
    success
}

function processes.processes.spawn_and_is_running {
    intro "processes.spawn and is_running"
    processes.spawn sleep 30
    [[ "$CRUCIBLE_LAST_PID" =~ ^[0-9]+$ ]] || fail "No pid in CRUCIBLE_LAST_PID: $CRUCIBLE_LAST_PID"
    assert_true "Spawned process should be running" processes.is_running "$CRUCIBLE_LAST_PID"
    kill "$CRUCIBLE_LAST_PID"
    wait "$CRUCIBLE_LAST_PID" 2>/dev/null
    assert_false "Killed process should not be running" processes.is_running "$CRUCIBLE_LAST_PID"
    assert_false "A pid that does not exist is not running" processes.is_running 4194000
    success
}

function processes.processes.finished_is_not_running {
    intro "a finished process that nobody waited for is not running"
    local zombie
    # bash waits for its own children, so the parent has to be something that does not:
    # sleep takes over the shell and never waits for the short lived process it inherited
    processes.spawn bash -c 'sleep 0.1 & echo $! >zombie.pid; exec sleep 30'
    processes.sleep 0.5
    zombie="$(cat zombie.pid)"
    # kill -0 still succeeds for the zombie, is_running must not
    kill -0 "$zombie" 2>/dev/null || fail "Test is wrong, the zombie is gone already"
    assert_equals "Z" "$(processes.state "$zombie")" "state of the zombie"
    assert_false "A zombie is not running" processes.is_running "$zombie"
    kill "$CRUCIBLE_LAST_PID"
    wait "$CRUCIBLE_LAST_PID" 2>/dev/null
    success
}

function processes.processes.wait {
    intro "processes.wait returns the exit status"
    processes.spawn bash -c 'exit 7'
    processes.wait "$CRUCIBLE_LAST_PID"
    assert_equals "7" "$?" "exit status"
    success
}

function processes.processes.wait_for {
    intro "processes.wait_for"
    local start
    processes.spawn sleep 1
    start=$SECONDS
    assert_true "Should have seen it end" processes.wait_for "$CRUCIBLE_LAST_PID" 10
    test $((SECONDS - start)) -le 3 || fail "Waited much longer than the process ran"
    wait "$CRUCIBLE_LAST_PID"
    processes.spawn sleep 30
    start=$SECONDS
    assert_false "Should have timed out" processes.wait_for "$CRUCIBLE_LAST_PID" 1
    test $((SECONDS - start)) -le 3 || fail "Timeout took too long"
    kill "$CRUCIBLE_LAST_PID"
    wait "$CRUCIBLE_LAST_PID" 2>/dev/null
    success
}

function processes.processes.signal {
    intro "processes.signal"
    processes.spawn sleep 30
    processes.signal "$CRUCIBLE_LAST_PID" STOP
    processes.sleep 0.3
    assert_equals "T" "$(processes.state "$CRUCIBLE_LAST_PID")" "stopped process"
    processes.signal "$CRUCIBLE_LAST_PID" CONT
    processes.sleep 0.3
    assert_equals "S" "$(processes.state "$CRUCIBLE_LAST_PID")" "continued process"
    processes.signal "$CRUCIBLE_LAST_PID"
    wait "$CRUCIBLE_LAST_PID" 2>/dev/null
    assert_equals "143" "$?" "default signal is TERM"
    success
}

function processes.processes.terminate {
    intro "processes.terminate"
    processes.spawn sleep 30
    processes.terminate "$CRUCIBLE_LAST_PID" 5
    wait "$CRUCIBLE_LAST_PID" 2>/dev/null
    assert_false "Terminated process should be gone" processes.is_running "$CRUCIBLE_LAST_PID"
    assert_true "Terminating what is gone is fine" processes.terminate "$CRUCIBLE_LAST_PID"
    success
}

function processes.processes.terminate_stubborn {
    intro "processes.terminate kills a process that ignores TERM"
    local start
    processes.spawn bash -c 'trap "" TERM; while :; do read -t 1 <> <(:); done'
    processes.sleep 0.5
    start=$SECONDS
    processes.terminate "$CRUCIBLE_LAST_PID" 1 >/dev/null
    wait "$CRUCIBLE_LAST_PID" 2>/dev/null
    assert_equals "137" "$?" "killed with KILL"
    test $((SECONDS - start)) -le 4 || fail "Terminate took too long"
    success
}

function processes.processes.inspect {
    intro "processes.name, parent, state and command_line"
    processes.spawn sleep 30
    assert_equals "sleep" "$(processes.name "$CRUCIBLE_LAST_PID")" "name"
    assert_equals "$$" "$(processes.parent "$CRUCIBLE_LAST_PID")" "parent"
    assert_equals "S" "$(processes.state "$CRUCIBLE_LAST_PID")" "state"
    assert_equals "sleep 30" "$(processes.command_line "$CRUCIBLE_LAST_PID")" "command line"
    assert_equals "bash" "$(processes.name $$)" "name of this shell"
    kill "$CRUCIBLE_LAST_PID"
    wait "$CRUCIBLE_LAST_PID" 2>/dev/null
    assert_false "A process that is gone has no name" processes.name "$CRUCIBLE_LAST_PID"
    success
}

function processes.processes.list_and_find {
    intro "processes.list, find_by_name, find_by_command and children"
    local sleeper
    processes.spawn sleep 31
    sleeper="$CRUCIBLE_LAST_PID"
    processes.list | grep -q "^$sleeper $$ S sleep$" || fail "list misses the sleeper"
    processes.list | grep -q "^$$ " || fail "list misses this shell"
    assert_equals "$sleeper" "$(processes.find_by_name sleep)" "find_by_name"
    assert_equals "" "$(processes.find_by_name no-such-process-name)" "find_by_name without match"
    assert_equals "$sleeper" "$(processes.find_by_command "sleep 31")" "find_by_command"
    processes.children $$ | grep -qx "$sleeper" || fail "children misses the sleeper"
    kill "$sleeper"
    wait "$sleeper" 2>/dev/null
    success
}

function processes.processes.run_with_timeout {
    intro "processes.run_with_timeout"
    local start
    processes.run_with_timeout 5 true
    assert_equals "0" "$?" "status of a command that succeeds"
    processes.run_with_timeout 5 bash -c 'exit 7'
    assert_equals "7" "$?" "status of a command that fails"
    start=$SECONDS
    processes.run_with_timeout 1 sleep 30
    assert_equals "124" "$?" "status of a command that takes too long"
    test $((SECONDS - start)) -le 3 || fail "The command was not stopped in time"
    processes.run_with_timeout 5 true
    test -z "$(jobs -p)" || fail "The timer was left running"
    success
}

function processes.processes.invalid_arguments {
    intro "invalid arguments"
    assert_false "pid must be a number" processes.is_running "abc" >/dev/null
    assert_false "pid must be a number" processes.signal "1; rm" TERM >/dev/null
    assert_false "signal must be a signal" processes.signal $$ "TERM; echo" >/dev/null
    assert_false "sleep needs a number" processes.sleep "soon" >/dev/null
    assert_false "spawn needs a command" processes.spawn >/dev/null
    success
}

echo "Testing processes/processes"

for test in "${tests[@]}"; do
    "$test"
done

teardown
