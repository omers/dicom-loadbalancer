#!/bin/bash


function run_storescp {
    mkdir -p $1
    storescp --accept-all --socket-timeout 10 --output-directory $1 $2
}

# Start the first process
haproxy -f /etc/haproxy/haproxy.cfg &
run_storescp /tmp/store1 11212 &
run_storescp /tmp/store2 11213 &

# Wait for any process to exit
wait -n

# Exit with status of process that exited first
exit $?