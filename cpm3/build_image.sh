#!/bin/sh
# -- make a (banked/unbanked) CP/M 3 image for a Compact Flash Card
#

# -- print the file size in bytes to stdout
file_size() {
    os=$(echo "$OSTYPE" | cut -c 1-6)
    if [ "$os" = "darwin" ]; then
        /usr/bin/stat -f "%z" "$1"
    else
        /usr/bin/stat -c "%s" "$1"
    fi
}

banked="yes"
if [ "$1" = "unbanked" ]; then
    banked=""
fi

if [ -n "$banked" ]; then
    echo "building banked CP/M 3 image for a Compact Flash Card"
    image="cf_banked.img"
else
    echo "building unbanked CP/M 3 image for a Compact Flash Card"
    image="cf_unbanked.img"
fi

s0=$(file_size cpm_gen/CPMLDR.COM)
t0=$(expr $s0 + 511)
t0=$(expr $t0 / 512)
echo "CPMLDR.COM is $s0 bytes ($t0 sectors) at track 0, sector 0"

s1=$(file_size cpm_src/0/CCP.COM)
t1=$(expr $s1 + 511)
t1=$(expr $t1 / 512)
echo "CCP.COM is $s1 bytes ($t1 sectors) at track 0, sector $t0"
echo "verify sizes in cpm3/bios/boot3.asm and zsbc-rom/zsbc-rom.z80"

# -- make the image with CPMLDR.COM and CCP.COM on the boot tracks
rm -f "$image"
mkfs.cpm -f z80sbc-cf -b cpm_gen/CPMLDR.COM -b cpm_src/0/CCP.COM "$image" || exit 1

# -- copy the CPM.SYS generated file
if [ -n "$banked" ]; then
    cpmcp -f z80sbc-cf "$image" cpm_gen/CPM3_BANKED.SYS 0:cpm3.sys || exit 1
else
    cpmcp -f z80sbc-cf "$image" cpm_gen/CPM3_UNBANKED.SYS 0:cpm3.sys || exit 1
fi

# -- copy the CP/M source files
userareas="0 1 2 3 4 5 6 7 8 9"
for user in $userareas; do
    for file in "cpm_src/$user/"*; do
        if [ -f "$file" ]; then
            cpmcp -f z80sbc-cf "$image" "$file" "$user:" || exit 1
        fi
    done
done

if [ -n "$banked" ]; then
    echo "banked image $image built"
else
    echo "unbanked image $image built"
fi
exit 0
