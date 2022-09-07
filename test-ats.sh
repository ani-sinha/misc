#!/bin/bash

/home/anisinha/workspace/qemu/build/qemu-system-x86_64 \
	-name 'test-vm1' \
	-machine q35 \
	-nodefaults \
	-device VGA,bus=pcie.0,addr=0x2 \
	-blockdev node-name=file_ovmf_code,driver=file,filename=/usr/share/OVMF/OVMF_CODE.fd,auto-read-only=on,discard=unmap \
	-blockdev node-name=drive_ovmf_code,driver=raw,read-only=on,file=file_ovmf_code \
	-blockdev node-name=file_ovmf_vars,driver=file,filename=/usr/share/OVMF/OVMF_VARS.fd,auto-read-only=on,discard=unmap \
	-blockdev node-name=drive_ovmf_vars,driver=raw,read-only=off,file=file_ovmf_vars \
	-device pcie-root-port,id=pcie-root-port-0,multifunction=on,bus=pcie.0,addr=0x1,chassis=1 \
	-device pcie-pci-bridge,id=pcie-pci-bridge-0,addr=0x0,bus=pcie-root-port-0  \
	-device pcie-root-port,id=pcie-root-port-1,port=0x2,addr=0x1.0x2,bus=pcie.0,chassis=3 \
        -device virtio-scsi-pci,id=virtio_scsi_pci0,bus=pcie-root-port-1,addr=0x0  \
	-device pcie-root-port,id=pcie-root-port-2,port=0x3,addr=0x1.0x3,bus=pcie.0,chassis=4 \
	-device virtio-net-pci,mac=9a:7f:22:72:3a:80,id=id962Oxs,bus=pcie-root-port-2,addr=0x0,aer=on,ats=on \
	-blockdev node-name=file_image1,driver=file,auto-read-only=on,discard=unmap,aio=threads,filename=/data/ws2019-q35.qcow2,cache.direct=on,cache.no-flush=off \
        -blockdev node-name=drive_image1,driver=qcow2,read-only=off,cache.direct=on,cache.no-flush=off,file=file_image1 \
        -device scsi-hd,id=image1,drive=drive_image1,write-cache=on \
	-enable-kvm \
	-m 2048 \
	-blockdev '{"driver":"file","filename":"/data/isos/virtio-win-0.1.221.iso","node-name":"libvirt-2-storage","auto-read-only":true,"discard":"unmap"}' \
        -blockdev '{"node-name":"libvirt-2-format","read-only":true,"driver":"raw","file":"libvirt-2-storage"}' \
        -device ide-cd,bus=ide.0,unit=0,drive=libvirt-2-format,id=ide0-0-1,bootindex=2 \
	-drive file=/data/isos/en_windows_server_2019_x64_dvd.iso,media=cdrom,readonly=on,id=cdrom1,if=none,format=raw \
	-device ide-cd,bus=ide.1,unit=0,drive=cdrom1,id=ide0-0-2,bootindex=1 -snapshot -monitor stdio \
	--global ICH9-LPC.acpi-pci-hotplug-with-bridge-support=off

