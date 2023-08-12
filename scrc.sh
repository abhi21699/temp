#!/bin/bash

# Display usage message if no arguments provided
if [ $# -eq 0 ]; then
    echo "Usage: $0 <space separated host list> [-t <ttl>] [-c <count>] [-s <size>]"
    exit 1
fi

# Default values
default_ttl=30
default_count=1
default_size=60

# Initialize variables
ttl=$default_ttl
count=$default_count
size=$default_size
hosts=()

# Parse input options
while [ $# -gt 0 ]; do
    option="$1"
    shift
    if [ "$option" = "-t" ]; then
        ttl="$1"
        shift
    elif [ "$option" = "-c" ]; then
        count="$1"
        shift
    elif [ "$option" = "-s" ]; then
        size="$1"
        shift
    else
        hosts+=( "$option" )
    fi
done

# Main operation
for host in "${hosts[@]}"; do
    echo "Traceroute simulation for host: $host"
    i=1
    destination_reached=false
    while [ "$i" -le "$ttl" ]; do
        echo "TTL: $i - Count: $count - Packet Size: $size"
        ping_output=$(ping -t "$i" -c "$count" -s "$size" "$host" | grep -o '[0-9]*\.[0-9]*\.[0-9]*\.[0-9]*')
        ip_count=0
        for ip in $ping_output; do
            (( ip_count++ ))
            if [ "$ip_count" -eq 2 ]; then
                echo "Hop $i - Intermediate IP: $ip"
                if [ "$ip" == "$(echo "$host" | cut -d' ' -f1)" ]; then
                    echo "Destination IP reached. Exiting..."
                    destination_reached=true
                    break 2  # Break out of both inner and outer loops
                fi
                intermediate_output=$(ping -t "$ttl" -c "$count" -s "$size" "$ip" | grep '[fF]rom')
                if [ -z "$intermediate_output" ]; then
                    echo "No ping response from intermediate hop."
                else
                    echo "$intermediate_output"
                fi
            fi
        done
        if [ "$ip_count" -lt 2 ]; then
            echo "Hop $i - Timeout"
        fi
        (( i++ ))
    done

    if [ "$destination_reached" = true ]; then
        break
    fi
done
