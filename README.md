# crucible
A shell script framework. This framework exists to help make it easier to create shell script packages with reusable code and modules that are curated and safe.

For now this only supports **Bash**. 

# How to use

To use crucible get the latest stable version and put the `crucible` file in you local path, e.g. `~/.local/bin`.

## Commands

### _init_

The init will turn the directory where it is run into a **crucible** project. It will create a shared directory in which the modules will be put and some metadata. 

### _update_

The update command will update the project with a new version of **crucible**

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

## Core

- [ ] Dates
- [ ] Logging
- [ ] Arrays

# Static Code Analysis

The tool [ShellCheck](https://github.com/koalaman/shellcheck) has been used to perform static code analysis on all scripts. 
