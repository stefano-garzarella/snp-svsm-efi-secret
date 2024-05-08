# AMD SEV-SNP PoC with SVSM, KBS proxy, and Linux's efi_secrets

This PoC will allow you to start a Confidential VM on AMD SEV-SNP.

We will create an encrypted rootfs and boot a VM using QEMU and SVSM in VMPL0.
SVSM will request an attestation report and talk to a Key Broker Server (using
a proxy running in the host) to perform a remote attestation and receive the
rootfs encryption key previously registered with the expected launch
measurement.

At this point SVSM injects this secret into the guest OS leveraging the
EFI configuration table under the `LINUX_EFI_COCO_SECRET_AREA_GUID` entry
(`adf956ad-e98c-484c-ae11-b51c7d336447`) and the
[Linux's `efi_secret` kernel module](https://docs.kernel.org/security/secrets/coco.html). This was previously developed for AMD SEV and SEV-ES, where the table
injection was from the hypervisor. We reuse the same mechanism, but inject
it from SVSM, then directly into the guest VMPL0. This way we do not have to
make any changes in the guest OS.

## Prerequisites

### Host machine

For running this demo, you need:
- AMD processor that supports SEV-SNP
- Coconut Linux kernel installed, you can build it yourself or install it
  via copr in Fedora:
  - *Coconut source kernel code. [optional]*  
    You can build the host kernel by following the instructions here:
    https://github.com/coconut-svsm/svsm/blob/main/Documentation/INSTALL.md#preparing-the-host
  - **Fedora copr package**
```shell
sudo dnf copr enable -y @virtmaint-sig/sev-snp-coconut
sudo dnf install kernel-snp-coconut

# Note: installation may fail on Fedora 39, in which case the
# following steps may help:

sudo dnf install 'dnf-command(download)' rpmdevtools
cd /tmp
dnf --releasever=38 download grubby
rpmdev-extract grubby*.rpm
cd grubby*fc38.x86_64
sudo cp usr/sbin/installkernel /usr/sbin

# Retry the installation
sudo dnf reinstall kernel-snp-coconut
```

### Build machine

This repository contains the QEMU code, EDK2 code, and several Rust
projects, so I recommend that you install the following packages
(for Fedora 39) to use the scripts contained in this demo:

```
sudo dnf builddep https://src.fedoraproject.org/rpms/qemu/raw/f39/f/qemu.spec
sudo dnf builddep https://src.fedoraproject.org/rpms/edk2/raw/f39/f/edk2.spec
sudo dnf install rust cargo
```

## Demo

[![Video demo](https://img.youtube.com/vi/STcKbgSOwo0/maxresdefault.jpg)](https://www.youtube.com/watch?v=STcKbgSOwo0)

### Build QEMU, EDK2, and SVSM

This operation is only required the first time, or when git submodules are updated

```shell
./prepare.sh
```

### Build the guest image with an encrypted rootfs

This is only required the first time or when you want to regenerate a new
image (for example, with a different encryption key).

The script will also install the coconut kernel for the guest, put the
`efi_secret` module in the initrd, and configure `/etc/crypttab` to look at
`/sys/kernel/security/secrets/coco/736869e5-84f0-4973-92ec-06879ce3da0b`
for the encryption key coming from SVSM.

```shell
./build-vm-image.sh --passphrase <LUKS passphrase>
```

### Start Key Broker server and SVSM proxy

This script starts in the host the Key Broker server (it will be remote in a
real scenaio) and the proxy used by SVSM to communicate with the server.
The proxy forwards requests arriving from SVSM via a serial port to the http
connection with the server.

```shell
./start-kbs.sh
```

### Register launch measurement and the encryption key in the Key Broker server

This script first calculates the launch measurement (SVSM, OVMF, etc.) and then
registers it in the Key Broker server along with the rootfs encryption key.

```shell
./register-secret-in-kbs.sh --passphrase <LUKS passphrase>
```

### Start the Confidential VM

And finally we launch our CVM which will receive the key from the Key Broker
server and mount the rootfs by decrypting it.

```shell
sudo ./start-cvm.sh
```
