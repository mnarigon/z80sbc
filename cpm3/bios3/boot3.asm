	title 'Z80 SBC boot loader module for CP/M 3.0'
;;
;---------------------------------------
;
true	equ	-1
false	equ	not true
CR	equ	0DH
LF	equ	0AH
bdos	equ	0005H

;;
;---------------------------------------
; build flags
; ccp$dseg - if true buffer CCP.COM in DSEG for CCP.COM reload
;
CCP$DSEG 	equ	true

;;
;---------------------------------------
; CCP.COM load from system track
; keep consistent with zsbc-mon/zsbcmon.z80
ldr$size	equ	4992			;CPMLDR.COM file size in bytes
ccp$size	equ	3200			;CCP.COM file size in bytes

ccp$count	equ	(ccp$size+511)/512	;number of 512-byte sectors
ccp$track	equ	0			;starting track for CCP.COM
ccp$sector	equ	(ldr$size+511)/512	;starting sector for CCP.COM
ccp$ladr	equ	0100H			;load address
ccp$bank	equ	0			;buffer bank
max$sec		equ	64			;sectors per track

;;
;---------------------------------------
; libraries
;
maclib	Z80
maclib	zsbcrom

;;
;---------------------------------------
; module definitions
;
public	?init
public	?ldccp
public	?rlccp
public	?time

;;
;---------------------------------------
; external CP/M references
;
extrn	@civec
extrn	@covec
extrn	@aivec
extrn	@aovec
extrn	@lovec

extrn	@cbnk
extrn	?move
extrn	?xmove

;;
;---------------------------------------
; banked segment
;
dseg

;;
;---------------------------------------
; ?init - perform hardware initialization other than character and disk I/O
;
?init:
	lxi	h,8000H			;assign console to USBSER:
	shld	@civec
	shld	@covec

	lxi	h,0	 		;assign LIST and AUX IN/OUT to null
	shld	@lovec
	shld	@aivec
	shld	@aovec

	lxi	h,signon$msg		;print signon message
	call	puts

	ret

signon$msg:
	db	'Z80 SBC BIOS Version 1.0',CR,LF,0

;;
;---------------------------------------
; CCP.COM reload buffer
;
	IF	CCP$DSEG
ccp$badr:
	ds	ccp$size
	ENDIF

;;
;---------------------------------------
; common segment
;
cseg

;;
;---------------------------------------
; ?ldccp - load CCP.COM from the system track into the TPA
;   saves a copy into bank 0 for reload
;
?ldccp:
	mvi	b,ccp$count		;load from disk using ROM
	mvi	c,ccp$sector
	lxi	d,ccp$track
	lxi	h,ccp$ladr
ldccp0:
	push	b
	push	d
	push	h
	call	set$addr		;set address
	jrnz	ldccp2			;report error

	pop	h
	call	ide$read		;read sector
	jrnz	ldccp3			;report error

	pop	d
	pop	b
	inr	c			;next sector
	mov	a,c
	cpi	max$sec
	jrc	ldccp1
	inx	d			;next track
	mvi	c,0
ldccp1:
	djnz	ldccp0			;read another

	IF	CCP$DSEG		;save a copy into buffer
	mvi	b,ccp$bank		;destination bank
	lda	@cbnk			;source bank
	mov	c,a
	call	?xmove

	lxi	b,ccp$size		;byte count
	lxi	d,ccp$ladr		;source address
	lxi	h,ccp$badr		;destination address
	call	?move
	ENDIF
	ret

ldccp2:
	pop	h
ldccp3:
	pop	d
	pop	b
	lxi	h,ld$msg		;error
	call	puts
	ret

ld$msg:
	db	'CCP.COM Load Error',CR,LF,0

;;
;---------------------------------------
; ?rlccp - reload CCP into the TPA
;
?rlccp:
	IF	CCP$DSEG
	lda	@cbnk			;destination bank
	mov	b,a
	mvi	c,ccp$bank		;source bank
	call	?xmove

	lxi	b,ccp$size		;byte count
	lxi	d,ccp$badr		;source address
	lxi	h,ccp$ladr		;destination address
	jmp	?move
	ELSE
	jmp	?ldccp
	ENDIF

;;
;---------------------------------------
; ?time - set or get time
;
?time:
	ret				;no clock
	end
