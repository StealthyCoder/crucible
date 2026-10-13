# Changelog

## 0.3.0

The release that completes the core roadmap, and that makes the existing modules trustworthy:
most of them had never been tested.

### Added

- **Processes** (`processes/processes`): spawn, wait, signal, terminate, run with a timeout, a sleep
  that starts no process, and inspection through `/proc`.
- **Memory cache** and **file cache** (`cache/memory`, `cache/file`): entries with a ttl, hit and miss
  statistics, `get_or_compute_into`. The file cache is read as data and never run as code.
- **Http** (`http/http`): a client over `/dev/tcp` with all common methods, three kinds of body,
  redirects and url and form encoding. `http://` only, bash cannot do TLS.
- **Dns** (`dns/dns`): queries and answers built and read in bash, over TCP; A, AAAA, NS, CNAME,
  SOA, PTR, MX, TXT and SRV.
- **Classes** (`class/class`): classes with properties and defaults, methods, static methods,
  inheritance, and the functions `instance.property` and `instance.method`.
- `network.tcp.receive_hex`, `send_hex` and `network.udp.send_hex` for binary data.
- Tests for every module, and for `crucible pour`.

### Changed

- `io/binary` finds out what a file is by itself, from magic numbers and a look at the bytes, and no longer
  needs `file(1)`: compared with `file` 5.44 on 633 programs, libraries, scripts and documents it came to the
  same class for every one. ELF programs are told from libraries the way `file` does it, by `DF_1_PIE`.
- Everything new runs on bash alone; no `curl`, `wget`, `dig`, `nc`, `ps` or `timeout`. Bash 4.4 or newer.
- `crucible pour` fetches what the main file requires before it bundles, so a project that never ran
  can be poured.
- `require` stops with a message when a module cannot be downloaded, where it used to continue with
  an empty file. It also loads every module once, which makes loading much faster for modules that
  many others depend on, and keeps a safe variant from being replaced by its base module.
- Cached modules end in `.sh`. Run `crucible update` once in an existing project; it clears the old cache.
- `network.udp.receive` is text only. The DNS parser that lived in it is part of the `dns` module now.
- The class proof of concept: methods are functions or code, `class.invoke_method` is `class.invoke`.
- CI fails when any check fails and looks at all files. It used to report the last command only, and
  never reached directories deeper than two levels.

### Fixed

- Three `require` lines named modules that do not exist (`io/files/dirs`, `io/files/safe/user`, `io/network/udp`).
- A project in a directory with `id`, `version` or `location` in its path broke `purge`, `update` and `require`.
- `strings.contains_string_ignore_case` was always true; `strings.join` with a delimiter of more than
  one character.
- `files.file_exists`, `dirs.dir_exists` and the four `move_*` functions did not work. The group
  "clear" permission variants removed the permissions they had just set, `add_other_write_execute_only`
  was missing, and `dirs.dir_copy_perms_recursive` did not recurse.
- `binary.is_text` was never true.
- `binary_*sum_check` always failed on current coreutils.
- Hashing a file with a space in its name; `uuidv4` did not set the variant bits.
- All of `search`: every function returned nothing. It no longer loads the safe files module either.
- TCP and UDP: the inline mode called functions that do not exist, closing a descriptor did not work,
  inline calls leaked descriptors, and host names with a hyphen were refused.
