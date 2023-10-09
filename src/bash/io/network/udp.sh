#!/usr/bin/env bash
### CRUCIBLE META DATA ###
# CRUCIBLE_VERSION={CRUCIBLE_VERSION}
# CRUCIBLE_AUTHOR=StealthyCoder
# CRUCIBLE_CREATED={CRUCIBLE_CREATED}
### CRUCIBLE META DATA ###

require core/.internal
require io/network/.internal
require logging/logging
require arrays/arrays
require maps/maps
require string/strings

function network.udp.send {
    __verify_nr_args "$#" 2 network.udp_send
    local fd data
    fd="$1"
    data="$2"
    echo -e "$data" >&"$fd"
}

function network.udp.receive {
    __verify_nr_args "$#" 1 network.udp_receive
    if ! __command_exists "bc"; then
        logging.error "[bc] command is needed to execute network.udp.receive"
        exit 1
    fi
    local fd response
    fd="$1"
    response=$(dd status=none count=1 <&"$fd" | od -vt x1 -A n | tr -d ' ' | tr -d '\n' | tr '[:lower:]' '[:upper:]')
    local id params qr opcode aa tc rd ra z rcode
    id=$((16#${response:0:4}))
    maps.transform_into_map DNS_RESPONSE_"$id"
    params=$(echo "obase=2; ibase=16; ${response:5:4}" | bc)
    qr=$(echo "obase=10; ibase=2; ${params:0:1}" | bc)
    opcode=$(echo "ibase=2; obase=10; ${params:1:4}" | bc)
    aa=$(echo "ibase=2; obase=10; ${params:5:1}" | bc)
    tc=$(echo "ibase=2; obase=10; ${params:6:1}" | bc)
    rd=$(echo "ibase=2; obase=10; ${params:7:1}" | bc)
    ra=$(echo "ibase=2; obase=10; ${params:8:1}" | bc)
    z=${params:9:3}
    rcode=$(echo "ibase=2; obase=10; ${params:12}" | bc)

    maps.put DNS_RESPONSE_"$id" ID $((16#${response:0:4}))
    if [ "$qr" -eq 0 ]
    then
        maps.put DNS_RESPONSE_"$id" QR "Request"
    else

        maps.put DNS_RESPONSE_"$id" QR "Response"
    fi

    case $opcode in
        0)
            maps.put DNS_RESPONSE_"$id" OPCODE "Standard Query"
            ;;
        1)
            maps.put DNS_RESPONSE_"$id" OPCODE "Reverse Lookup"
            ;;
        2)
            maps.put DNS_RESPONSE_"$id" OPCODE "Server Status"
            ;;
        3)
            maps.put DNS_RESPONSE_"$id" OPCODE "Reserved"
            ;;
    esac

    if [ "$aa" -eq 0 ]
    then
        maps.put DNS_RESPONSE_"$id" AA "Non-Authoritative"
    else
        maps.put DNS_RESPONSE_"$id" AA "Authoritative"
    fi

    if [ "$tc" -eq 0 ]
    then
        maps.put DNS_RESPONSE_"$id" TC "Not truncated"
    else
        maps.put DNS_RESPONSE_"$id" TC "Truncated"
    fi

    if [ "$rd" -eq 0 ]
    then
        maps.put DNS_RESPONSE_"$id" RD "Recursion desired"
    else
        maps.put DNS_RESPONSE_"$id" RD "Recursion not desired"
    fi

    if [ "$ra" -eq 0 ]
    then
        maps.put DNS_RESPONSE_"$id" RA "Recursion not available"
    else
        maps.put DNS_RESPONSE_"$id" RA "Recursion available"
    fi

    maps.put DNS_RESPONSE_"$id" Z "$z"

    case "$rcode" in
        0)
            maps.put DNS_RESPONSE_"$id" RCODE "No Error"
            ;;
        1)
            maps.put DNS_RESPONSE_"$id" RCODE "Format error - The name server was unable to interpret the query."
            ;;
        2)
            maps.put DNS_RESPONSE_"$id" RCODE "Server failure - The name server was unable to process this query due to a problem with the name server."
            ;;
        3)
            maps.put DNS_RESPONSE_"$id" RCODE "Name Error - Meaningful only for responses from an authoritative name server, this code signifies that the domain name referenced in the query does not exist."
            ;;
        4)
            maps.put DNS_RESPONSE_"$id" RCODE "Not Implemented - The name server does not support the requested kind of query."
            ;;
        5)
            maps.put DNS_RESPONSE_"$id" RCODE "Refused - The name server refuses to perform the specified operation for policy reasons.  For example, a name server may not wish to provide the information to the particular requester, or a name server may not wish to perform a particular operation (e.g., zone transfer) for particular data."
            ;;
    esac

    maps.put DNS_RESPONSE_"$id" QDCOUNT $((16#${response:8:4}))
    maps.put DNS_RESPONSE_"$id" ANCOUNT $((16#${response:12:4}))
    maps.put DNS_RESPONSE_"$id" NSCOUNT $((16#${response:16:4}))
    maps.put DNS_RESPONSE_"$id" ARCOUNT $((16#${response:20:4}))

    # TODO: Handle ANCOUNT and ARCOUNT correctly

    # NOTE: Chop off first octal, read the rest as binary, then get that many octals chop off repeat until 0000 0000

    local label labelcnt data label_offset data_offset qname aname
    label=$((16#${response:24:2}))
    label_offset=26
    qname=""

    while [[ "$label" -ne 0 ]]; do
        for i in "$(seq "$label")"; do
            data_offset=$(("$label_offset" + (2 * ("$i" -1))))
            qname=$(strings.concat "$qname" "$(printf "\x${response:data_offset:2}")")
        done
        qname=$(strings.concat "$qname" ".")
        data_offset=$(("$data_offset" +  2 ))
        label=$((16#${response:data_offset:2}))
        label_offset=$(("$data_offset" + 2))
    done
    data_offset=$(("$data_offset" +  2 ))
    maps.put DNS_RESPONSE_"$id" QNAME "$qname"

    case $((16#${response:data_offset:4})) in
        1)
            maps.put DNS_RESPONSE_"$id" QTYPE "A"
            ;;
    esac
    data_offset=$(("$data_offset" +  4 ))
    case $((16#${response:data_offset:4})) in
        1)
            maps.put DNS_RESPONSE_"$id" QCLASS "IN"
            ;;
    esac
    data_offset=$(("$data_offset" +  4 ))

    local alabel alabel_offset a_start_offset adata_offset pointer
    pointer=$(echo "obase=2; ibase=16; ${response:data_offset:4}" | bc)
    pointer=${pointer:2}
    a_start_offset=$(echo "obase=10; ibase=2; $pointer" | bc)
    data_offset=$(("$data_offset" +  4 ))

    alabel=$((16#${response:$(("$a_start_offset" * 2)):2}))
    alabel_offset=26
    aname=""

    while [[ "$alabel" -ne 0 ]]; do
        for i in "$(seq "$alabel")"; do
            adata_offset=$(("$alabel_offset" + (2 * ("$i" -1))))
            aname=$(strings.concat "$aname" "$(printf "\x${response:adata_offset:2}")")
        done
        aname=$(strings.concat "$aname" ".")
        adata_offset=$(("$adata_offset" +  2 ))
        alabel=$((16#${response:adata_offset:2}))
        alabel_offset=$(("$adata_offset" + 2))
    done
    maps.put DNS_RESPONSE_"$id" ANAME "$aname"

    case $((16#${response:data_offset:4})) in
        1)
            maps.put DNS_RESPONSE_"$id" ATYPE "A"
            ;;
    esac
    data_offset=$(("$data_offset" +  4 ))
    case $((16#${response:data_offset:4})) in
        1)
            maps.put DNS_RESPONSE_"$id" ACLASS "IN"
            ;;
    esac
    data_offset=$(("$data_offset" +  4 ))

    maps.put DNS_RESPONSE_"$id" TTL $((16#${response:data_offset:8}))
    data_offset=$(("$data_offset" +  8 ))
    case $(maps.get DNS_RESPONSE_"$id" ATYPE) in
        "A")
            maps.put DNS_RESPONSE_"$id" RDLENGTH "$((16#${response:data_offset:4}))"
            data_offset=$(("$data_offset" +  4 ))
            local ip
            ip=""
            ip=$(strings.concat "$ip" "$(echo "obase=10; ibase=16; ${response:data_offset:2}" | bc)")
            ip=$(strings.concat "$ip" ".")
            data_offset=$(("$data_offset" +  2 ))
            ip=$(strings.concat "$ip" "$(echo "obase=10; ibase=16; ${response:data_offset:2}" | bc)")
            ip=$(strings.concat "$ip" ".")
            data_offset=$(("$data_offset" +  2 ))
            ip=$(strings.concat "$ip" "$(echo "obase=10; ibase=16; ${response:data_offset:2}" | bc)")
            ip=$(strings.concat "$ip" ".")
            data_offset=$(("$data_offset" +  2 ))
            ip=$(strings.concat "$ip" "$(echo "obase=10; ibase=16; ${response:data_offset:2}" | bc)")
            maps.put DNS_RESPONSE_"$id" RDATA "$ip"
            ;;
    esac
}

function network.udp {
    case "$#" in
        0 | 1)
            logging.error "network.udp: Wrong number of arguments, need at least 2 or 3."
            logging.error "network.udp: usage is network.udp <HOST> <PORT>"
            logging.error "to setup a file descriptor to send messages"
            logging.error "network.udp: usage is network.udp <HOST> <PORT> <DATA>"
            logging.error "to send one message and immediately get response"
            exit 1
            ;;
        2)
            local host port
            host="$1"
            port="$2"
            if ! network.verify_host "$host"; then
                logging.error "Invalid hostname: $host"
                exit 1
            fi
            if ! network.verify_port "$port"; then
                logging.error "Invalid port: $port"
                exit 1
            fi
            local available_fd
            for fd in $(ls /proc/$$/fd); do
                if test "$fd" -lt 255; then
                    available_fd="$fd"
                elif test "$fd" -eq 255; then
                    available_fd="$(($available_fd + 1))"
                fi
            done
            eval "exec $available_fd<>/dev/udp/$host/$port"
            export CRUCIBLE_NETWORK_FD="$available_fd"
            logging.debug "Exported CRUCIBLE_NETWORK_FD to value: $available_fd"
            ;;
        3)
            local host port data
            host="$1"
            port="$2"
            data="$3"
            if ! network.verify_host "$host"; then
                logging.error "Invalid hostname: $host"
                exit 1
            fi
            if ! network.verify_port "$port"; then
                logging.error "Invalid port: $port"
                exit 1
            fi
            local available_fd
            for fd in $(ls /proc/$$/fd); do
                if test "$fd" -lt 255; then
                    available_fd="$fd"
                elif test "$fd" -eq 255; then
                    available_fd="$(($available_fd + 1))"
                fi
            done
            eval "exec $available_fd<>/dev/udp/$host/$port"
            network.udp_send "$available_fd" "$data"
            echo "$(network.udp_receive "$available_fd")"
            ;;
        *)
            arrays.transform_into_array args
            arrays.add_all args "$@"
            local surplus i
            surplus=""
            for ((i = 3; i < ${#args[@]}; i++)); do
                surplus+=" ${args[$i]}"
            done
            logging.warning "Ignoring surplus:$surplus"
            unset args
            local host port data
            host="$1"
            port="$2"
            data="$3"
            if ! network.verify_host "$host"; then
                logging.error "Invalid hostname: $host"
                exit 1
            fi
            if ! network.verify_port "$port"; then
                logging.error "Invalid port: $port"
                exit 1
            fi
            local available_fd
            for fd in $(ls /proc/$$/fd); do
                if test "$fd" -lt 255; then
                    available_fd="$fd"
                elif test "$fd" -eq 255; then
                    available_fd="$(($available_fd + 1))"
                fi
            done
            eval "exec $available_fd<>/dev/udp/$host/$port"
            network.udp_send "$available_fd" "$data"
            echo "$(network.udp_receive "$available_fd")"
            ;;
    esac
}

function network.udp.close {
    __verify_nr_args "$#" 1 network.close
    local fd
    fd=$1
    exec "$fd"<&-
}
