#!/bin/sh
# -- build zsbc-rom.hex, CPMLDR.COM, CPM.SYS, and cf_banked.img/cf_unbanked.img
if [ ! -f zsbc-rom.hex ]; then
    echo "build zsbc-rom.hex"
    cd zsbc-rom
    ./build.sh
    cp zsbc-rom.hex ..
    cd ..
fi

if [ ! -f cpm3/cpm_gen/CPMLDR.COM ]; then
    echo "build cpmldr"
    cd cpm3
    ./build_cpmldr.sh
    cd ..
fi

echo "build CP/M 3.0"
cd cpm3
./build_cpm.sh "$1"
./build_image.sh "$1"
if [ "$1" = "unbanked" ]; then
    cp cf_unbanked.img ..
else
    cp cf_banked.img ..
fi
cd ..

echo "Done"
exit 0
