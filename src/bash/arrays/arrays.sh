#!/usr/bin/env bash
### CRUCIBLE META DATA ###
# CRUCIBLE_VERSION=0.2.1
# CRUCIBLE_AUTHOR=StealthyCoder
# CRUCIBLE_CREATED=1578009741
### CRUCIBLE META DATA ###

require core/.internal

function arrays.transform_into_array {
    local -a arr
    local print
    arr=()
    print="$(declare -p arr | sed -e "s/declare -a arr=/export $1=/" )"
    eval "$print"
}

function arrays.add {
    __verify_nr_args "$#" 2 arrays.add
    
    if __verify_if_arg_is_array "$1"
    then
        local arr element print
        print="$(declare -p "$1" | sed -e "s/declare -ax $1=/arr=/" )"
        eval "$print"
        element="$2"        
        arr+=("$element")    
        print="$(declare -p arr | sed -e "s/declare -a arr=/export $1=/" )"
        eval "$print"
    fi

}

function arrays.push {
    arrays.add "$1" "$2"
}

function arrays.add_all {
    if __verify_if_arg_is_array "$1"
    then
        local arr element print export_name
        print="$(declare -p "$1" | sed -e "s/declare -ax $1=/arr=/" )"
        eval "$print"
        export_name="$1"
        shift
        while test $# -gt 0
        do
            element="$1"
            arr+=("$element")
            shift
        done
        
        print="$(declare -p arr | sed -e "s/declare -a arr=/export $export_name=/" )"
        eval "$print"
    fi
}

function arrays.concat {
    if __verify_if_arg_is_array "$1"
    then
        if __verify_if_arg_is_array "$2"
        then
            local src target print
            print="$(declare -p "$1" | sed -e "s/declare -ax $1=/src=/" )"
            eval "$print"
            print="$(declare -p "$2" | sed -e "s/declare -ax $2=/target=/" )"
            eval "$print"
            for element in "${target[@]}"
            do
                src+=("$element")
            done
            print="$(declare -p src | sed -e "s/declare -a src=/export $1=/" )"
            eval "$print"
        fi
    fi
    
}

function arrays.get {
    __verify_nr_args "$#" 2 arrays.get
    if __verify_if_arg_is_array "$1"
    then
        local arr element print
        print="$(declare -p "$1" | sed -e "s/declare -ax $1=/arr=/" )"
        eval "$print"
        echo "${arr[$2]}"
    fi
}

function arrays.pop {
    if __verify_if_arg_is_array "$1"
    then
        local arr last element print size counter
        local -a target
        target=()
        print="$(declare -p "$1" | sed -e "s/declare -ax $1=/arr=/" )"
        eval "$print"
        if [ "${#arr[@]}" -le 0 ]
        then
            return 0
        fi

        last="${arr[-1]}"
        size="$(( ${#arr[@]} - 1 ))"
        counter=0
        while test "$counter" -ne "$size"
        do
            element="${arr[$counter]}"
            target+=("$element")
            counter="$((counter + 1))"
        done

        print="$(declare -p target | sed -e "s/declare -a target=/export $1=/" )"
        eval "$print"

        eval "export $2=$last"
    fi

}

function arrays.values {
    if __verify_if_arg_is_array "$1"
    then

        local arr print
        print="$(declare -p "$1" | sed -e "s/declare -ax $1=/arr=/" )"
        eval "$print"
        echo "${arr[@]}"
    fi
}

function arrays.entries {
    if __verify_if_arg_is_array "$1"
    then

        local arr print size counter
        print="$(declare -p "$1" | sed -e "s/declare -ax $1=/arr=/" )"
        eval "$print"
        if [ "${#arr[@]}" -le 0 ]
        then
            return 0
        fi

        size="$(( ${#arr[@]} ))"
        counter=0
        while test "$counter" -ne "$size"
        do
            echo "Index: $counter, Value: ${arr[$counter]}"
            counter="$((counter + 1))"
        done
    fi

}

function arrays.clear {
    if __verify_if_arg_is_array "$1"
    then
        arrays.transform_into_array "$1"
    fi
}