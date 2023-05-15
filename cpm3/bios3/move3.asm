	title 'Z80 SBC memory select and move module for CP/M 3.0'
;;
;---------------------------------------
;
true	equ	-1
false	equ	not true

;;
;---------------------------------------
; build flags
; debug - print information about BIOS calls
; banked - true if a banked CP/M system
;
DEBUG	equ	false
BANKED	equ	true

;;
;---------------------------------------
; libraries
;
maclib	Z80
maclib	zsbcrom

;;
;---------------------------------------
; module routines
;
public	?move
public	?xmove
public	?bank

;;
;---------------------------------------
; external CP/M references
;
extrn	?bnksl
extrn	@cbnk

;;
;---------------------------------------
; common segment
;
cseg

;;
;---------------------------------------
; buffer for between bank moves
;
	IF	BANKED
src$bnk	ds	1			;source bank
dst$bnk	ds	1			;destination bank
mov$flg	db	0			;zero if an within bank move
bnk$buf	ds	128			;buffer for between bank moves
	ENDIF

;;
;---------------------------------------
; ?move - memory to memory move
;   DE - source address
;   HL - destination address
;   BC - byte count
;   if ?xmove has been called since the last call to ?move
;     a between bank move must be performed
;   on return, registers HL and DE point to the next byte after the move
;
?move:
	IF	BANKED
	lda	mov$flg
	ana	a			;test if within bank move
	jrz	m$1			;zero - within bank move

	xra	a			;clear between bank move flag
	sta	mov$flg

	lda	@cbnk
	push	psw			;save current bank
	xchg				;swap source and destination

m$lp0:
	push	b			;save count
	push	d			;save destination
	lxi	d,bnk$buf		;set buffer as destination
	lda	src$bnk
	call	?bnksl			;select source bank

m$lp1:
	ldi				;and move max 128 bytes
	mov	a,c
	ani	07FH
	jrnz	m$lp1

	pop	d			;restore destination
	pop	b			;restore count
	push	h			;save source
	lxi	h,bnk$buf		;set buffer as source
	lda	dst$bnk
	call	?bnksl			;set destination bank

m$lp2:
	ldi				;and move max 128 bytes
	mov	a,c
	ani	07FH
	jrnz	m$lp2

	pop	h			;restore source
	mov	a,b			;test if count is zero
	ora	c
	jrnz	m$lp0			;more bytes to move

	xchg				;swap source and destination
	pop	psw
	call	?bnksl			;restore current bank
	ret

m$1:
	ENDIF

	xchg				;swap source and dest
	ldir				;use Z80 block move instruction
	xchg				;swap back source and dest
	ret

;;
;---------------------------------------
; ?xmove - set banks for the following ?move
;   B - destination bank
;   C - source bank
;
?xmove:
	IF	BANKED
	mov	a,c
	sta	src$bnk			;store source bank
	mov	a,b
	sta	dst$bnk			;store destination bank
	mvi	a,0FFH
	sta	mov$flg			;set between bank move flag
	ENDIF
	ret

;;
;---------------------------------------
; ?bank - set bank for execution
;   A - bank
;   on return, all registers except A must be restored
;
?bank:
	IF	BANKED
	ani	01H
	call	set$bank		;ROM routine
	ENDIF
	ret
	end
