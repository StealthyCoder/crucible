![.github/workflows/integrity.yml](https://github.com/StealthyCoder/crucible/workflows/.github/workflows/integrity.yml/badge.svg?branch=develop)

# crucible
A shell script framework. This framework exists to help make it easier to create shell script packages with reusable code and modules that are curated and safe. These reusable modules will be _installed_ into a shared location per project similar to how [virtualenv](https://virtualenv.pypa.io/) works for Python. 

For now this only supports **Bash**. 

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

The pour command will get the associated **crucible** assets and pour it into a distributable `.tar.gz` file

# Docker

To make local development easier there exist some docker images to help out.

## ShellCheck

By running the following command the `shellcheck` will be performed on all scripts to make sure no violations have occurred. 

`docker-compose up shellcheck`

## Crucible

By running the following command you get a nice clean environment in which `crucible` commands can be run without polluting your own host.

`docker-compose run --rm crucible`

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
- [ ] Pipes
- [ ] Redirect
- [ ] Search
- [ ] Cryptography
- [ ] Binary I/O
- [x] File I/O
- [ ] Network I/O
- [ ] Processes
- [ ] [Classes](https://stealthycoder.writeas.com/crucible-the-future)
- [ ] Http
- [ ] File Cache
- [ ] Memory Cache

# Static Code Analysis

The tool [ShellCheck](https://github.com/koalaman/shellcheck) has been used to perform static code analysis on all scripts. 
