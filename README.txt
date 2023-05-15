0. This a Z80 SBC EPROM monitor and CP/M 3 BIOS/LDRBIOS to get started
with CP/M 3 on John Monahan's Single Board Computer Z80 CPU board for S-100
bus systems.

1. Introduction.

This software is used to generate a banked CP/M 3 installation consisting of
ROM and Compact Flash card images that are tailored for John Monahan's Single
Board Computer Z80 CPU board for S-100 bus systems.

The details of this board are found at:
http://www.s100computers.com/My%20System%20Pages/SBC%20Z80%20Board/SBC%20Z80%20CPU%20Board.htm
Thanks very much to John for making these systems available.

Monitor and BIOS/LDRBIOS unique features:
The Z80 SBC board is the only board required for a complete CP/M 3 system.
New 4K ROM monitor and build scripts.
  - ROM contains the majority of the CP/M BIOS routines.
  - Includes general monitor functions for board/system bring up.
New CP/M 3 LDRBIOS, BIOS, and build scripts.
  - Banked CP/M 3 system with a 57K TPA.
  - CCP.COM on system track and buffered in banked memory.
  - Supports four 16MB drives on a single 128MB Compact Flash card.
  - A basic CP/M 3 distribution installed on Drive A: User 0. Additional
    files can be loaded on the image.
Uses a rewritten IDE driver that includes IDE spec timing for reset pulse
generation and ready states.
Uses Logical Block Addressing (LBA) with 64 sectors per track.
Extensive IDE controller error checking and status reporting.

2. Installation.

This software is developed on a macOS system. I have tested the scripts on a
Linux Mint distribution and they are likely to work on other Linux
distributions. The scripts currently don't support Windows systems.
Patches/pull requests are welcome.

The ROM monitor is written in SLR Systems Z80ASM assembler.

The LDRBIOS/BIOS files are written for Digital Research RMAC and LINK.

All three use Z80 instructions with the LDRBIOS/BIOS files using Z80.LIB macros.

This software relies on two tools not provided in this repository.

The first tool is cpmtools-2.23, developed by Michael Haart. It is available at:
http://www.moria.de/~michael/cpmtools.

cpmtools-2.23 should be installed to your system (/usr/local/bin) and available
in your PATH.

The diskdef for the Compact Flash card format used by this software is located
at cpm3/scripts/z80sbc-cf.diskdef and should be installed in
/usr/local/share/diskdefs.

The second tool is the Altair Z80 SIMH simulator, developed by Peter Schorn. It
is available at: https://schorn.ch/altair.html. This tool is used to
cross-assemble the ROM monitor and to cross-assemble/cross-link/cross-gencpm
the CP/M 3 system.

Download the 'Altair Z80 CP/M Version 3 with banked memory' version from Peter's
web site and build. The resulting altairz80 executable should be installed to
your system (/usr/local/bin) and available in your PATH.
In the simh directory in this repository include the altairz80 cpm3.dsk disk
image, and copy the altairz80 i.dsk image to i.dsk.orig (the build scripts
start from fresh by copying i.dsk.orig to i.dsk to remove any changes before
each run). If you want to manually run the simulator, also copy the cpm3 script.

3. Building.

Running ./build.sh in the top-level directory of the repository builds
zsbc-rom.hex, CPMLDR.COM, and CPM3.SYS. It then creates the file cf_banked.img,
which is a Compact Flash image file containing the CP/M 3 Drive A image.

If you run './build.sh unbanked' the script will produce the file
cf_unbanked.img, an unbanked CP/M 3 Drive A image.

Running ./clean.sh in top-level directory of the repository removes all the
build products.

To cross-assemble a file in the build scripts, the Altair Z80 simulator is
started with a script file that configures the simulator, and then reads and 
submits a CP/M script using SIMH features to interpret output and provide
input to the simulator. Because the script does not provide feedback on its
success or failure you should review the output to ensure each script
executed successfully.

For the Drive A disk image, additional files can be installed in cpm3/cpm_src
and they will be copied to the disk image.
Each directory in cpm3/cpm_src is by user, e.g., 0/, 1/, etc., for user 0,
user 1, etc., on Drive A:.

Thanks to the ZSOS distribution at
https://www.retrobrewcomputers.org/doku.php?id=software:firmwareos:zsos:start
for the ideas on how to create the disk image.

4. Hardware Configuration.

4A. ROM

The Z80 SBC uses an M27C64A 150ns (8K byte) EPROM for its boot rom. The board
manages the EPROM as two 4K pages. I configured the board (see section 4C)
so that the lower page of the EPROM is mapped to 0F000H in the Z80 memory
space. The upper page of the EPROM is unused.

I use a Lumitech UV EPROM eraser to erase the EPROM prior to programming.

I use a TL866CS programmer with the MiniPro v6.85 programming software to
program the .hex file generated in section 3 (zsbc-rom.hex) into the M27C64A.

In the MiniPro software the 'IC selected' is 'M27C64A @DIP28'.

When opening the .hex file set the 'From File Start Addr' to 0F000 and leave
everything else the default.

The programming options I select are 'Verify After', 'Skip 0xFF', and
'Blank Check', and I deselect 'Check ID', and 'Auto SN_NUM'.

4B. Compact Flash Card

I use no-name 128MB Compact Flash cards.

Running 'sudo ./format_cf.sh device' formats a Compact Flash card for CP/M by
filling the card with 0E5H (the value for an empty directory entry).

The Compact Flash device name for the format_cf.sh command can be found on
macOS by running 'diskutil list' and looking for the card. For linux you can
run 'ls /dev/sd*' before and after pluggin in the card adapter. Use the root
device, e.g., /dev/sde, /dev/sdf, etc., rather than /dev/sde1.

Note that currently there is no error checking to ensure you select the
compact flash card so make sure you get this right.

Format the card before imaging so that the B, C,and D drives are initialized.

Running 'sudo ./image_cf.sh device file' creates a CP/M 3 filesystem image
file, writes the system track with CPMLDR.COM and CCP.COM, and copies the
files in cpm3/cpm_src to the image.

4C. Board Jumpers

Here is the complete list of switches/jumpers on the v1.1A Z80 SBC board with
a 4MHz processor oscillator as used with the above software.

IDE to CF Adapter
  JP1 - 2-3 - power source selection - pin 20 IDE connector
  JP2 - 1-2 - voltage selection - 5V
  JP3 - 1-2 - mode selection - single

Z80 SBC Switches
  Base Port   - CCOOCCCC (030H) Left to right, C - closed, O - open
  IOBYTE Port - CCCCCCCC (00H)

Z80 SBC Jumpers
  JP1  - jumpered - pin 20 GND
  JP2  - jumpered - pin 53 GND
  JP3  - jumpered - pin 70 GND
  JP4  - jumpered - power on POC* assert enabled
  JP5  - jumpered - power on board reset enabled
  JP6  - jumpered - power on SLAVE_CLR* assert enabled
  JP7  - jumpered - power on RESET* assert enabled
  JP8  - 1-2      - onboard ROM A11 tie to A11
  JP9  - open     - onboard ROM U13-25 open
  JP10 - jumpered - onboard ROM enable
  K1   - 2-3      - NMI* source NMI*
  K2   - 2-3      - Z80 will relinquish on bus request
  K101 - 1-2      - temporary master controls address lines
  K102 - 2-3      - IDE drive select tied to VCC
  K103 - 1-2      - onboard RAM enable
  K105 - 2-3      - onboard RAM page select enable
  K106 - 2-3      - onboard RAM enable
  K107 - 1-2      - S100 data bus input enable
  P3   - open     - Power on Jump (POJ) address 0F000H
  P4   - 1-2, 3-4 - Z80 generates bus master clock, Z80 generates bus MWRT
  P8/P9/P10 - P8-1/4 to P10-1/4 - onboard ROM range 0F000H-0FFFFH
  P36  - open     - no memory wait
  P37  - 1-2      - enable partial latch
  P101 - 1-2      - onboard ROM A12 tied to page select
  P104 - jumpered - IDE power tied to VCC
  P112 - open     - no memory wait states
  P113 - open     - no ROM wait states
  P114 - open     - no I/O wait states

In particular the POJ and ROM base address is set to 0F000H, and banked ROM
operation is enabled with the default page 0 of the ROM selected on
power on.

Note that there are delay functions in the monitor that are tuned to a 4 MHz
clock, so if you use a different clock you will have to modify these delay
functions.
  
5. Monitor

The monitor implements the following operations useful for bringing up a
new Z80 SBC board. For a quick start, the 'H' command will display help and
the 'B' command will boot into CP/M from the Compact Flash card.

The monitor has simple line editing with backspace/delete to erase the current
character and control-U to erase the current line. For long output control-S/
control-Q will pause and resume output. Either upper or lower case is
accepted.

The monitor accepts only hexadecimal numbers. So, for example, to read a
single disk sector from track 27, sector 42 and store it at memory address
0100H the command is:
  DR 0100,1,1B,2A<ret>

The ML command can be used to 'paste' an Intel hex format input file into
memory. Upon entering the ML command, the monitor reads and processes Intel
hex records until an end of file record or control-C is received.

I use 'putty', https://putty.org, as the terminal emulator for the Z80 SBC
USB serial port on the Windows machine I use to interface to my S-100 bus
systems.

Monitor commands:
  B - boot from disk
  H - display this help

  CB bank - select ROM/RAM bank
  CD - test delay function
  CI - display IOBYTE
  CJ address - jump to address

  DI - reset disk controller
  DR address,count,track,sector - read disk sector
  DS - display controller and disk status
  DW address,count,track,sector - write disk sector

  MD start,end - display memory contents
  ME address - edit memory contents, +, -, value, RET to end
  MF start,end,data - fill memory
  ML - load memory from Intel hex format input
  MM start,end,destination - move memory
  MS - scan memory and display (RAM/ROM/none)

  PI port - input from selected port
  PO port,data - output to selected port
  PS - scan ports for activity
