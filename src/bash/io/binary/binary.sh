#!/usr/bin/env bash
### CRUCIBLE META DATA ###
# CRUCIBLE_VERSION={CRUCIBLE_VERSION}
# CRUCIBLE_AUTHOR=StealthyCoder
# CRUCIBLE_CREATED={CRUCIBLE_CREATED}
### CRUCIBLE META DATA ###

require core/.internal
require logging/logging
require os/os
require strings/strings

function binary.read_file {
    __verify_nr_args "$#" 1 binary.read_file
    local target
    target="$1"
    cat "$target"
}

function binary.is_printable {
    __verify_nr_args "$#" 1 binary.is_printable
    local target result
    target="$1"
    result=0
    if __command_exists "file"
    then
        if [[ "$(file "$1" 2>/dev/null)" =~ .+text$ ]]
        then
            result=1
        elif [[ "$(file "$1" 2>/dev/null)" =~ .+text.+ ]]
        then
            result=1
        fi
    else
        logging.warning "[file] command does not exist, cannot determine if $1 is printable"
    fi
     __to_boolean "$result" "==" 1
}

function binary.is_html {
    __verify_nr_args "$#" 1 binary.is_html
    local target result
    target="$1"
    result=1
    if __command_exists "file"
    then
        if [[ ! "$(file "$1" 2>/dev/null)" =~ .+HTML\ document.+ ]]
        then
            result=0
        fi
    else
        logging.warning "[file] command does not exist, cannot determine if $1 is HTML"
        result=0
    fi
    __to_boolean "$result" "==" 1
}

function binary.is_text {
    __verify_nr_args "$#" 1 binary.is_text
    local target result
    target="$1"
    result=1
    if __command_exists "file"
    then
        if [[ ! "$(file "$1" 2>/dev/null)" =~ .+text$ ]]
        then
            result=0
        fi
        if [[ ! "$(file "$1" 2>/dev/null)" =~ .+text.+ ]]
        then
            result=0
        fi
    else
        logging.warning "[file] command does not exist, cannot determine if $1 is text"
        result=0
    fi
    __to_boolean "$result" "==" 1
}

function binary.is_binary {
    __verify_nr_args "$#" 1 binary.is_binary
    local target result
    target="$1"
    result=1
    if __command_exists "file"
    then
        if [[ ! "$(file "$1" 2>/dev/null)" =~ .+executable.+ ]]
        then
            result=0
        fi
    else
        logging.warning "[file] command does not exist, cannot determine if $1 is binary"
        result=0
    fi
    __to_boolean "$result" "==" 1
}

function binary.is_pdf {
    __verify_nr_args "$#" 1 binary.is_pdf
    local target result
    target="$1"
    result=1
    if __command_exists "file"
    then
        if [[ ! "$(file "$1" 2>/dev/null)" =~ .+PDF\ document.+ ]]
        then
            result=0
        fi
    else
        logging.warning "[file] command does not exist, cannot determine if $1 is PDF"
        result=0
    fi
    __to_boolean "$result" "==" 1
}

function binary.is_jpeg {
    __verify_nr_args "$#" 1 binary.is_jpeg
    local target result
    target="$1"
    result=1
    if __command_exists "file"
    then
        if [[ ! "$(file "$1" 2>/dev/null)" =~ .+JPEG.+ ]]
        then
            result=0
        fi
    else
        logging.warning "[file] command does not exist, cannot determine if $1 is JPEG/JPG"
        result=0
    fi
    __to_boolean "$result" "==" 1
}

function binary.is_png {
    __verify_nr_args "$#" 1 binary.is_png
    local target result
    target="$1"
    result=1
    if __command_exists "file"
    then
        if [[ ! "$(file "$1" 2>/dev/null)" =~ .+PNG.+ ]]
        then
            result=0
        fi
    else
        logging.warning "[file] command does not exist, cannot determine if $1 is PNG"
        result=0
    fi
    __to_boolean "$result" "==" 1
}

function binary.is_gif {
    __verify_nr_args "$#" 1 binary.is_gif
    local target result
    target="$1"
    result=1
    if  __command_exists "file"
    then
        if [[ ! "$(file "$1" 2>/dev/null)" =~ .+GIF.+ ]]
        then
            result=0
        fi
    else
        logging.warning "[file] command does not exist, cannot determine if $1 is GIF"
        result=0
    fi
    __to_boolean "$result" "==" 1
}

function binary.is_image {
    __verify_nr_args "$#" 1 binary.is_gif
    local target result
    target="$1"
    result=1
    if  __command_exists "file"
    then
        if [[ ! "$(file "$1" 2>/dev/null)" =~ .+image\ data.+ ]]
        then
            result=0
        fi
    else
        logging.warning "[file] command does not exist, cannot determine if $1 is an image"
        result=0
    fi
    __to_boolean "$result" "==" 1
}

function binary.is_executable {
    __verify_nr_args "$#" 1 binary.is_gif
    local target result
    target="$1"
    result=0
    if  __command_exists "file"
    then
        if [[ "$(file "$target" 2>/dev/null)" =~ .+executable.+ ]]
        then
            local arch
            arch="$(os.get_architecture)"
            arch="$(strings.replace_char_with "$arch" _ -)"
            if [[ "$(file "$target" 2>/dev/null)" =~ .+$arch.+ ]]
            then
                result=1
            fi
        elif [[ "$(file "$target" 2>/dev/null)" =~ .+executable$ ]]
        then
            result=1
        fi
    else
        logging.warning "[file] command does not exist, cannot determine if $1 is executable"
    fi
    __to_boolean "$result" "==" 1
}

function binary.get_file_type {
    __verify_nr_args "$#" 1 binary.get_file_type
    local target length pos result file_contents
    target="$1"
    result=""
    if  __command_exists "file"
    then
        file_contents="$(file "$target")"
        length="$(strings.length "$file_contents")"
        pos="$(strings.lindex "$file_contents" :)"
        result="$(strings.slice "$file_contents" $pos $length)"
        length="$(strings.length "$result")"
        result="$(strings.slice "$result" 2 "$length" )"
    else
        logging.warning "[file] command does not exist, cannot determine filetype of $target"
    fi
    echo "$result"
}

# Binary
#   - Write content to file
#   v Read content of file
#   - write contents to stdout
#   - write contents to stderr
#   - write contents to dev null
#   - read random bytes
#   v get file type
#   v isPNG
#   v isGIF
#   v isExecutable
#   v isBinary
#   v isPrintable
#   v isPDF
#   v isHTML
#   v isText
#   - extract text from binary
#   - create hexdump from binary