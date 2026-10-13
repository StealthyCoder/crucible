![.github/workflows/integrity.yml](https://github.com/StealthyCoder/crucible/workflows/.github/workflows/integrity.yml/badge.svg?branch=develop)

# crucible
A shell script framework. This framework exists to help make it easier to create shell script packages with reusable code and modules that are curated and safe. These reusable modules will be _installed_ into a shared location per project similar to how [virtualenv](https://virtualenv.pypa.io/) works for Python. 

For now this only supports **Bash**. 

## Bash is the dependency

Crucible does what it does with bash itself: builtins, `/dev/tcp`, `/dev/udp` and `/proc`. The http, dns, processes, cache, class and network modules do not call `curl`, `wget`, `dig`, `nc`, `ps` or `timeout`. A script that is poured (see below) needs nothing but bash, version **4.4** or newer (it is developed and tested with 5.2).

That has consequences, and they are stated in the module they belong to:

- Bash cannot do TLS, so there is no `https://`.
- Bash cannot hold a NUL byte in a variable, so text is text. Binary data is read byte exact from a TCP stream (DNS needs it) and not at all from UDP.
- Bash cannot rename a file or take a lock, so the file cache is not atomic.

Some modules exist to wrap a system tool: `files` and `dirs` call `mv`, `chmod` and `chown`, `crypto` calls `sha256sum`, `md5sum` and `shasum`, `io/binary` calls `strings` and `xxd` to list the contents of a binary. What a file is (`binary.is_png`, `binary.get_file_type`, `binary.is_executable` and the rest) bash finds out itself, from the first bytes of the file. Those are the modules that need that tool, and they say so when it is missing. While you develop, `require` downloads modules with `wget`; a poured script does not.

# How to use

To use crucible get the latest stable version and put the `crucible` file in you local path, e.g. `~/.local/bin`.

## Commands

### _init_

The init will turn the directory where it is run into a **crucible** project. It will create a shared directory in which the modules will be put and some metadata. 

### _update_

The update command will update the project with a new version of **crucible**

### _purge_

The purge command will delete the project and associated **crucible** assets

### _pour_

The pour command will get the associated **crucible** assets and pour it into a distributable `.tar.gz` file. It fetches the modules that the main file requires first, so a project that never ran can be poured. The result is the main file and a `.lib` with all modules; it needs bash and nothing else.

# Docker

To make local development easier there exist some docker images to help out.

## Tests

`docker-compose run --rm crucible-test` runs all tests against your working tree, not against what is on GitHub: a stand in for `wget` serves the modules from `src`. Give a regular expression to run some of them: `docker-compose run --rm crucible-test 'cache/|http/'`.

The tests that need a server start one on 127.0.0.1 with `nc`; that is the only place the repository uses it.

## ShellCheck

By running the following command the `shellcheck` will be performed on all scripts to make sure no violations have occurred. 

`docker-compose up shellcheck`

## Crucible

By running the following command you get a nice clean environment in which `crucible` commands can be run without polluting your own host.

`docker-compose run --rm crucible`

# Modules

A module is loaded with `require`, for example `require strings/strings`. Every module is loaded once, however often and from wherever it is required. The ones below are new; the older ones (`arrays`, `maps`, `strings`, `dates`, `logging`, `pipes`, `redirect`, `search`, `crypto`, `io/binary`, `io/files`, `io/network`, `os`) are described in the source, next to each function.

## Processes

`require processes/processes`. Builtins and `/proc`; the functions that look at other processes need Linux.

```bash
processes.spawn sleep 30                  # the process id is in CRUCIBLE_LAST_PID
processes.is_running "$CRUCIBLE_LAST_PID" # a zombie is not running
processes.terminate "$CRUCIBLE_LAST_PID"  # TERM, and KILL after 5 seconds
processes.run_with_timeout 10 some-command arg   # 124 when it had to be stopped: TERM, and KILL after CRUCIBLE_PROCESSES_KILL_AFTER (5) seconds
processes.sleep 0.5                       # without starting sleep
processes.find_by_name sshd; processes.children $$; processes.command_line 1
```

## Memory cache and file cache

`require cache/memory` and `require cache/file`. A cache is an associative array with the name of the cache, so `${sessions[user1]}` and `maps.*` work on it, with the expiry of entries kept next to it. Time is counted in whole seconds.

```bash
cache.memory.create sessions 3600                 # entries live an hour unless said otherwise
cache.memory.put sessions user1 "Ada"
cache.memory.put sessions token abc 30            # this one lives 30 seconds, 0 is forever
cache.memory.get sessions user1                   # fails when it is not there or has expired
cache.memory.get_or_compute_into result sessions user2 load_user   # asks the function when missing

cache.file.create store ~/.cache/myscript.cache 600   # the same, kept in a file
cache.file.put store answer 42
```

A subshell works on a copy, so `put` and `get_or_compute_into` must be called directly and not as `$(...)`; that is why the result of the latter comes back in a variable. The file cache is read as data, never run as code, and a new file can only be read by its owner. It writes the whole file at once and does not lock, scripts that write at the same moment can lose each other's changes.

## HTTP

`require http/http`. A client over `/dev/tcp`: GET, HEAD, POST, PUT, PATCH, DELETE, bodies with a length, chunked bodies and bodies that end when the server hangs up, redirects.

```bash
http.get http://127.0.0.1:8080/status                     # prints the body
http.post http://127.0.0.1:8080/items "$(http.form_encode name Ada city 'New York')"
http.request PUT http://127.0.0.1:8080/items/1 '{"a":1}' 'Content-Type: application/json'
echo "$CRUCIBLE_HTTP_STATUS $CRUCIBLE_HTTP_REASON"; http.header content-type
```

The status of a request is 0 below 400, 22 for 400 and up and 1 when there was no answer. The result is also in `CRUCIBLE_HTTP_STATUS`, `CRUCIBLE_HTTP_BODY` and `CRUCIBLE_HTTP_HEADERS` for a request made outside `$(...)`. `CRUCIBLE_HTTP_TIMEOUT`, `CRUCIBLE_HTTP_MAX_REDIRECTS` and `CRUCIBLE_HTTP_USER_AGENT` change the defaults. **Only `http://`**, and bodies are text.

## DNS

`require dns/dns`. Builds the query and reads the answer itself: A, AAAA, NS, CNAME, SOA, PTR, MX, TXT and SRV, anything else as `\# length hex`.

```bash
dns.resolve example.com A 1.1.1.1         # the addresses, one to a line
dns.query example.com MX                  # whole records, from the first nameserver in /etc/resolv.conf
dns.reverse 1.1.1.1
echo "${CRUCIBLE_DNS_RESPONSE[rcode_name]}" "${CRUCIBLE_DNS_ANSWERS[@]}"
```

The status is 0 for answers, 1 for a failure, 2 for NXDOMAIN and 3 when the name has no record of that type. It asks over **TCP**: an answer is full of NUL bytes and bash can only read those exactly from a stream. `CRUCIBLE_DNS_SERVER`, `CRUCIBLE_DNS_PORT` and `CRUCIBLE_DNS_TIMEOUT` change the defaults.

## Classes

`require class/class`. Not real classes, as the blog post says: definitions, instances and functions that make them meet.

```bash
function person_new   { class.set "$1" name "$2"; }
function person_greet { echo "${2:-Hello}, I am $("$1.name")"; }

class.define Person person_new                  # the constructor is a function, or none
class.define_property Person age 0              # every instance has it, with a default
class.define_method Person greet person_greet   # or the code of the method as the last argument
class.define_static_method Person species 'echo human'

class.new Person alice "Alice"                  # calls person_new alice Alice
alice.name                                      # reads a property
alice.age 30                                    # sets it
alice.greet "Hi"                                # calls a method
Person.species

class.define Student; class.extends Student Person   # methods, statics and constructor are inherited
class.invoke_as Person alice greet                   # the method as Person has it, for a call to the parent
```

The blog post planned for `alice.name=Ada`. That cannot exist in bash: with a dot it is not an assignment but a command, and the handler for unknown commands runs in a subshell and so cannot change anything. `alice.name Ada` does what it was for. As with the caches, `class.new` and `class.set` change state and need to be called directly, not in `$(...)`.

# Future roadmap

## Shells

- [ ] Fish
- [ ] csh
- [ ] ksh
- [ ] zsh

## Core

- [X] Dates
- [X] Logging
- [X] Arrays
- [X] Maps
- [x] Strings
- [x] Pipes
- [x] Redirect
- [x] Search
- [x] Cryptography
- [x] Binary I/O
- [x] File I/O
- [x] Network I/O
- [x] Processes
- [x] [Classes](https://stealthycoder.writeas.com/crucible-the-future)
- [x] Http
- [x] DNS
- [x] [File Cache](https://stealthycoder.writeas.com/crucible-the-future)
- [x] [Memory Cache](https://stealthycoder.writeas.com/crucible-the-future)

## Next

- [ ] [Web framework](https://stealthycoder.writeas.com/crucible-the-future): a live bash process that takes requests on a Unix domain socket and runs controllers by route, built on `processes`, `io`, `http` and `class`. The open question is listening: bash can connect to sockets (`/dev/tcp`, `/dev/udp`) but has no builtin to accept connections on one, so this needs a design decision first (a named pipe, the `accept` loadable builtin that ships with the bash sources, or something else) and a look at what that does to the "bash is the only dependency" rule.
- [ ] `io/binary` without `strings` and `xxd`/`hexdump`: `binary.extract_strings` and `binary.hexdump` are the last functions in the module that call a system tool. The reader that identifies files (`__read_bytes_hex`) is what to build on, as it did for `file`.

# Static Code Analysis

The tool [ShellCheck](https://github.com/koalaman/shellcheck) has been used to perform static code analysis on all scripts, [shfmt](https://github.com/mvdan/sh) checks the formatting of `src`, and the tests run in CI. A warning, a badly formatted file or a failing test fails the build.
