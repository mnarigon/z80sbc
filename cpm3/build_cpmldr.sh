#!/bin/sh
# -- build CPMLDR.COM

#
# -- copy scripts
cp scripts/cpmldr.sub      ../simh/CPMLDR.SUB
cp scripts/cpmldr.simh     ../simh/CPMLDR.SIMH

#
# -- copy LDRBIOS files
cp ldrbios3/ldrbios3.asm   ../simh/LDRBIOS3.ASM
cp ../zsbc-rom/zsbcrom.lib ../simh/ZSBCROM.LIB

#
# -- copy CP/M files
cp cpm_bld/CPMLDR.REL      ../simh/CPMLDR.REL
cp cpm_bld/CPM3.LIB        ../simh/CPM3.LIB
cp cpm_bld/MAKEDATE.LIB    ../simh/MAKEDATE.LIB
cp cpm_bld/Z80.LIB         ../simh/Z80.LIB

#
# -- run simulator to assemble and link CPMLDR
cd ../simh
cp hd.dsk.orig hd.dsk
altairz80 CPMLDR.SIMH

#
# -- move results
mv CPMLDR.COM ../cpm3/cpm_gen/CPMLDR.COM

#
# -- clean simh directory
rm -f CPMLDR.SUB
rm -f CPMLDR.SIMH
rm -f LDRBIOS3.ASM
rm -f ZSBCROM.LIB
rm -f CPMLDR.REL
rm -f CPM3.LIB
rm -f MAKEDATE.LIB
rm -f Z80.LIB

echo "CPMLDR.COM built"
exit 0
