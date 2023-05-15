	title 'Z80 SBC loader BIOS module for CP/M 3.0'
;;
;---------------------------------------
;
true	equ	-1
false	equ	not true
CR	equ	0DH
LF	equ	0AH

;;
;---------------------------------------
; libraries
;
maclib	Z80
maclib	cpm3
maclib	zsbcrom

;;
;---------------------------------------
; common segment
;
cseg

;;
;---------------------------------------
; CP/M 3.0 BIOS jump table
; * needs to be implemented in LDRBIOS
;
	jmp	boot			; * arrive here from cold start load
	jmp	wboot			;   arrive here for warm start
	jmp	const			;   return console input status
	jmp	conin			;   read console character
	jmp	conout			; * write console character
	jmp	list			;   write list character
	jmp	auxout			;   write aux character
	jmp	auxin			;   read aux character
	jmp	home			; * move to track zero on selected drive
	jmp	seldsk			; * select disk drive
	jmp	settrk			; * set track number
	jmp	setsec			; * set sector number
	jmp	setdma			; * set DMA address
	jmp	read			; * read selected sector
	jmp	write			;   write selected sector
	jmp	listst			;   return list device status
	jmp	sectrn			; * translate logical to physical sector number
	jmp	conost			;   return console output status
	jmp	auxist			;   return aux device input status
	jmp	auxost			;   return aux device output status
	jmp	devtbl			;   return address of character i/o table
	jmp	devini			;   init character i/o devices
	jmp	drvtbl			;   return address of disk drive table
	jmp	multio			;   set number of consec. sec. to read/write
	jmp	flush			;   flush user [de]blocking buffers
	jmp	move			; * copy memory to memory
	jmp	time			;   Signal Time and Date operation
	jmp	selmem			;   select memory bank
	jmp	setbnk			;   set bank for next DMA
	jmp	xmove			;   set banks for next move
	jmp	0			;   reserved for future expansion
	jmp	0			;   reserved for future expansion
	jmp	0			;   reserved for future expansion

;;
;---------------------------------------
; boot - get control from cold start loader and initialize system
; NOTE: there is only one word of stack available when called
;
boot:
	sspd	saved$sp
	lxi	sp,bios$stack		;load our stack

	lxi	h,signon$msg		;print signon message
	call	puts

	lspd	saved$sp		;restore stack
	ret

signon$msg:
	db	'Z80 SBC LDRBIOS Version 1.0',CR,LF,0

;;
;---------------------------------------
; conout - output character to console
; input
;   C - console character
;
conout:
	jmp	putc

;;
;---------------------------------------
; home - select track 0 of the specified drive
;
home:
	lxi	h,0
	shld	@trk
	ret

;;
;---------------------------------------
; seldsk - select the specified disk drive
; input
;   C - disk drive (0-15)
;   E - initial select flag
; return
;   HL - address of DPH if drive exists
;   HL - 0000H if the drive does not exist
;
seldsk:
	lxi	h,@dph0
	mov	a,c
	ora	a
	rz				;drive 0
	lxi	h,0
	ret

;;
;---------------------------------------
; settrk - set specified track number
; input
;   BC - track number
;
settrk:
	sbcd	@trk
	ret

;;
;---------------------------------------
; setsec - set specified sector number
; input
;   BC - sector number
;
setsec:
	sbcd	@sect
	ret

;;
;---------------------------------------
; setdma - set address for subsequent disk I/O
; input
;   BC - DMA address
;
setdma:
	sbcd	@dma
	ret

;;
;---------------------------------------
; read - read a sector from the specified drive
; return
;   A - 0 if no errors occured
;   A - 1 if nonrecoverable error condition occurred
;   A - 0FFH if media has changed
;
read:
	sspd	saved$sp
	lxi	sp,bios$stack		;load our stack

	lhld	@trk			;track in DE
	xchg
	lhld	@sect			;sector in C
	mov	c,l
	call	set$addr		;set track and sector
	jrnz	read0			;test status

	lhld	@dma			;DMA address
	call	ide$read		;call ROM disk read routine
	jrz	read1			;test status

read0:
	lxi	h,read$msg
	call	puts
	call	put$status		;call ROM output status routine
	xra	a			;report error
	inr	a

read1:
	lspd	saved$sp		;restore stack
	ret

read$msg:
	db	'LDRBIOS Read Error',CR,LF,0

;;
;---------------------------------------
; sectrn - translate sector number given translate table
; input
;   BC - logical sector number
;   DE - translate table address
; return
;   HL - physical sector number
;
sectrn:
	mov	l,c			;move BC to HL
	mov	h,b
	mov	a,d
	ora	e			;test translate table address
	rz				;return if zero
	xchg				;not zero, DE <-> HL
	dad	b			;add sector number to translate table address
	mov	l,m			;get table entry
	mvi	h,0			;clear high byte
	ret

;;
;---------------------------------------
; move - memory to memory block move
; input
;   HL - destination address
;   DE - source address
;   BC - count
; return
;   HL - point to next byte following move
;   DE - point to next byte following move
;
move:
	xchg				;swap source and dest
	ldir				;use Z80 block move instruction
	xchg				;swap back source and dest
	ret

;;
;---------------------------------------
; unimplemented
;
wboot:
const:
conin:
list:
auxout:
auxin:
write:
listst:
conost:
auxist:
auxost:
devtbl:
devini:
drvtbl:
multio:
flush:
time:
selmem:
setbnk:
xmove:
	ret

;;
;---------------------------------------
; BIOS stack
;
	dw	7676H,7676H,7676H,7676H,7676H,7676H,7676H,7676H
bios$stack:
saved$sp:
	dw	0

;;
;---------------------------------------
; disk transfer information
;
@dma	dw	0
@trk	dw	0
@sect	dw	0

;;
;---------------------------------------
; disk parameter header (DPH)
;   xlt:	logical to physical translate table address, 0 for no translation
;   mf:		media flag
;   dpb:	disk parameter block address
;   csv:	checksum vector address,
;		0 for drive permanently mounted,
;		0FFFEH for GENCPM assignment
;   alv:	allocation vector address,
;		0FFFEH for GENCPM assignment
;   dirbcb:	directory buffer control block address,
;		0FFFEH for GENCPM assignment
;   dtabcb:	data buffer control block address,
;		0FFFEH for GENCPM assignment,
;		0FFFFH to disable data buffer
;   hash:	directory hash table,
;		0FFFEH for GENCPM assignment,
;		0FFFFH to disable hashing
;   hbank:	hash table bank number
;
@dph0:
	dw	0			;xlt
	db	0,0,0,0,0,0,0,0,0	;scratch area
	db	0			;mf
	dw	@dpb0			;dpb
	dw	0			;csv
	dw	@alv0			;alv
	dw	@bcb0			;dirbcb
	dw	@bcb1			;dtabcb
	dw	0FFFFH			;hash
	db	0			;hbank

;;
;---------------------------------------
; disk parameter block (DPB)
; 512 byte physical sector size
; 64 physical sectors per track
; 512 tracks per drive
; 8192 allocation block size
; 4096 directory entries
;
; virtual partitioning:
;   track 0: system
;   track 1-512:     Drive A 16MB
;   track 513-1024:  Drive B 16MB
;   track 1025-1536: Drive C 16MB
;   track 1537-2048: Drive D 16MB
;
;   spt:	logical records per track
;   bsh:	block shift factor
;   blm:	block mask
;   exm:	extent mask
;   dsm:	total storage capacity
;   drm:	total number of directory entries minus 1
;   al0,al1:	determine reserved directory blocks
;   cks:	size of directory check vector
;   off:	number of reserved tracks
;   psh:	physical record shift factor
;   phm:	physical record mask
;
;   spt = 512/128*64
;   dsm = (512*64*512/8192)-1
;   drm = (8192/32*16)-1
;   al0/al1
;     4096 directory entries
;     128 directory entries per block
;     16 reserved blocks -> al0 = 0FFH, al1 = 0FFH
;   cks = 8000H, drive is permanently mounted and
;     checksumming is not required
;
@dpb0:
	dw	256			;spt
	db	6			;bsh
	db	3FH			;blm
	db	3			;exm
	dw	2047			;dsm
	dw	4095			;drm
	db	0FFH			;al0
	db	0FFH			;al1
	dw	8000H			;cks
	dw	1			;off
	db	2			;psh
	db	3			;phm

;;
;---------------------------------------
; directory buffer control block (BCB)
;
@bcb0:
	db	0FFH			;drv
	db	0,0,0			;recn
	db	0			;wflg
	db	0
	dw	0			;track
	dw	0			;sector
	dw	@buff0			;buffad
	db	0			;bank
	dw	0			;link

;;
;---------------------------------------
; data buffer control block (BCB)
;
@bcb1:
	db	0FFH			;drv
	db	0,0,0			;recn
	db	0			;wflg
	db	0
	dw	0			;track
	dw	0			;sector
	dw	@buff1			;buffad
	db	0			;bank
	dw	0			;link

;;
;---------------------------------------
; disk buffers
;
@buff0:
	ds	512
@buff1:
	ds	512

;;
;---------------------------------------
; allocation vector
;   len(alv) = (drm/4) + 2
;
@alv0:
	ds	1025

	end
