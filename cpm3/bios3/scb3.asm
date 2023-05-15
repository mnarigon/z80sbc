	title 'Z80 SBC System Control Block definition module for CP/M 3.0'
;;
;---------------------------------------
; module definitions
;
public	@civec
public	@covec
public	@aivec
public	@aovec
public	@lovec
public	@bnkbf
public	@crdma
public	@crdsk
public	@vinfo
public	@resel
public	@fx
public	@usrcd
public	@mltio
public	@ermde
public	@erdsk
public	@media
public	@bflgs
public	@date
public	@hour
public	@min
public	@sec
public	?erjmp
public	@mxtpa

scb$base	equ	0FE00H		;base of the SCB - SYSGEN flag
@civec		equ	scb$base+22h	;console input redirection vector (word, r/w)
@covec		equ	scb$base+24h	;console output redirection vector (word, r/w)
@aivec		equ	scb$base+26h	;auxiliary input redirection vector (word, r/w)
@aovec		equ	scb$base+28h	;auxiliary output redirection vector (word, r/w)
@lovec		equ	scb$base+2ah	;list output redirection vector (word, r/w)
@bnkbf		equ	scb$base+35h	;address of 128 byte buffer for banked bios (word, r/o)
@crdma		equ	scb$base+3ch	;current dma address (word, r/o)
@crdsk		equ	scb$base+3eh	;current disk (byte, r/o)
@vinfo		equ	scb$base+3fh	;BDOS variable "info" (word, r/o)
@resel		equ	scb$base+41h	;FCB flag (byte, r/o)
@fx		equ	scb$base+43h	;BDOS function for error messages (byte, r/o)
@usrcd		equ	scb$base+44h	;current user code (byte, r/o)
@mltio		equ	scb$base+4ah	;current multi-sector count (byte, r/w)
@ermde		equ	scb$base+4bh	;BDOS error mode (byte, r/o)
@erdsk		equ	scb$base+51h	;BDOS error disk (byte, r/o)
@media		equ	scb$base+54h	;set by BIOS to indicate open door (byte, r/w)
@bflgs		equ	scb$base+57h	;BDOS message size flag (byte, r/o)
@date		equ	scb$base+58h	;date in days since 1 jan 78 (word, r/w)
@hour		equ	scb$base+5ah	;hour in BCD (byte, r/w)
@min		equ	scb$base+5bh	;minute in BCD (byte, r/w)
@sec		equ	scb$base+5ch	;second in BCD (byte, r/w)
?erjmp		equ	scb$base+5fh	;BDOS error message jump (word, r/w)
@mxtpa		equ	scb$base+62h	;top of user TPA (address at 6,7) (word, r/o)

	end
