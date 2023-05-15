	title 'Z80 SBC drive table module for CP/M 3.0'
;;
;---------------------------------------
; libraries
;
maclib	cpm3

;;
;---------------------------------------
; module definitions
;
public	@dtbl

;;
;---------------------------------------
; external references
;
extrn	@dph0
extrn	@dph1
extrn	@dph2
extrn	@dph3

;;
;---------------------------------------
; common segment
;
cseg

;;
;---------------------------------------
; @dtbl - the drive table
;
@dtbl:	dtbl <@dph0,@dph1,@dph2,@dph3>

	end
