#!/bin/bash

SCRIPT_PATH="$( cd "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"

function usage
{
    echo -e "usage: $0 [OPTION...]"
    echo -e ""
    echo -e "Initialize git submodules and build QEMU, EDK2, SVSM, etc."
    echo -e ""
    echo -e " -h, --help          print this help"
}

while [ "$1" != "" ]; do
    case $1 in
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

pushd "${SCRIPT_PATH}"
git submodule update --init
popd
# Based on https://github.com/coconut-svsm/svsm/blob/main/Documentation/INSTALL.md

pushd "${SCRIPT_PATH}/qemu"
if [ ! -d "./build" ]; then
    ./configure --disable-docs --disable-user --target-list=x86_64-softmmu
fi
make -j"$(nproc)"
popd

pushd "${SCRIPT_PATH}/edk2"
git submodule update --init
export PYTHON3_ENABLE=TRUE
export PYTHON_COMMAND=python3
make -j"$(nproc)" -C BaseTools/
{
    source ./edksetup.sh
    build -a X64 -b DEBUG -t GCC5 -D DEBUG_ON_SERIAL_PORT -D DEBUG_VERBOSE -p OvmfPkg/OvmfPkgX64.dsc
}
popd

pushd "${SCRIPT_PATH}/svsm"
make
popd
