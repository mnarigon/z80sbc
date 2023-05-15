	title 'Z80 SBC disk I/O module for CP/M 3.0'
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
; module definitions
;
public	@dph0				;drive parameter headers
public	@dph1
public	@dph2
public	@dph3

;;
;---------------------------------------
; external CP/M references
;
extrn	@dma				;DMA address
extrn	@trk				;track number
extrn	@sect				;sector number
extrn	@dbnk				;DMA bank
extrn	@cbnk				;current bank

extrn	@ermde				;BDOS error mode
extrn	?pmsg				;print message
extrn	?pderr				;print BIOS disk error header

;;
;---------------------------------------
; common segment
;
cseg

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
;   track 0:         system track
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
@dpb1:
	dw	256			;spt
	db	6			;bsh
	db	3FH			;blm
	db	3			;exm
	dw	2047			;dsm
	dw	4095			;drm
	db	0FFH			;al0
	db	0FFH			;al1
	dw	8000H			;cks
	dw	513			;off
	db	2			;psh
	db	3			;phm

;;
;---------------------------------------
@dpb2:
	dw	256			;spt
	db	6			;bsh
	db	3FH			;blm
	db	3			;exm
	dw	2047			;dsm
	dw	4095			;drm
	db	0FFH			;al0
	db	0FFH			;al1
	dw	8000H			;cks
	dw	1025			;off
	db	2			;psh
	db	3			;phm

;;
;---------------------------------------
@dpb3:
	dw	256			;spt
	db	6			;bsh
	db	3FH			;blm
	db	3			;exm
	dw	2047			;dsm
	dw	4095			;drm
	db	0FFH			;al0
	db	0FFH			;al1
	dw	8000H			;cks
	dw	1537			;off
	db	2			;psh
	db	3			;phm

;;
;---------------------------------------
; banked segment
;
dseg

;;
;---------------------------------------
; extended disk parameter header (XDPH)
;
	dw	write
	dw	read
	dw	login
	dw	init
	db	0,0
;;
;---------------------------------------
; disk parameter header (DPH)
;   xlt:	logical to physical translate table address, 0 for no translation
;   mf:		media flag
;   dpb:	disk parameter block address
;   csv:	checksum vector address,
;		0 for drive permanently mounted,
;		0FFFEH for GENCPM assignment
;   alv:	allocation vector address, 0FFFEH for GENCPM assignment
;   dirbcb:	directory buffer control block address,
;		0FFFEH for GENCPM assignment
;   dtabcb:	data buffer control block address,
;		0FFFEH for GENCPM assignment
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
	dw	0FFFEH			;alv
	dw	0FFFEH			;dirbcb
	dw	0FFFEH			;dtabcb
	dw	0FFFFH			;hash
	db	0			;hbank

;;
;---------------------------------------
	dw	write
	dw	read
	dw	login
	dw	init
	db	0,0
@dph1:
	dw	0			;xlt
	db	0,0,0,0,0,0,0,0,0	;scratch area
	db	0			;mf
	dw	@dpb1			;dpb
	dw	0			;csv
	dw	0FFFEH			;alv
	dw	0FFFEH			;dirbcb
	dw	0FFFEH			;dtabcb
	dw	0FFFFH			;hash
	db	0			;hbank

;;
;---------------------------------------
	dw	write
	dw	read
	dw	login
	dw	init
	db	0,0
@dph2:
	dw	0			;xlt
	db	0,0,0,0,0,0,0,0,0	;scratch area
	db	0			;mf
	dw	@dpb2			;dpb
	dw	0			;csv
	dw	0FFFEH			;alv
	dw	0FFFEH			;dirbcb
	dw	0FFFEH			;dtabcb
	dw	0FFFFH			;hash
	db	0			;hbank

;;
;---------------------------------------
	dw	write
	dw	read
	dw	login
	dw	init
	db	0,0
@dph3:
	dw	0			;xlt
	db	0,0,0,0,0,0,0,0,0	;scratch area
	db	0			;mf
	dw	@dpb3			;dpb
	dw	0			;csv
	dw	0FFFEH			;alv
	dw	0FFFEH			;dirbcb
	dw	0FFFEH			;dtabcb
	dw	0FFFFH			;hash
	db	0			;hbank

;;
;---------------------------------------
; init - first time initialization
;
init:
	ret				;N/A - initialized during ROM boot

;;
;---------------------------------------
; login - automatic determination of density
;   DE - address of the XDPH
;
login:
	ret				;N/A - single media type

;;
;---------------------------------------
; read - disk READ entry point
;   DE - address of the XDPH
;   return
;   A - 0 if read was successful
;   A - 1 if a permanent error occurred
;
read:
	lhld	@trk			;track in DE
	xchg
	lhld	@sect			;sector (0-63) in C
	mov	c,l
	call	set$addr		;set track and sector
	jrnz	read0			;test status

	lda	@dbnk			;set DMA bank
	mov	b,a
	lda	@cbnk			;set current bank
	mov	c,a
	lhld	@dma			;set DMA address
	call	ide$b$read		;call ROM disk read routine
	rz				;test status

read0:
	lxi	h,read$msg
	jmp	error			;report error

read$msg:
	db	', Read',CR,LF,0

;;
;---------------------------------------
; write - disk WRITE entry point
;   DE - address of the XDPH
;   return
;   A - 0 if write was successful
;   A - 1 if a permanent error occurred
;   A - 2 if the drive was write protected
;
write:
	lhld	@trk			;track in DE
	xchg
	lhld	@sect			;sector (0-63) in C
	mov	c,l
	call	set$addr		;set track and sector
	jrnz	write0			;test status

	lda	@dbnk			;set DMA bank
	mov	b,a
	lda	@cbnk			;set current bank
	mov	c,a
	lhld	@dma			;set DMA address
	call	ide$b$write		;call ROM disk write routine
	rz				;test status

write0:
	lxi	h,write$msg
	jmp	error			;report error

write$msg:
	db	', Write',CR,LF,0

;;
;---------------------------------------
; error - report an I/O error
; HL - operation message
;
error:
	push	psw			;save status
	lda	@ermde			;suppress error message if BDOS is returning errors
	cpi	0FFh
	jrz	error0

	push	h
	call	?pderr			;BIOS Err on d: T-nn, S-mm
	pop	h
	call	?pmsg			;print operation
	pop	psw			;restore status
	call	put$status		;call ROM display disk status routine
	xra	a
	inr	a
	ret
error0:
	pop	psw
	ret
	end
