#!/bin/sh
# -- clean project
rm -f cf_banked.img
rm -f cf_unbanked.img
rm -f zsbc-rom.hex

cd cpm3
rm -f cf_banked.img
rm -f cf_unbanked.img
cd ..

cd cpm3/cpm_gen
rm -f CPM3_BANKED.SYS
rm -f CPM3_UNBANKED.SYS
rm -f CPMLDR.COM
cd ../..

cd simh
rm -f i.dsk
cd ..

cd zsbc-rom
rm -f zsbc-rom.hex
rm -f zsbc-rom.lst
cd ..

echo "Done"
exit 0
