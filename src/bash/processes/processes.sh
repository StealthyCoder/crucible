#!/usr/bin/env bash
### CRUCIBLE META DATA ###
# CRUCIBLE_VERSION=0.3.0
# CRUCIBLE_AUTHOR=StealthyCoder
# CRUCIBLE_CREATED=1791901074
### CRUCIBLE META DATA ###

require core/.internal
require logging/logging

# Everything in here is bash itself: builtins like kill, wait and read, and
# /proc for what the shell cannot tell. The functions that look at other
# processes need /proc and therefore Linux.

function processes._verify_pid {
	if ! [[ "$1" =~ ^[0-9]+$ ]]; then
		logging.error "Not a process id: $1"
		return 1
	fi
}

function processes._verify_proc {
	if [ ! -r /proc/self/stat ]; then
		logging.error "This needs /proc, which this system does not have"
		return 1
	fi
}

# Prints the process name, the state and the parent of a process, separated by
# spaces and in that order. The name can contain spaces and brackets itself,
# which is why the fields are taken from the last bracket on.
function processes._stat {
	local line name rest state ppid
	processes._verify_proc || return 1
	[ -r "/proc/$1/stat" ] || return 1
	read -r line <"/proc/$1/stat" || return 1
	name="${line#*(}"
	name="${name%)*}"
	rest="${line##*) }"
	read -r state ppid _ <<<"$rest"
	printf '%s %s %s\n' "$state" "$ppid" "$name"
}

# Sleeps without starting a sleep process: read waits for input that never
# arrives on a pipe that this shell keeps open itself, until the timeout.
function processes.sleep {
	__verify_nr_args "$#" 1 processes.sleep
	if ! [[ "$1" =~ ^[0-9]+(\.[0-9]+)?$ ]]; then
		logging.error "Not a number of seconds: $1"
		return 1
	fi
	IFS= read -rt "$1" <> <(:)
	return 0
}

function processes.current {
	echo "$$"
}

function processes.current_subshell {
	echo "$BASHPID"
}

# Starts a command in the background. Its process id is in CRUCIBLE_LAST_PID
# and not on stdout: a process started inside $(...) does not belong to this
# shell, so processes.wait could not wait for it.
function processes.spawn {
	if [ "$#" -lt 1 ]; then
		logging.error "processes.spawn: usage is processes.spawn <COMMAND> [ARGUMENTS]"
		return 1
	fi
	"$@" &
	export CRUCIBLE_LAST_PID=$!
}

# A process that has ended but was not waited for yet is a zombie, that is not running
function processes.is_running {
	__verify_nr_args "$#" 1 processes.is_running
	local state
	processes._verify_pid "$1" || return 1
	kill -0 "$1" 2>/dev/null || return 1
	if [ -r "/proc/$1/stat" ]; then
		state="$(processes.state "$1")"
		[ "$state" != "Z" ]
	fi
}

# Waits for a child of this shell and returns its exit status
function processes.wait {
	__verify_nr_args "$#" 1 processes.wait
	processes._verify_pid "$1" || return 1
	wait "$1"
}

# Waits until a process has ended, it does not have to be a child of this
# shell. Fails when it is still running after the timeout, which is 30
# seconds when it is not given.
function processes.wait_for {
	if [ "$#" -lt 1 ] || [ "$#" -gt 2 ]; then
		logging.error "processes.wait_for: usage is processes.wait_for <PID> [TIMEOUT]"
		return 1
	fi
	local polls
	processes._verify_pid "$1" || return 1
	polls=$((${2:-30} * 20))
	while processes.is_running "$1"; do
		if [ "$polls" -le 0 ]; then
			return 1
		fi
		polls=$((polls - 1))
		processes.sleep 0.05
	done
}

function processes.signal {
	if [ "$#" -lt 1 ] || [ "$#" -gt 2 ]; then
		logging.error "processes.signal: usage is processes.signal <PID> [SIGNAL]"
		return 1
	fi
	processes._verify_pid "$1" || return 1
	if ! [[ "${2:-TERM}" =~ ^([A-Z0-9]+|[0-9]+)$ ]]; then
		logging.error "Not a signal: $2"
		return 1
	fi
	kill -s "${2:-TERM}" "$1"
}

# Asks a process to stop and kills it when it has not after the grace period,
# which is 5 seconds when it is not given.
function processes.terminate {
	if [ "$#" -lt 1 ] || [ "$#" -gt 2 ]; then
		logging.error "processes.terminate: usage is processes.terminate <PID> [GRACE]"
		return 1
	fi
	processes._verify_pid "$1" || return 1
	processes.is_running "$1" || return 0
	kill -s TERM "$1" 2>/dev/null
	if ! processes.wait_for "$1" "${2:-5}"; then
		logging.warning "Process $1 ignored TERM, sending KILL"
		kill -s KILL "$1" 2>/dev/null
		processes.wait_for "$1" 5
	fi
}

# Runs a command and stops it when it takes longer than the seconds given: it
# is asked to stop with TERM and killed when it is still there after
# CRUCIBLE_PROCESSES_KILL_AFTER seconds, 5 unless set.
# The status is that of the command, or 124 when it had to be stopped.
#
# The watcher says "fired" in a pipe before it signals the command, so when the
# command is gone the answer to "was it stopped" is already there. Looking at
# whether the watcher is still alive instead is a race: it can be on its way out.
# Usage: processes.run_with_timeout <seconds> <command> [argument]...
function processes.run_with_timeout {
	if [ "$#" -lt 2 ]; then
		logging.error "processes.run_with_timeout: usage is processes.run_with_timeout <SECONDS> <COMMAND> [ARGUMENT]..."
		return 1
	fi
	local seconds pid watcher status fired_fd timed_out
	seconds="$1"
	shift
	"$@" &
	pid=$!
	exec {fired_fd}< <(
		processes.sleep "$seconds"
		echo fired
		kill -s TERM "$pid" 2>/dev/null
		processes.sleep "${CRUCIBLE_PROCESSES_KILL_AFTER:-5}"
		kill -s KILL "$pid" 2>/dev/null
	)
	watcher=$!
	wait "$pid"
	status=$?
	timed_out=1
	# read -t 0 only asks whether something can be read
	if IFS= read -r -t 0 -u "$fired_fd"; then
		timed_out=0
	fi
	kill -s KILL "$watcher" 2>/dev/null
	wait "$watcher" 2>/dev/null
	exec {fired_fd}<&-
	if [ "$timed_out" -eq 0 ]; then
		return 124
	fi
	return "$status"
}

# Prints the state of a process: R running, S sleeping, D waiting for the disk,
# T stopped, Z zombie
function processes.state {
	__verify_nr_args "$#" 1 processes.state
	local stat
	processes._verify_pid "$1" || return 1
	stat="$(processes._stat "$1")" || return 1
	echo "${stat%% *}"
}

function processes.parent {
	__verify_nr_args "$#" 1 processes.parent
	local stat
	processes._verify_pid "$1" || return 1
	stat="$(processes._stat "$1")" || return 1
	stat="${stat#* }"
	echo "${stat%% *}"
}

function processes.name {
	__verify_nr_args "$#" 1 processes.name
	local stat
	processes._verify_pid "$1" || return 1
	stat="$(processes._stat "$1")" || return 1
	stat="${stat#* }"
	echo "${stat#* }"
}

# Prints the command line of a process, with a space between the words
function processes.command_line {
	__verify_nr_args "$#" 1 processes.command_line
	local -a words
	processes._verify_pid "$1" || return 1
	processes._verify_proc || return 1
	[ -r "/proc/$1/cmdline" ] || return 1
	mapfile -d '' -t words <"/proc/$1/cmdline"
	echo "${words[*]}"
}

# Prints a line with the id, the parent, the state and the name of every process
function processes.list {
	local dir stat state ppid name
	processes._verify_proc || return 1
	for dir in /proc/[0-9]*; do
		stat="$(processes._stat "${dir#/proc/}")" || continue
		state="${stat%% *}"
		ppid="${stat#* }"
		name="${ppid#* }"
		ppid="${ppid%% *}"
		echo "${dir#/proc/} $ppid $state $name"
	done
}

# Prints the ids of the processes that have exactly this name
function processes.find_by_name {
	__verify_nr_args "$#" 1 processes.find_by_name
	local pid ppid state name
	while read -r pid ppid state name; do
		if [ "$name" = "$1" ]; then
			echo "$pid"
		fi
	done < <(processes.list)
}

# Prints the ids of the processes of which the command line contains the text
function processes.find_by_command {
	__verify_nr_args "$#" 1 processes.find_by_command
	local pid ppid state name
	while read -r pid ppid state name; do
		if [[ "$(processes.command_line "$pid" 2>/dev/null)" == *"$1"* ]]; then
			echo "$pid"
		fi
	done < <(processes.list)
}

# Prints the ids of the processes that were started by this process
function processes.children {
	__verify_nr_args "$#" 1 processes.children
	local pid ppid state name
	processes._verify_pid "$1" || return 1
	while read -r pid ppid state name; do
		if [ "$ppid" = "$1" ]; then
			echo "$pid"
		fi
	done < <(processes.list)
}
