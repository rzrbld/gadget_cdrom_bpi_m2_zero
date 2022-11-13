#!/bin/bash

FILE="/iso.img"

if [ -f "$FILE" ]; then
    echo "$FILE already exists" 1>&2
    exit 0
fi

resize2fs_status="$(systemctl is-enabled armbian-resize-filesystem)"
if [[ $resize2fs_status == "enabled" ]]; then
    sleep 40
    echo "armbian-resize-filesystem in progress" 2>&1
    exit 1
fi

free="$(df -k / | tail -n1 | awk '{print $4}')"
size=$(($free-(1024*1024*2)))
if [ "$size" -lt "$((free/2))" ]; then
    size=$((free/2))
fi
size="${size}k"
part_type="ntfs"
 
echo "Creating $size image..."  1>&2

fallocate -l "$size" "$FILE"
dev="$(losetup -fL --show "$FILE")"

parted "$dev" mklabel gpt
parted "$dev" mkpart p "$part_type" 2M 100%

mkfs.exfat -n BPiHDD "${dev}p1"

losetup -d "$dev"
sync

mkdir -p /iso

echo "img.iso creation is done!"  1>&2

systemctl disable gadget_cdrom_auto_img.service && \
systemctl restart gadget_cdrom.service && \
systemctl stop gadget_cdrom_auto_img.service
