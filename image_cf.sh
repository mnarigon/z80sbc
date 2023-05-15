#!/bin/sh
# -- load a CP/M disk image to a Compact Flash Card
#
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

disk=$1
image=$2
if [ -z "$disk" -o -z "$image" ]; then
    echo "usage: image_cf disk image"
    exit 1
fi

if [ "${EUID:-$(id -u)}" -ne 0 ]; then
    echo "please run as root"
    exit 1
fi

echo "Verify Compact Flash Card is at $disk and image file is $image"
confirm "Are you ready to load image? [y/N]" || exit 0

# -- load image
dd "if=$image" "of=$disk" 2>/dev/null || exit 1

echo "Image complete"
exit 0
