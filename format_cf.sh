#!/bin/sh
# -- format a Compact Flash Card
#
blocksize=512

# -- output a prompt and return true or false
confirm() {
    printf "${1:-Are you sure? [y/N]} "
    read response
    case "$response" in
        [yY][eE][sS]|[yY])
            true
            ;;
        *)
            false
            ;;
    esac
}

# -- report the device size in blocks to stdout
device_size() {
    device=$1
    size=0
    offset=0
    incr=65536

    while true; do
        read=$(dd if=$device bs=$blocksize skip=$offset count=1 2>/dev/null | wc -c)
        if [ "$read" -ne "$blocksize" ]; then
            offset=$size
            incr=$(expr $incr / 2)
            if [ "$incr" -eq 0 ]; then
                size=$(expr $size + 1)
                printf $size
                return
            fi
        else
            size=$offset
        fi
        offset=$(expr $offset + $incr)
    done
}

# -- generate a blank sector on stdout
blank_sector() {
    i=0
    while [ "$i" -ne "$blocksize" ]; do
        printf "\345"
        i=$(expr $i + 1)
    done
}

# -- generate count blank sectors on stdout
# -- output breadcrumbs to stderr
blank_sectors() {
    count=$1
    sector=$(blank_sector)
    i=0
    while [ "$i" -ne "$count" ]; do
        p=$(expr $i % 8192)
        if [ "$p" -eq 0 ]; then
            printf "." 1>&2
        fi
        printf $sector 2>/dev/null || exit 1
        i=$(expr $i + 1)
    done
}

disk=$1
if [ -z "$disk" ]; then
    echo "usage: format_cf disk"
    exit 1
fi

if [ "${EUID:-$(id -u)}" -ne 0 ]; then
    echo "please run as root"
    exit 1
fi

# -- confirmation
echo "Verify Compact Flash Card is at $disk"
echo "Formatting will fill the card with 0E5H and can take a several minutes"
confirm "Are you ready to format? [y/N]" || exit 0

# -- fill card with blank sectors
nblocks=$(device_size "$disk")
echo "Formatting $nblocks blocks on $disk"
blank_sectors "$nblocks" | dd of=$disk 2>/dev/null || exit 1

echo " "
echo "Format complete"
exit 0
