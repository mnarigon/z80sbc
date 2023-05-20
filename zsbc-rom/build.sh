#!/bin/sh
# -- build zsbc-rom.z80

#
# -- copy scripts into simh directory
cp scripts/zsbc-rom.sub ../simh/ZSBC-ROM.SUB
cp scripts/zsbc-rom.simh ../simh/ZSBC-ROM.SIMH

#
# -- copy source
cp zsbc-rom.z80 ../simh/ZSBC-ROM.Z80

#
# -- run simulator
cd ../simh
altairz80 ZSBC-ROM.SIMH

#
# -- move results back into zsbc-mon directory
mv ZSBC-ROM.HEX ../zsbc-rom/zsbc-rom.hex
mv ZSBC-ROM.LST ../zsbc-rom/zsbc-rom.lst

#
# -- clean simh directory
rm ZSBC-ROM.SUB
rm ZSBC-ROM.SIMH
rm ZSBC-ROM.Z80

echo "ZSBC-ROM.HEX built"
exit 0
