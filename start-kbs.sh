#!/bin/bash

SCRIPT_PATH="$( cd "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"

# Load VM configuration
source "${SCRIPT_PATH}/vm.conf"

function usage
{
    echo -e "usage: $0 [OPTION...]"
    echo -e ""
    echo -e "Start Key Broker Server and SVSM proxy for QEMU"
    echo -e ""
    echo -e " -h, --help          print this help"
}

pushd "${SCRIPT_PATH}/kbs/reference-kbs"
cargo run &
popd

# Wait till the server is listening on port 8000
while ! netstat -tna | grep 'LISTEN\>' | grep -q ':8000\>'; do
  sleep 1
done

set -x

pushd "${SCRIPT_PATH}/kbs/kbc"
cargo run --example=svsm-proxy -- --unix "${PROXY_SOCK}"  --url "${KBS_URL}" -f
popd

kill "$(jobs -p)"
