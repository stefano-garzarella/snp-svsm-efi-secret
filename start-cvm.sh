#!/bin/bash

SCRIPT_PATH="$( cd "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"

# Load VM configuration
source "${SCRIPT_PATH}/vm.conf"

function usage
{
    echo -e "usage: $0 [OPTION...]"
    echo -e ""
    echo -e "Start QEMU Confidential VM"
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

${QEMU} \
  -enable-kvm \
  -cpu "${VCPU}" -smp "${NVCPUS}" \
  -machine q35,confidential-guest-support=sev0,memory-backend=ram1,kvm-type=protected \
  -object memory-backend-memfd-private,id=ram1,size=8G,share=true \
  -object sev-snp-guest,id=sev0,cbitpos=51,reduced-phys-bits=1,svsm=on \
  -drive if=pflash,format=raw,unit=0,file="${OVMF_CODE}",readonly=on \
  -drive if=pflash,format=raw,unit=1,file="${OVMF_VARS}",snapshot=on \
  -drive if=pflash,format=raw,unit=2,file="${SVSM}",readonly=on \
  -netdev user,id=vmnic -device e1000,netdev=vmnic,romfile= \
  -drive file="${IMAGE}",if=none,id=disk0,format=qcow2,snapshot=off \
  -device virtio-scsi-pci,id=scsi0,disable-legacy=on,iommu_platform=on \
  -device scsi-hd,drive=disk0,bootindex=0 \
  -serial mon:stdio \
  -serial pty \
  -serial unix:"${PROXY_SOCK}" \
  -no-reboot -display none
