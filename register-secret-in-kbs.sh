#!/bin/bash

SCRIPT_PATH="$( cd "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"

# Load VM configuration
source "${SCRIPT_PATH}/vm.conf"

function usage
{
    echo -e "usage: $0 [OPTION...]"
    echo -e ""
    echo -e "Build a VM image with rootfs encrypted"
    echo -e ""
    echo -e " -p, --passphrase    LUKS passphrase [default: ${LUKS_PASSPHRASE}]"
    echo -e " -h, --help          print this help"
}

while [ "$1" != "" ]; do
    case $1 in
        -p | --passphrase )
            shift
            LUKS_PASSPHRASE=$1
            ;;
        -h | --help )
            usage
            exit
            ;;
        * )
            echo -e "\nParameter not found: $1\n"
            usage
            exit 1
    esac
    shift
done

set -ex

OVMF_VARS_SIZE="$(stat -c %s "${OVMF_VARS}")"
MEASUREMENT="$("${SCRIPT_PATH}/sev-snp-measure/sev-snp-measure.py" \
    --mode snp:svsm --vmm-type QEMU --vcpu-type "${VCPU}" \
    --vcpus "${NVCPUS}" \
    --ovmf "${OVMF_CODE}" --vars-size "${OVMF_VARS_SIZE}" --svsm "${SVSM}")"

pushd "${SCRIPT_PATH}/kbs/kbc"
cargo run --example=svsm-register --all-features -- --url "${KBS_URL}" --reference-kbs svsm  --passphrase "${LUKS_PASSPHRASE}" --measurement "${MEASUREMENT}"
popd
