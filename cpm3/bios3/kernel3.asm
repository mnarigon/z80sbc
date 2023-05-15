	title	'Z80 SBC kernel module for CP/M 3.0'
;;
;---------------------------------------
; Copyright (C), 1982
; Digital Research, Inc
; P.O. Box 579
; Pacific Grove, CA  93950
;
true	equ	-1
false	equ	not true
CR	equ	0DH
LF	equ	0AH
ctrlQ	equ	11H
ctrlS	equ	13H
ccp	equ	0100h		;Console Command Processor load address

;;
;---------------------------------------
; build flags
; banked - true if a banked system
;
BANKED	equ	true

;;
;---------------------------------------
; libraries
;
maclib	modebaud
maclib	zsbcrom

;;
;---------------------------------------
; external CP/M references
;

;;
;---------------------------------------
; initialization - boot loader module
;
extrn	?init				;general initialization and signon
extrn	?ldccp				;load CCP for BOOT
extrn	?rlccp				;reload CCP for WBOOT

;;
;---------------------------------------
; clock support - boot loader module
;
extrn	?time				;time operation

;;
;---------------------------------------
; character I/O routines - character I/O module
;
extrn	@ctbl				;physical character device table
extrn	?cinit				;(re)initialize device in C
extrn	?ci				;each take device in B
extrn	?co
extrn	?cist
extrn	?cost

;;
;---------------------------------------
; memory control - memory select and move module
;
public	@cbnk				;current bank
extrn	?xmove				;select move bank
extrn	?move				;block move
extrn	?bank				;select CPU bank

;;
;---------------------------------------
; system control block - system control block definition module
;
extrn	@covec				;I/O redirection vectors
extrn	@civec
extrn	@aovec
extrn	@aivec
extrn	@lovec
extrn	@mxtpa				;addr of system entry point
extrn	@bnkbf				;128 byte scratch buffer

;;
;---------------------------------------
; disk communication data items
;
extrn   @dtbl				;table of pointers to XDPHs
public	@adrv				;parameters for disk I/O
public	@rdrv
public	@trk
public	@sect
public	@dma
public	@dbnk
public	@cnt

;;
;---------------------------------------
; general utility routines
;
public	?pmsg				;print message
public	?pdec				;print number from 0 to 65535
public	?pderr				;print BIOS disk error message header

;;
;---------------------------------------
; external names for BIOS entry points
;
public	?boot
public	?wboot
public	?const
public	?conin
public	?cono
public	?list
public	?auxo
public	?auxi
public	?home
public	?sldsk
public	?sttrk
public	?stsec
public	?stdma
public	?read
public	?write
public	?lists
public	?sctrn
public	?conos
public	?auxis
public	?auxos
public	?dvtbl
public	?devin
public	?drtbl
public	?mltio
public	?flush
public	?mov
public	?tim
public	?bnksl
public	?stbnk
public	?xmov

;;
;---------------------------------------
; common segment
;
cseg

;;
;---------------------------------------
; BIOS Jump vector
; All BIOS routines are invoked by calling these entry points
;
?boot:	jmp	boot			;initial entry on cold start
?wboot:	jmp	wboot			;reentry on program exit, warm start

?const:	jmp	const			;return console input status
?conin:	jmp	conin			;return console input character
?cono:	jmp	conout			;send console output character
?list:	jmp	list			;send list output character
?auxo:	jmp	auxout			;send auxilliary output character
?auxi:	jmp	auxin			;return auxilliary input character

?home:	jmp	home			;set disks to logical home
?sldsk:	jmp	seldsk			;select disk drive, return disk parameter info
?sttrk:	jmp	settrk			;set disk track
?stsec:	jmp	setsec			;set disk sector
?stdma:	jmp	setdma			;set disk I/O memory address
?read:	jmp	read			;read physical block(s)
?write:	jmp	write			;write physical block(s)

?lists:	jmp	listst			;return list device status
?sctrn:	jmp	sectrn			;translate logical to physical sector

?conos:	jmp	conost			;return console output status
?auxis:	jmp	auxist			;return aux input status
?auxos:	jmp	auxost			;return aux output status
?dvtbl:	jmp	devtbl			;return address of device def table
?devin:	jmp	?cinit			;change baud rate of device

?drtbl:	jmp	getdrv			;return address of disk drive table
?mltio:	jmp	multio			;set multiple record count for disk I/O
?flush:	jmp	flush			;flush BIOS maintained disk caching

?mov:	jmp	?move			;block move memory to memory
?tim:	jmp	?time			;signal time and date operation
?bnksl:	jmp	bnksel			;select bank for code execution and default DMA
?stbnk:	jmp	setbnk			;select different bank for disk I/O DMA operations
?xmov:	jmp	?xmove			;set source and destination banks for one operation

	jmp	0			;reserved for future expansion
	jmp	0			;reserved for future expansion
	jmp	0			;reserved for future expansion

;;
;---------------------------------------
; data segment
;
dseg

;;
;---------------------------------------
; BOOT - initial entry point for system startup
boot:
	lxi	sp,boot$stack
	mvi	c,15			;initialize all 16 character devices
c$init$loop:
	push	b
	call	?cinit
	pop	b
	dcr	c
	jp	c$init$loop

	call	?init			;perform any additional system initialization
					;and print signon message

	lxi	b,16*256+0		;init all 16 logical disk drives
	lxi	h,@dtbl
d$init$loop:
	push	b			;save remaining count and abs drive

	mov	e,m			;grab @drv entry
	inx	h
	mov	d,m
	inx	h

	mov	a,e			;if null, no drive
	ora	d
	jz	d$init$next

	push	h			;save @drv pointer
	xchg				;XDPH address in <HL>

	dcx	h			;get relative drive code
	dcx	h
	mov	a,m
	sta	@RDRV

	mov	a,c			;get absolute drive code
	sta	@ADRV

	dcx	h			;point to init routine

	mov	d,m			;get init pointer
	dcx	h
	mov	e,m

	xchg				;call init routine
	call	ipchl

	pop	h			;recover @drv pointer
d$init$next:
	pop	b			;recover counter and drive #

	inr	c			;and loop for each drive
	dcr	b
	jnz	d$init$loop
	jmp	boot$1

;;
;---------------------------------------
; common segment
;
cseg

boot$1:
	call	set$jumps		;initialize page zero
	call	?ldccp			;fetch CCP for first time
	jmp	ccp			;and exit to CCP

;;
;---------------------------------------
; WBOOT - entry for system restarts
;
wboot:
	lxi	sp,boot$stack
	call	set$jumps		;initialize page zero
	call	?rlccp			;reload CCP
	jmp	ccp			;and exit to ccp

set$jumps:
	IF BANKED
	mvi	a,1
	call	?bnksl
	ENDIF

	mvi	a,JMP			;set up jumps in page zero
	sta	0000H
	sta	0005H
	lxi	h,?wboot		;BIOS warm start entry
	shld	0001H
	lhld	@mxtpa			;BDOS system call entry
	shld	0006H
	ret

;;
;---------------------------------------
; boot stack
;
	dw	7676H,7676H,7676H,7676H,7676H,7676H,7676H,7676H
	dw	7676H,7676H,7676H,7676H,7676H,7676H,7676H,7676H
boot$stack:

;;
;---------------------------------------
; DEVTBL - return address of character device table
;
devtbl:
	lxi	h,@ctbl
	ret

;;
;---------------------------------------
; GETDRV - return address of drive table
;
getdrv:
	lxi	h,@dtbl
	ret

;;
;---------------------------------------
; CONOUT - console output
; send character in C to all selected devices
;
conout:
	lhld	@covec			;fetch console output bit vector
	jmp	out$scan

;;
;---------------------------------------
; AUXOUT - auxiliary output
; send character in C to all selected devices
;
auxout:
	lhld	@aovec			;fetch aux output bit vector
	jmp	out$scan

;;
;---------------------------------------
; LIST - list output
; send character in C to all selected devices
;
list:
	lhld	@lovec			;fetch list output bit vector

out$scan:
	mvi	b,0			;start with device 0

co$next:
	dad	h			;shift out next bit
	jnc	not$out$device

	push	h			;save the vector
	push	b			;save the count and character

not$out$ready:
	call	coster
	ora	a
	jz	not$out$ready

	pop	b			;restore and resave the character and device
	push	b
	call	?co			;if device selected, print it
	pop	b			;recover count and character
	pop	h			;recover the rest of the vector

not$out$device:
	inr	b			;next device number
	mov	a,h
	ora	l			;see if any devices left
	jnz	co$next			;and go find them...

	ret

;;
;---------------------------------------
; CONOST - console output status
; return true if all selected console output devices are ready
;
conost:
	lhld	@covec			;get console output bit vector
	jmp	ost$scan

;;
;---------------------------------------
; AUXOST - auxiliary output status
; return true if all selected auxiliary output devices are ready
;
auxost:
	lhld	@aovec			;get aux output bit vector
	jmp	ost$scan

;;
;---------------------------------------
; LISTST - list output status
; return true if all selected list output devices are ready
;
listst:
	lhld	@lovec			;get list output bit vector

ost$scan:
	mvi	b,0			;start with device 0
cos$next:
	dad	h			;check next bit
	push	h			;save the vector
	push	b			;save the count
	mvi	a,0FFh			;assume device ready
	cc	coster			;check status for this device

	pop	b			;recover count
	pop	h			;recover bit vector
	ora	a			;see if device ready
	rz				;if any not ready, return false

	inr	b			;drop device number
	mov	a,h			;see if any more selected devices
	ora	l
	jnz	cos$next

	ori 0FFh			;all selected were ready, return true

	ret

;;
;---------------------------------------
; check for output device ready, including optional xon/xoff support
;
coster:
	mov	l,b			;make device code 16 bits
	mvi	h,0
	push	h			;save it in stack
	dad	h			;create offset into device characteristics tbl
	dad	h
	dad	h
	lxi	d,@ctbl+6		;make address of mode byte
	dad	d
	mov	a,m
	ani	mb$xonxoff
	pop	h			;recover console number in <HL>
	jz	?cost			;not a xon device, go get output status direct
	lxi	d,xofflist		;make pointer to proper xon/xoff flag
	dad	d
	call	cist1			;see if this keyboard has character
	mov	a,m
	cnz	ci1			;get flag or read key if any
	cpi	ctrlQ			;if its a control-Q,
	jnz	not$q
	mvi	a,0FFh 			;set the flag ready

not$q:
	cpi	ctrlS
	jnz	not$s			;if its a control-S,
	mvi	a,00h			;clear the flag

not$s:
	mov	m,a			;save the flag
	call	cost1			;get the actual output status,
	ana	m			;and mask with control-Q/control-S flag

	ret				;return this as the status

;;
;---------------------------------------
; get input status with BC and HL saved
;
cist1:
	push	b
	push	h 
	call	?cist
	pop	h
	pop	b
	ora	a
	ret

;;
;---------------------------------------
; get output status with BC and HL saved
;
cost1:
	push	b
	push	h
	call	?cost
	pop	h
	pop	b
	ora	a
	ret

;;
;---------------------------------------
; get input with BC and HL saved
;
ci1:
	push	b
	push	h
	call	?ci
	pop	h
	pop	b
	ret

;;
;---------------------------------------
; CONST - console input status
; return true if any selected console input device has an available character
;
const:
	lhld	@civec			;get console input bit vector
	jmp	ist$scan

;;
;---------------------------------------
; AUXIST - auxiliary input status
; return true if any selected auxiliary input device has an available character
;
auxist:
	lhld	@aivec			;get aux input bit vector

ist$scan:
	mvi	b,0			;start with device 0

cis$next:
	dad	h			;check next bit
	mvi	a,0			;assume device not ready
	cc	cist1			;check status for this device
	ora	a
	rnz				;if any ready, return true

	inr	b			;drop device number
	mov	a,h			;see if any more selected devices
	ora	l
	jnz	cis$next

	xra	a			;all selected were not ready, return false
	ret

;;
;---------------------------------------
; CONIN - console input
; return character from first ready console input device
;
conin:
	lhld	@civec
	jmp	in$scan

;;
;---------------------------------------
; AUXIN - auxiliary input
; return character from first ready auxiliary input device
;
auxin:
	lhld	@aivec

in$scan:
	push	h			;save bit vector
	mvi	b,0

ci$next:
	dad	h			;shift out next bit
	mvi	a,0			;ensure zero a (nonexistant device not ready)
	cc	cist1			;see if the device has a character

	ora	a
	jnz	ci$rdy			;this device has a character

	inr	b			;else, next device
	mov	a,h
	ora	l			;see if any more devices
	jnz	ci$next			;go look at them

	pop	h			;recover bit vector
	jmp	in$scan			;loop until we find a character

ci$rdy:
	pop	h			;discard extra stack
	jmp	?ci

;;
;---------------------------------------
; Utility Subroutines
;

;;
;---------------------------------------
; vectored CALL point
;
ipchl:
	pchl

;;
;---------------------------------------
; print message @HL up to a null
; saves BC and DE
;
?pmsg:
	push	b
	push	d
pmsg$loop:
	mov	a,m
	ora	a
	jz	pmsg$exit

	mov	c,a
	push	h
	call	?cono
	pop	h
	inx	h
	jmp	pmsg$loop

pmsg$exit:
	pop	d
	pop	b
	ret

;;
;---------------------------------------
; print binary number 0-65535 from HL
;
?pdec:
	lxi	b,table10
	lxi	d,-10000
next:
	mvi	a,'0'-1
pdecl:
	push	h
	inr	a
	dad	d
	jnc	stoploop

	inx	sp
	inx	sp
	jmp	pdecl

stoploop:
	push	d
	push	b
	mov	c,a
	call	?cono
	pop	b
	pop	d

nextdigit:
	pop	h
	ldax	b
	mov	e,a
	inx	b
	ldax	b
	mov	d,a
	inx	b
	mov	a,e
	ora	d
	jnz	next

	ret

table10:
	dw	-1000,-100,-10,-1,0

;;
;---------------------------------------
; print BIOS disk error message header
;
?pderr:
	lxi	h,drive$msg		;error header
	call	?pmsg
	lda	@adrv			;drive code
	adi	'A'
	mov	c,a
	call	?cono
	lxi	h,track$msg		;track header
	call	?pmsg
	lhld	@trk			;track number
	call	?pdec
	lxi	h,sector$msg		;sector header
	call	?pmsg
	lhld	@sect			;sector number
	call	?pdec
	ret

;;
;---------------------------------------
; BNKSEL - bank select
; select CPU bank for further execution
;
bnksel:
	sta	@cbnk 			;remember current bank
	jmp	?bank			;and go exit through users
					;physical bank select routine

xofflist:
	db	-1,-1,-1,-1,-1,-1,-1,-1	;control-S clears to zero
	db	-1,-1,-1,-1,-1,-1,-1,-1

;;
;---------------------------------------
; data segment
;
dseg

;;
;---------------------------------------
;	Disk I/O interface routines

;;
;---------------------------------------
; SELDSK - select disk drive
; drive code in C
; invoke login procedure for drive if this is first select
; return address of disk parameter header in HL
;
seldsk:
	mov	a,c			;save drive select code
	sta	@adrv
	mov	l,c			;create index from drive code
	mvi	h,0
	dad	h
	lxi	b,@dtbl			;get pointer to dispatch table
	dad	b
	mov	a,m			;point at disk descriptor
	inx	h
	mov	h,m			;if no entry in table, no disk
	mov	l,a
	ora	h
	rz 

	mov	a,e			;examine login bit
	ani	1
	jnz	not$first$select

	push	h			;put pointer in stack and DE
	xchg
	lxi	h,-2			;get relative drive
	dad	d
	mov	a,m
	sta	@RDRV
	lxi	h,-6			;find LOGIN addr
	dad	d
	mov	a,m			;get address of LOGIN routine
	inx	h
	mov	h,m
	mov	l,a
	call	ipchl			;call LOGIN
	pop	h			;recover DPH pointer

not$first$select:
	ret

;;
;---------------------------------------
; HOME - home selected drive
; treated as SETTRK(0)
;
home:
	lxi	b,0			;same as set track zero
					;fallthrough to settrk

;;
;---------------------------------------
; SETTRK - set track
; saves track address from BC in @TRK for further operations
;
settrk:
	mov	l,c
	mov	h,b
	shld	@trk
	ret

;;
;---------------------------------------
; SETSEC - set sector
; saves sector number from BC in @SECT for further operations
;
setsec:
	mov	l,c
	mov	h,b
	shld	@sect
	ret

;;
;---------------------------------------
; SETDMA - set disk memory address
; saves DMA address from BC in @DMA
; sets @DBNK to @CBNK so that further disk operations take place
;   in current bank
;
setdma:
	mov	l,c
	mov	h,b
	shld	@dma

	lda	@cbnk			;default DMA bank is current bank
					;fall through to set DMA bank

;;
;---------------------------------------
; SETBNK - set disk memory bank
; saves bank number in @DBNK for future disk data transfers
;
setbnk:
	sta	@dbnk
	ret

;;
;---------------------------------------
; SECTRN - sector translate
; indexes skew table in DE with sector in BC
; returns physical sector in HL
; if no skew table (DE=0) then returns physical=logical
;
sectrn:
	mov	l,c
	mov	h,b
	mov	a,d
	ora	e
	rz

	xchg
	dad	b
	mov	l,m
	mvi	h,0
	ret

;;
;---------------------------------------
; READ - read physical record from currently selected drive
; finds proper read routine from extended disk parameter header (XDPH)
;
read:
	lhld	@adrv			;get drive code and double it
	mvi	h,0
	dad	h
	lxi	d,@dtbl			;make address of table entry
	dad	d
	mov	a,m			;fetch table entry
	inx	h
	mov	h,m
	mov	l,a
	push	h			;save address of table
	lxi	d,-8			;point to read routine address
	dad	d
	jmp	rw$common		;use common code

;;
;---------------------------------------
; WRITE - write physical sector from currently selected drive
; finds proper write routine from extended disk parameter header (XDPH)
;
write:
	lhld	@adrv			;get drive code and double it
	mvi	h,0
	dad	h
	lxi	d,@dtbl			;make address of table entry
	dad	d
	mov	a,m			;fetch table entry
	inx	h
	mov	h,m
	mov	l,a
	push	h			;save address of table
	lxi	d,-10			;point to write routine address
	dad	d

rw$common:
	mov	a,m			;get address of routine
	inx	h
	mov	h,m
	mov	l,a
	pop	d			;recover address of table
	dcx	d			;point to relative drive
	dcx	d
	ldax	d			;get relative drive code and post it
	sta	@rdrv
	inx	d			;point to DPH again
	inx	d
	pchl				;leap to driver

;;
;---------------------------------------
; MULTIO - set multiple sector count
; saves passed count in @CNT
;
multio:
	sta	@cnt
	ret

;;
;---------------------------------------
; FLUSH - BIOS deblocking buffer flush
; Not implemented
;
flush:
	xra	a
	ret				;return with no error

;;
;---------------------------------------
; error message components
;
drive$msg	db	CR,LF,'BIOS Error on ',0
track$msg	db	': T-',0
sector$msg	db	', S-',0

;;
;---------------------------------------
; disk communication data items
;
@adrv	ds	1		; currently selected disk drive
@rdrv	ds	1		; controller relative disk drive
@trk	ds	2		; current track number
@sect	ds	2		; current sector number
@dma	ds	2		; current DMA address
@cnt	db	0		; record count for multisector transfer
@dbnk	db	0		; bank for DMA operations


;;
;---------------------------------------
; common segment
;
cseg
@cbnk	db	0		; bank for processor operations

	end
