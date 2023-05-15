	title 'Z80 SBC character I/O module for CP/M 3.0'
;;
;---------------------------------------
; libraries
;
maclib	Z80
maclib	modebaud
maclib	zsbcrom

;;
;---------------------------------------
; module definitions
;
public	?cinit
public	?ci
public	?co
public	?cist
public	?cost
public	@ctbl

;;
;---------------------------------------
; common segment
;
cseg

;;
;---------------------------------------
; ?cinit - character device initialization
;   C - the device number
;
?cinit:
	ret				;N/A - initialized during ROM boot

;;
;---------------------------------------
; ?ci - character device input
;   waits for the next input character and returns it
;   B - the device number
;   return
;   A - the input character
;
?ci:
	mov	a,b
	ana	a
	jrnz	null$input		;null$input if not device 0
	call	getc			;ROM serial input
	ani	07FH			;clear parity
	ret

null$input:
	mvi	a,1AH			;return a ctl-Z for no device
	ret

;;
;---------------------------------------
; ?co - character device output
;   waits for the device to be ready and sends it
;   B - the device number
;   C - the character to output
;
?co:
	mov	a,b
	ana	a
	jrnz	null$output		;null$output if not device 0
	jmp	putc			;ROM serial output

null$output:
	ret

;;
;---------------------------------------
; ?cist - character device input status
;   B - the device number
;   return
;   A - 0 if the device has no input ready
;   A - 0FFH if the device has input ready
;
?cist:
	mov	a,b
	ana	a
	jrnz	null$status		;null$status if not device 0
	jmp	rx$avail		;ROM serial in status

null$status:
	xra	a
	ret

;;
;---------------------------------------
; ?cost - character device output status
;   B - the device number
;   return
;   A - 0 if the device can not accept an output character
;   A - 0FFH if the device can accept an output character
;
?cost:
	mov	a,b
	ana	a
	jrnz	null$status		;null$status if not device 0
	jmp	tx$ready		;ROM serial output status

;;
;---------------------------------------
; @ctbl - character device table
;
@ctbl:
	db 'USBSER'			;device 0, Z80 SBC USB serial I/O
	db mb$in$out			;input/output
	db baud$none
	db 0				;table terminator
	end
