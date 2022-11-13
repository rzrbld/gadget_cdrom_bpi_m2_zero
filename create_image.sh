#!/bin/bash -ue

auto=0
if [ "$#" -eq 1 ] && [ "$1" = "auto" ]; then
    auto=1
fi

FILE="/iso.img"

if [ -f "$FILE" ]; then
    if [ "$auto" -eq 0 ]; then
        echo "$FILE already exists" 1>&2
        exit 1
    fi
    exit 0
fi

if [ -f "/etc/init.d/resize2fs_once" ] && [ "$auto" -eq 1 ]; then # this is ugly hack :(
    echo "/etc/init.d/resize2fs_once exists" 2>&1
    exit 1
fi

size=0
if [ "$auto" -eq 0 ]; then
    free="$(df -h / | tail -n1 | awk '{print $4}')"
    echo -ne "Space available: $free\nSize, e.g. 16G? "
    read size
    echo -ne "Choose a filesystem (in HDD mode): ntfs, fat32 and exfat are supported? "
    read sel_fs_type
    echo -ne "Choose a partittion type: msdos and gpt are supported? "
    read sel_part_type
    echo -ne "Choose a partittion label: RPiHDD by default? "
    read part_label
else
    free="$(df -k / | tail -n1 | awk '{print $4}')"
    size=$(($free-(1024*1024*2)))
    if [ "$size" -lt "$((free/2))" ]; then
        size=$((free/2))
    fi
    size="${size}k"
    sel_fs_type="ntfs"
    sel_part_type="msdos"
    part_offset="1M"
    part_label="RPiHDD"
fi

if [ "$sel_fs_type" != "ntfs" ] && [ "$sel_fs_type" != "fat32" ] && [ "$sel_fs_type" != "exfat" ]; then
    echo "$sel_fs_type is not supported, choose ntfs or fat32" 1>&2
    exit 1
fi

if [ "$part_label" = "" ]; then
    part_label="RPiHDD"
fi

if [ "$sel_fs_type" = "exfat" ]; then
    #later we will convert it to exfat partition
    fs_type="ntfs" 
else
    fs_type=$sel_fs_type
fi

if [ "$sel_part_type" = "gpt" ]; then
    part_offset="2M"
else
    part_offset="1M"
fi
 
echo "Creating $size image..."

fallocate -l "$size" "$FILE"
dev="$(losetup -fL --show "$FILE")"
parted "$dev" mklabel "$sel_part_type"
parted "$dev" mkpart p "$fs_type" "$part_offset" 100%

if [ "$sel_fs_type" = "ntfs" ]; then
    mkfs.ntfs -fL "$part_label" "${dev}p1"
elif [ "$sel_fs_type" = "fat32" ]; then
    mkfs.vfat "${dev}p1"
    fatlabel "${dev}p1" "$part_label"
elif [ "$sel_fs_type" = "exfat"]; then 
    mkfs.exfat -n "$part_label" "${dev}p1"
else
    exit 1
fi

losetup -d "$dev"
sync

mkdir -p /iso

echo "Done!"
