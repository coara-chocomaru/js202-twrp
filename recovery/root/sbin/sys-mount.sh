#!/sbin/sh
PATH=/sbin:/system/bin:/system/xbin:/vendor/bin:/usr/bin:/bin
export PATH
umask 022
LOG=/tmp/mount_system_root.log
: > "$LOG" 2>/dev/null
exec >>"$LOG" 2>&1

is_mounted() {
    grep -q ' /system_root ' /proc/mounts 2>/dev/null
}

mkdir -p /dev/block/by-name
if [ -e /system_root ] && [ ! -d /system_root ]; then
    rm -f /system_root
fi
mkdir -p /system_root

if [ ! -x /sbin/mount ]; then
    if [ -x /system/bin/mount ]; then
        ln -sf /system/bin/mount /sbin/mount
    elif [ -x /system/bin/toybox ]; then
        ln -sf /system/bin/toybox /sbin/mount
    elif [ -x /sbin/toybox ]; then
        ln -sf /sbin/toybox /sbin/mount
    elif [ -x /sbin/busybox ]; then
        ln -sf /sbin/busybox /sbin/mount
    fi
fi

SLOT=""
set -- $(cat /proc/cmdline 2>/dev/null)
for x in "$@"; do
    case "$x" in
        androidboot.slot_suffix=*) SLOT="${x#androidboot.slot_suffix=}" ;;
        androidboot.slot=*) SLOT="_${x#androidboot.slot=}" ;;
    esac
done

if [ -z "$SLOT" ]; then
    if command -v getprop >/dev/null 2>&1; then
        SLOT=$(getprop ro.boot.slot_suffix 2>/dev/null)
        if [ -z "$SLOT" ]; then
            SLOT=$(getprop ro.boot.slot 2>/dev/null)
            [ -n "$SLOT" ] && SLOT="_$SLOT"
        fi
    fi
fi

for d in /system_root /system; do
    if grep -q " $d " /proc/mounts 2>/dev/null; then
        umount "$d" 2>/dev/null
        if grep -q " $d " /proc/mounts 2>/dev/null; then
            umount -l "$d" 2>/dev/null
        fi
    fi
done

if [ ! -e /dev/block/by-name/system ] && [ -n "$SLOT" ]; then
    for d in /dev/block/by-name/system$SLOT /dev/block/bootdevice/by-name/system$SLOT /dev/block/platform/*/by-name/system$SLOT /dev/block/platform/*/*/by-name/system$SLOT /dev/block/platform/*/*/*/by-name/system$SLOT; do
        if [ -e "$d" ]; then
            ln -sf "$d" /dev/block/by-name/system
            break
        fi
    done
fi

if [ ! -e /dev/block/by-name/system ]; then
    for d in /dev/block/by-name/system /dev/block/bootdevice/by-name/system /dev/block/platform/*/by-name/system /dev/block/platform/*/*/by-name/system /dev/block/platform/*/*/*/by-name/system /dev/block/platform/*/*/*/*/by-name/system; do
        if [ -e "$d" ]; then
            ln -sf "$d" /dev/block/by-name/system
            break
        fi
    done
fi

if [ ! -e /dev/block/by-name/system ]; then
    for d in /dev/block/by-name/system_a /dev/block/by-name/system_b /dev/block/bootdevice/by-name/system_a /dev/block/bootdevice/by-name/system_b /dev/block/platform/*/by-name/system_a /dev/block/platform/*/by-name/system_b /dev/block/platform/*/*/by-name/system_a /dev/block/platform/*/*/by-name/system_b /dev/block/platform/*/*/*/by-name/system_a /dev/block/platform/*/*/*/by-name/system_b; do
        if [ -e "$d" ]; then
            ln -sf "$d" /dev/block/by-name/system
            break
        fi
    done
fi

if [ ! -e /dev/block/by-name/system ]; then
    for d in $(find /dev/block -type l -name 'system*' 2>/dev/null); do
        [ -e "$d" ] || continue
        case "$d" in
            */by-name/system|*/by-name/system_a|*/by-name/system_b)
                ln -sf "$d" /dev/block/by-name/system
                break
                ;;
        esac
    done
fi

if [ ! -e /dev/block/by-name/system ]; then
    for d in $(find /dev/block -type b -name 'system*' 2>/dev/null); do
        [ -e "$d" ] || continue
        case "$d" in
            */system|*/system_a|*/system_b)
                ln -sf "$d" /dev/block/by-name/system
                break
                ;;
        esac
    done
fi

if [ ! -e /dev/block/by-name/system ]; then
    for d in /dev/block/mmcblk*/by-name/system /dev/block/sd*/by-name/system /dev/block/mmcblk*/system /dev/block/sd*/system; do
        if [ -e "$d" ]; then
            ln -sf "$d" /dev/block/by-name/system
            break
        fi
    done
fi

if [ ! -e /dev/block/by-name/system ]; then
    for d in /dev/block/mapper/system /dev/block/mapper/system_a /dev/block/mapper/system_b; do
        if [ -e "$d" ]; then
            ln -sf "$d" /dev/block/by-name/system
            break
        fi
    done
fi

if [ ! -e /dev/block/by-name/system ]; then
    exit 1
fi

if [ -x /sbin/blockdev ]; then
    /sbin/blockdev --setrw /dev/block/by-name/system >/dev/null 2>&1
fi

if [ -x /system/bin/blockdev ]; then
    /system/bin/blockdev --setrw /dev/block/by-name/system >/dev/null 2>&1
fi

if [ -x /sbin/toybox ]; then
    /sbin/toybox blockdev --setrw /dev/block/by-name/system >/dev/null 2>&1
fi

if [ -x /sbin/busybox ]; then
    /sbin/busybox blockdev --setrw /dev/block/by-name/system >/dev/null 2>&1
fi

try_mount() {
    "$@" >/dev/null 2>&1
    is_mounted
}

for i in 1 2 3 4 5; do
    sync
    if try_mount /sbin/mount -t ext4 -o rw /dev/block/by-name/system /system_root; then
        break
    fi
    sleep 1
done

if ! is_mounted; then
    try_mount /sbin/mount -t ext4 -o rw,remount /dev/block/by-name/system /system_root
fi

if ! is_mounted; then
    try_mount /sbin/mount -o rw /dev/block/by-name/system /system_root
fi

if ! is_mounted; then
    try_mount /sbin/mount -t auto -o rw /dev/block/by-name/system /system_root
fi

if ! is_mounted; then
    try_mount /sbin/mount -t ext4 -o rw,noatime,barrier=1 /dev/block/by-name/system /system_root
fi

if ! is_mounted; then
    try_mount /sbin/mount -t ext4 -o rw,nodelalloc,noauto_da_alloc /dev/block/by-name/system /system_root
fi

if ! is_mounted; then
    try_mount /sbin/mount -w /dev/block/by-name/system /system_root
fi

if ! is_mounted && [ -x /system/bin/toybox ]; then
    try_mount /system/bin/toybox mount -t ext4 -o rw /dev/block/by-name/system /system_root
fi

if ! is_mounted && [ -x /system/bin/toybox ]; then
    try_mount /system/bin/toybox mount -o rw /dev/block/by-name/system /system_root
fi

if ! is_mounted && [ -x /sbin/toybox ]; then
    try_mount /sbin/toybox mount -t ext4 -o rw /dev/block/by-name/system /system_root
fi

if ! is_mounted && [ -x /sbin/toybox ]; then
    try_mount /sbin/toybox mount -o rw /dev/block/by-name/system /system_root
fi

if ! is_mounted && [ -x /sbin/busybox ]; then
    try_mount /sbin/busybox mount -t ext4 -o rw /dev/block/by-name/system /system_root
fi

if ! is_mounted && [ -x /sbin/busybox ]; then
    try_mount /sbin/busybox mount -o rw /dev/block/by-name/system /system_root
fi

if ! is_mounted && [ -x /system/bin/busybox ]; then
    try_mount /system/bin/busybox mount -t ext4 -o rw /dev/block/by-name/system /system_root
fi

if ! is_mounted && [ -x /system/bin/busybox ]; then
    try_mount /system/bin/busybox mount -o rw /dev/block/by-name/system /system_root
fi

if ! is_mounted && [ -x /sbin/e2fsck ]; then
    /sbin/e2fsck -p -f /dev/block/by-name/system >/dev/null 2>&1
    try_mount /sbin/mount -t ext4 -o rw /dev/block/by-name/system /system_root
fi

if ! is_mounted && [ -x /system/bin/e2fsck ]; then
    /system/bin/e2fsck -p -f /dev/block/by-name/system >/dev/null 2>&1
    try_mount /sbin/mount -t ext4 -o rw /dev/block/by-name/system /system_root
fi

if ! is_mounted && [ -x /sbin/fsck.ext4 ]; then
    /sbin/fsck.ext4 -p -f /dev/block/by-name/system >/dev/null 2>&1
    try_mount /sbin/mount -t ext4 -o rw /dev/block/by-name/system /system_root
fi

if ! is_mounted && [ -x /system/bin/fsck.ext4 ]; then
    /system/bin/fsck.ext4 -p -f /dev/block/by-name/system >/dev/null 2>&1
    try_mount /sbin/mount -t ext4 -o rw /dev/block/by-name/system /system_root
fi

if is_mounted; then
    /sbin/mount -o rw,remount /system_root >/dev/null 2>&1
    /sbin/mount -o rw,remount /dev/block/by-name/system /system_root >/dev/null 2>&1
    exit 0
fi

exit 1