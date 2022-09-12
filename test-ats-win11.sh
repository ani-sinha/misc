#!/bin/bash

mkdir -p /tmp/emulated_tpm
/usr/bin/swtpm socket --daemon --terminate \
	       --tpmstate dir=/tmp/emulated_tpm \
	       --ctrl type=unixio,path=/tmp/emulated_tpm/swtpm-sock,mode=0600 \
	       --log file=/tmp/emulated_tpm/swtpm.log,level=20 \
	       --tpm2 --pid file=/tmp/emulated_tpm/swtpm.pid

/home/anisinha/workspace/qemu/build/qemu-system-x86_64 \
        -name 'test-vm1' \
	-nodefaults \
	-global ICH9-LPC.disable_s3=1 \
        -global ICH9-LPC.disable_s4=1 \
	-global driver=cfi.pflash01,property=secure,value=on \
	-device VGA,bus=pcie.0,addr=0x2 \
        -machine pc-q35-6.2,usb=off,vmport=off,smm=on,dump-guest-core=on,pflash0=drive_ovmf_code,pflash1=drive_ovmf_vars \
        -no-hpet \
	-no-shutdown \
	-boot menu=on,strict=on \
	-blockdev node-name=file_ovmf_code,driver=file,filename=/usr/share/OVMF/OVMF_CODE_4M.secboot.fd,auto-read-only=on,discard=unmap \
	-blockdev node-name=drive_ovmf_code,driver=raw,read-only=on,file=file_ovmf_code \
	-blockdev node-name=file_ovmf_vars,driver=file,filename=/usr/share/OVMF/OVMF_VARS_4M.fd,auto-read-only=on,discard=unmap \
	-blockdev node-name=drive_ovmf_vars,driver=raw,read-only=off,file=file_ovmf_vars \
	-device pcie-root-port,id=pcie-root-port-0,multifunction=on,bus=pcie.0,addr=0x1,chassis=1 \
	-device pcie-pci-bridge,id=pcie-pci-bridge-0,addr=0x0,bus=pcie-root-port-0  \
	-device pcie-root-port,id=pcie-root-port-1,port=0x2,addr=0x1.0x2,bus=pcie.0,chassis=3 \
        -device virtio-scsi-pci,id=virtio_scsi_pci0,bus=pcie-root-port-1,addr=0x0  \
	-device pcie-root-port,id=pcie-root-port-2,port=0x3,addr=0x1.0x3,bus=pcie.0,chassis=4 \
	-device virtio-net-pci,mac=9a:7f:22:72:3a:80,id=id962Oxs,bus=pcie-root-port-2,addr=0x0,aer=on,ats=on \
	-blockdev node-name=file_image1,driver=file,auto-read-only=on,discard=unmap,aio=threads,filename=/data/win2012.qcow2,cache.direct=on,cache.no-flush=off \
        -blockdev node-name=drive_image1,driver=qcow2,read-only=off,cache.direct=on,cache.no-flush=off,file=file_image1 -snapshot \
        -device scsi-hd,id=image1,drive=drive_image1,write-cache=on \
	-enable-kvm \
	-m 4096 \
	-cpu host,migratable=on \
        -smp 4,maxcpus=4,cores=2,threads=1,dies=1,sockets=2  \
	-blockdev driver=file,filename=/data/isos/virtio-win-0.1.221.iso,node-name=virtio_driver_file,auto-read-only=true,discard=unmap \
        -blockdev node-name=virtio_driver_drive,read-only=true,driver=raw,file=virtio_driver_file \
        -device ide-cd,bus=ide.0,unit=0,drive=virtio_driver_drive,id=ide0-0-1,bootindex=2 \
	-drive file=/data/isos/win/win11.iso,media=cdrom,readonly=on,id=cdrom1,if=none,format=raw \
	-device ide-cd,bus=ide.1,unit=0,drive=cdrom1,id=ide0-0-2,bootindex=1 -monitor stdio \
	-chardev socket,id=chrtpm,path=/tmp/emulated_tpm/swtpm-sock \
        -tpmdev emulator,id=tpm0,chardev=chrtpm \
	-device tpm-tis,tpmdev=tpm0 \
	--global ICH9-LPC.acpi-pci-hotplug-with-bridge-support=on
