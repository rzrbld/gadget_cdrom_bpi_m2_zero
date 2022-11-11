#!/bin/bash -ue

FILE="/iso.img"

if [ -f "$FILE" ]; then
    exit 0
fi

resize2fs_status="$(systemctl is-enabled armbian-resize-filesystem)"
if [[ $resize2fs_status == "enabled" ]]; then
    sleep 5
    ./$0
    exit 1
fi

free="$(df -k / | tail -n1 | awk '{print $4}')"
size=$(($free-(1024*1024*2)))
if [ "$size" -lt "$((free/2))" ]; then
    size=$((free/2))
fi
size="${size}k"
part_type="ntfs"
 
echo "Creating $size image..."

fallocate -l "$size" "$FILE"
dev="$(losetup -fL --show "$FILE")"
parted "$dev" mklabel msdos
parted "$dev" mkpart p "$part_type" 1M 100%

mkfs.ntfs -fL RPiHDD "${dev}p1"

losetup -d "$dev"
sync

mkdir -p /iso

echo "Done!"
reboot
