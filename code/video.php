;    PMDEmu - AVR based emulator of Czechoslovak microcomputer PMD-85 originally based on I8080
;    Copyright (C) 2004  Peter Chrenko <peto@kmit.sk>, J.Matusku 2178/21, 955 01 Topolcany, Slovakia

;    video.php

	.equ		total_lines	= 312
	.equ		visible_lines	= 256
	.equ		dark_lines	= 36	
	.equ		vsync_lines	= 5	
	
<? 
   $expected_TCNT1L  = ($ocr1 + 4 + 3 + 3) & 0xff;

function VIDEO_DELAY()
{
  global $f;

  if ( $f >= 18000000 ) echo "\n\tnop\t;VIDEO_DELAY\n\n";
}  

?>

interrupt_OCR1A:	

	in	video_SREG,SREG			; remember SREG
	MEMWR_deactive				; safe finish possible memory write operation
	

	in	video_tmp,TCNT1L		; synchronize with 1, 2 or 3 cycles interrupted instruction
	cpi	video_tmp, <? echo $expected_TCNT1L; ?>	; 3 cycles instruction?
	breq	interrupted_1cycle
	cpi	video_tmp, <? echo $expected_TCNT1L - 1; ?>	; 2 cycles instruction?
	brne	interrupted_1cycle			; 1 cycle?

interrupted_1cycle:	

	in	video_CONTROLRAM,CONTROLRAM	; speakerbit is at CONTROLRAM port (synonymous to SPEAKERPORT)
	

	inc	m64
	mov	video_tmp,m64	
	ori	video_tmp,0b100
	
	and	video_tmp,kbd_portC	;PC0

	in 	video_tmp,SREG
	bst	video_tmp,1		; Z sign is 1st bit 	
	bld	video_CONTROLRAM,SPEAKER_BIT ; copy bit to SPEAKER 
	out	CONTROLRAM,video_CONTROLRAM	

	cpi	video_state,dark_lines-vsync_lines	;
	breq	normal_line

	inc	video_state
	
	cpi	video_state,total_lines-visible_lines-vsync_lines		
	breq	vertical_sync_begin
	cpi	video_state,total_lines-visible_lines		
	breq	vertical_sync_end

	rjmp	_reti
	
	
	
vertical_sync_begin: 		; first vertical sync signal
	ldi		video_tmp,high(<? echo $ocr3_vertical; ?>)	; when sync goes low 
	sts		OCR3AH,video_tmp				; channel T3/A
	ldi		video_tmp,low(<? echo $ocr3_vertical; ?>)	
	sts		OCR3AL,video_tmp
	rjmp		_reti

vertical_sync_end:   		; last vertical sync signal

	ldi		video_tmp,high(<? echo $ocr3; ?>)		; when sync goes low 
	sts		OCR3AH,video_tmp				; channel T3/A
	ldi		video_tmp,low(<? echo $ocr3; ?>)	
	sts		OCR3AL,video_tmp

        ; setup "videoprocessor" position to left upper corner 
	; video address := 0xc000
	ldi		video_ptr_h,0xc0			; set only high address counter
	mov		video_state,_zero			; state := 0

	lds		video_tmp,blink_counter
	dec		video_tmp
	brne		no_visibility_change	
	
	ldi		XL,1
	eor		XH,XL			; flip blink_lookup_table


	ldi		video_tmp,blink_period

no_visibility_change:	
	sts		blink_counter,video_tmp

		
	rjmp	_reti


normal_line:	
	; show TV microline 

    	in	video_DATADIR,DATADIR
	out	DATADIR,_zero			; prepare to read
	in	video_ADDRH,ADDRH
	in	video_ADDRL,ADDRL

	MEMRD_active
	
	out	ADDRL,video_ptr_l
	out	ADDRH,video_ptr_h
	inc	video_ptr_l

	<? MDELAY(1); ?>

	in	XL,DATAIN			; B X 0 1 2 3 4 5 (B = blink, X = brightness)
	ld	video_tmp,X
		
	; original PMD has 48 bytes per TV line	
<? 
	
	$bytes_per_line = 48;

	if( $f < 16000000 )
	{
	   $bytes_per_line = ceil(48e-6*$f/3/6); 
	}   
	
        echo "\t; bytes per line = $bytes_per_line\n";	 

for( $i = 0; $i < $bytes_per_line - 1; $i++ )
{ 
	
	echo "\t; $i.byte\n";
	?>	
	
	out	VIDEOPORT,video_tmp		; 0.bit 
	asr	video_tmp
	out	ADDRL,video_ptr_l		; output low address 
	
	out	VIDEOPORT,video_tmp		; 1.bit 
	asr	video_tmp
	<? VIDEO_DELAY(); ?>

	out	VIDEOPORT,video_tmp		; 2.bit 
	asr	video_tmp
	inc	video_ptr_l
	
	out	VIDEOPORT,video_tmp		; 3.bit 
	asr	video_tmp
	in	XL,DATAIN			; load next 6 pixels :X X 5 4 3 2 1 0
	
	out	VIDEOPORT,video_tmp		; 4.bit 
	asr	video_tmp
	<? VIDEO_DELAY(); ?>

	out	VIDEOPORT,video_tmp		; 5.bit 
	ld	video_tmp,X

<? } ?>

	; last byte on microline
	
	out	VIDEOPORT,video_tmp		; 0.bit 
	asr	video_tmp
	out	ADDRL,video_ADDRL
	
	out	VIDEOPORT,video_tmp		; 1.bit 
	asr	video_tmp
	<? VIDEO_DELAY(); ?>

	out	VIDEOPORT,video_tmp		; 2.bit 
	asr	video_tmp
        out	ADDRH,video_ADDRH


	out	VIDEOPORT,video_tmp		; 3.bit 
	asr	video_tmp
	ldi	XL,<? echo 64-$bytes_per_line; ?> 			
	                                        ; skip also next 16 bytes => 16
						; after 48 shown bytes is 16 bytes video-memory gap
						; also correct for 16.000 MHz clock
						
	out	VIDEOPORT,video_tmp		; 4.bit 
	asr	video_tmp
	<? VIDEO_DELAY(); ?>
	 
 	out	VIDEOPORT,video_tmp		; 5.bit 
	MEMRD_deactive
	out	VIDEOPORT, _zero	        ; blank TV (video_data:=0)
		

        add	video_ptr_l,XL			; next microline in PMD videomemory
	adc	video_ptr_h,_zero
        adc	video_state,_zero		; CY ? --> add it
	
	; Ports restore order is O.K. (safe)
	out	DATADIR,video_DATADIR
	

_reti:
	out	CONTROLRAM,video_CONTROLRAM	; restore control bus, but with disabled /WR
	out	SREG,video_SREG
	sbis	UCSR0A,RXC0			; USART received char from keyboard?
	reti					; finish video routine

	;continue to kbd.php
<? 	
	include "kbd.php"; 
?>

