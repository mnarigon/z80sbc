#!/bin/sh
# -- build CP/M 3.0 (banked/unbanked)
banked="yes"
if [ "$1" = "unbanked" ]; then
    banked=""
fi

if [ -n "$banked" ]; then
    echo "building banked CPM.SYS"
else
    echo "building unbanked CPM.SYS"
fi

#
# -- copy scripts
if [ -n "$banked" ]; then
    cp scripts/cpm_banked.sub ../simh/CPM.SUB
else
    cp scripts/cpm_unbanked.sub ../simh/CPM.SUB
fi
cp scripts/cpm.simh ../simh/CPM.SIMH

#
# -- copy BIOS files
if [ -n "$banked" ]; then
    sed -E 's/^(BANKED[[:space:]]+equ[[:space:]]+)(true|false)/\1true/' bios3/kernel3.asm > ../simh/KERNEL3.ASM
    sed -E 's/^(BANKED[[:space:]]+equ[[:space:]]+)(true|false)/\1true/' bios3/move3.asm > ../simh/MOVE3.ASM
else
    sed -E 's/^(BANKED[[:space:]]+equ[[:space:]]+)(true|false)/\1false/' bios3/kernel3.asm > ../simh/KERNEL3.ASM
    sed -E 's/^(BANKED[[:space:]]+equ[[:space:]]+)(true|false)/\1false/' bios3/move3.asm > ../simh/MOVE3.ASM
fi
cp bios3/boot3.asm   ../simh/BOOT3.ASM
cp bios3/chario3.asm ../simh/CHARIO3.ASM
cp bios3/diskio3.asm ../simh/DISKIO3.ASM
cp bios3/drvtbl3.asm ../simh/DRVTBL3.ASM
cp bios3/scb3.asm    ../simh/SCB3.ASM

cp ../zsbc-rom/zsbcrom.lib ../simh/ZSBCROM.LIB

#
# -- copy CP/M files
if [ -n "$banked" ]; then
    cp cpm_gen/gencpm_banked.dat ../simh/GENCPM.DAT
else
    cp cpm_gen/gencpm_unbanked.dat ../simh/GENCPM.DAT
fi
cp cpm_bld/BNKBDOS3.SPR ../simh/BNKBDOS3.SPR
cp cpm_bld/RESBDOS3.SPR ../simh/RESBDOS3.SPR
cp cpm_bld/BDOS3.SPR    ../simh/BDOS3.SPR
cp cpm_bld/CPM3.LIB     ../simh/CPM3.LIB
cp cpm_bld/MAKEDATE.LIB ../simh/MAKEDATE.LIB
cp cpm_bld/MODEBAUD.LIB ../simh/MODEBAUD.LIB
cp cpm_bld/Z80.LIB      ../simh/Z80.LIB

#
# -- run simulator to assemble, link, and sysgen CP/M
cd ../simh
cp hd.dsk.orig hd.dsk
altairz80 CPM.SIMH

#
# -- move results
if [ -n "$banked" ]; then
    mv CPM3.SYS ../cpm3/cpm_gen/CPM3_BANKED.SYS
else
    mv CPM3.SYS ../cpm3/cpm_gen/CPM3_UNBANKED.SYS
fi

#
# -- clean simh directory
rm -f CPM.SUB
rm -f CPM.SIMH
rm -f BOOT3.ASM
rm -f CHARIO3.ASM
rm -f DISKIO3.ASM
rm -f DRVTBL3.ASM
rm -f KERNEL3.ASM
rm -f MOVE3.ASM
rm -f SCB3.ASM
rm -f ZSBCROM.LIB
rm -f GENCPM.DAT
rm -f BDOS3.SPR
rm -f BNKBDOS3.SPR
rm -f RESBDOS3.SPR
rm -f CPM3.LIB
rm -f MAKEDATE.LIB
rm -f MODEBAUD.LIB
rm -f Z80.LIB

if [ -n "$banked" ]; then
    echo "banked CPM.SYS built"
else
    echo "unbanked CPM.SYS built"
fi
exit 0
