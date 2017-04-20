    
;    PMDEmu SMALL - AVR based emulator of Czechoslovak microcomputer PMD-85 originally based on I8080
;    Copyright (C) 2003  Peter Chrenko <peto@kmit.sk>, J.Matusku 2178/21, 955 01 Topolcany, Slovakia
	
;
;    This program is free software; you can redistribute it and/or modify
;    it under the terms of the GNU General Public License as published by
;    the Free Software Foundation; either version 2 of the License, or
;    (at your option) any later version.
;
;    This program is distributed in the hope that it will be useful,
;    but WITHOUT ANY WARRANTY; without even the implied warranty of
;    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;    GNU General Public License for more details.
;
;    You should have received a copy of the GNU General Public License
;    along with this program; if not, write to the Free Software
;    Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
;

; PMD.PHP

 	 .include 	"m128def.inc"
	 .listmac 
	 
	; SRAM ===> 2 sys cycles


;    PMDEmu - AVR based emulator of Czechoslovak microcomputer PMD-85 originally based on I8080
;    Copyright (C) 2004  Peter Chrenko <peto@kmit.sk>, J.Matusku 2178/21, 955 01 Topolcany, Slovakia

;    macro.asm

; A0-7  = PORTD
; A8-15 = PORTB

.equ	ADDRL	=	PORTD
.equ	ADDRH	=	PORTB
.equ	ADDRLDD = 	DDRD
.equ	ADDRHDD = 	DDRB


; D0-D7 = PORTC(OUTPUT):PINC(INPUT)
.equ	DATAIN	=	PINC
.equ	DATAOUT	=	PORTC
.equ	DATADIR = 	DDRC


; PORT E
 
	; PE0 = KBD_DATA(RXD)(IN)
	; PE1 = VIDEO_DATA (OUT)
	; PE2 = KBD_CLK(XCK) (IN)
	; PE3 = N/A
	; PE4 = N/A
	; PE5 = VIDEO_SYNC (OC3C)(OUT)
	; PE6 = N/A
	; PE7 = VIDEO_BRIGHT (OUT)

.equ	VIDEOPORT	= PORTE
.equ	VIDEOPORTDD	= DDRE
.equ	VIDEOPORTDD_value = (1<<1)|(1<<3)|(1<<7)

.macro	VIDEO_SYNC_0
	cbi	DDRE,DDE5
.endmacro	

.macro	VIDEO_SYNC_1
	sbi	DDRE,DDE5
.endmacro	


; PORT A
	; PA7 = /RD
	; PA6 = /WR

	; PA3 = SPEAKER

.equ	MEMRD	=	PA7
.equ	MEMWR	=	PA6
.equ	SPEAKER_BIT =   PA3

.equ	CONTROLRAM   = 	PORTA
.equ	SPEAKERPORT  =  PORTA
.equ	CONTROLRAMDD = 	DDRA

.equ	CONTROLRAMDD_value = (1<<MEMWR)|(1<<MEMRD)|(1<<SPEAKER_BIT)

;flags
.equ	PMD_CY	= 0
.equ	PMD_P	= 2
.equ	PMD_AC	= 4
.equ	PMD_Z	= 6
.equ	PMD_S	= 7
.equ	PMD_PSW	= 0b00000010	; empty PSW

.equ	ATMEL_C		= 0
.equ	ATMEL_Z		= 1
.equ	ATMEL_N		= 2
.equ	ATMEL_V		= 3
.equ	ATMEL_S		= 4
.equ	ATMEL_H		= 5
.equ	ATMEL_T		= 6
.equ	ATMEL_I		= 7

.macro	SET_SPEAKER_1
	sbi	SPEAKERPORT,SPEAKER_BIT
.endmacro

.macro	SET_SPEAKER_0
	cbi	SPEAKERPORT,SPEAKER_BIT
.endmacro

.macro	MEMRD_active
		cbi			CONTROLRAM,MEMRD
.endmacro


.macro	MEMRD_deactive
		sbi			CONTROLRAM,MEMRD
.endmacro

.macro	MEMWR_active
		cbi			CONTROLRAM,MEMWR
.endmacro


.macro	MEMWR_deactive
		sbi			CONTROLRAM,MEMWR
.endmacro


; kb_lookup
	 	.equ	r0 = 1  ; definition of rows of PMD keyboard
		.equ	r1 = 2  ; 2nd row
		.equ	r2 = 4  ; 3rd row
		.equ	r3 = 8  ; 4th row
		.equ	r4 = 15 ; 5th row
		.equ	rx = 0  ; mark - not used key


	 .def	video_SREG 		=	r0	
     	 .def	video_DATADIR		=	r1	
	 .def	kbd_flags		=	r2 ; flags for KBD module
					    ; 7 = F0
					    ; 6 = STOP
					    ; 5 = SHIFT
					    ; 4 = ALT
					    ; 3 = ALT+S	 
					    ; 2 =
					    ; 1 =
    					    ; 0 =

       	 .def	m64		=	r3
	 .def	video_ADDRL		=	r4	; pair0
	 .def	video_ADDRH		=	r5	; pair1 (kbd.asm uses movw)
	 .def	video_CONTROLRAM	=	r6	; pair1

	 .def	kbd_portC	=	r7		; special register such as *(kbd_ports+2), but with precomputed sound bits
 	 .def	B		=	r8
	 .def	video_ptr_l	=	r9		
	 .def	_zero		=	r10
	 .def	_255		=	r11
         .def   _last_result  	=	r12
	 .def	A		=	r13
	 .def	L		=	r14	  
     	 .def	H		=	r15   

     
		
    	;free 				r16
	.def	PSW		=	r17
	.def	video_tmp	= 	r18 
        .def	video_state	=	r19
	.def	kbd_reg		=	r20	; only in kbd.asm

	.def	C		=	r20	  	    
	.def	video_ptr_h	=	r21

	.def	E		=	r22	  
	.def	D		=	r23    
    
	
	.def	_SPL	=	r24	  ; may use addiw _SPL,1
    	.def	_SPH	=	r25
	
	; X(r26:27) is video look-up table address (16bit register)
	; Z is used by IJMP & LPM (main instruction cycle)
	
	.def	_PCL	=	r28   ; Y
	.def	_PCH	=	r29


.dseg
		.org	0x100	; skip ATmega128 MMIO (memory mapped I/O)
		
kb_cols:	.byte   16  	; PMD's keyboard has 16 columns selected by IC 74154                                        '
blink_counter:	.byte	1
kbd_ports:	.byte   4	; keyboard 8255 state
mgf_pointer: 	.byte	3	; 3 bytes counter (now we address 128 KB FLASH)
_rom:		.byte	4	; external ROM modul 8255 state (contain BASIC-G) 	
stop_flag:	.byte	1

.equ	F0_bit		= 7
.equ	STOP_bit	= 6
.equ	SHIFT_bit	= 5
.equ	ALT_bit		= 4

.cseg


;**********************************************************************************
 		.org	0		
		clr		_zero			; _zero := 0	
		ldi		r30,255
		mov		_255,r30
		
		; PORT E
 
		; PE0 = KBD_DATA(RXD)(IN)
		; PE1 = VIDEO_DATA (OUT)
		; PE2 = KBD_CLK(XCK) (IN)
		; PE3 = N/A
		; PE4 = N/A
		; PE5 = VIDEO_SYNC (OC3C)(OUT)
		; PE6 = N/A
		; PE7 = VIDEO_BRIGHT (OUT)
				
		; PORT A		
		; PA7 = /RD
		; PA6 = /WR

				
		ldi		r30, CONTROLRAMDD_value ;
		out		CONTROLRAMDD,r30
		out		CONTROLRAM,_255	 	 ; control bus = idle state	
			
		out		ADDRLDD,_255		 ; output (address)
		out		ADDRHDD,_255		 ; output (address)

		ldi		r30,VIDEOPORTDD_value
		out		VIDEOPORTDD,r30		 ; set outputs (video,sync,brightness)
		out		VIDEOPORT,_zero		 ; BLACK level on video

		; ---------- inicialize PS/2 keyboard ---------------------------------------------
		ldi		r30,(1<<RXEN0)
		out		UCSR0B,r30
						
		ldi		r30,0b01110110 ; synchro mode enable, odd parity, 8 bits
		sts		UCSR0C,r30
		; ---------- end of inicializing PS/2 keyboard ---------------------------------------------

		;------------------- rewind tape				
		ldi	ZL,byte1(games_start << 1)
		sts	mgf_pointer+0,ZL
		ldi	ZL,byte2(games_start << 1)
		sts	mgf_pointer+1,ZL
				
		ldi	ZL,1

		rjmp 	after_reset

;**********************************************************************************
		.org	OC1Aaddr
		
		;    PMDEmu - AVR based emulator of Czechoslovak microcomputer PMD-85 originally based on I8080
;    Copyright (C) 2004  Peter Chrenko <peto@kmit.sk>, J.Matusku 2178/21, 955 01 Topolcany, Slovakia

;    video.php

	.equ		total_lines	= 312
	.equ		visible_lines	= 256
	.equ		dark_lines	= 36	
	.equ		vsync_lines	= 5	
	

interrupt_OCR1A:	

	in	video_SREG,SREG			; remember SREG
	MEMWR_deactive				; safe finish possible memory write operation
	

	in	video_tmp,TCNT1L		; synchronize with 1, 2 or 3 cycles interrupted instruction
	cpi	video_tmp, 141	; 3 cycles instruction?
	breq	interrupted_1cycle
	cpi	video_tmp, 140	; 2 cycles instruction?
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
	ldi		video_tmp,high(511)	; when sync goes low 
	sts		OCR3AH,video_tmp				; channel T3/A
	ldi		video_tmp,low(511)	
	sts		OCR3AL,video_tmp
	rjmp		_reti

vertical_sync_end:   		; last vertical sync signal

	ldi		video_tmp,high(948)		; when sync goes low 
	sts		OCR3AH,video_tmp				; channel T3/A
	ldi		video_tmp,low(948)	
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

		nop		;MDELAY: inserted one wait cycle

	in	XL,DATAIN			; B X 0 1 2 3 4 5 (B = blink, X = brightness)
	ld	video_tmp,X
		
	; original PMD has 48 bytes per TV line	
	; bytes per line = 48
	; 0.byte
	
	
	out	VIDEOPORT,video_tmp		; 0.bit 
	asr	video_tmp
	out	ADDRL,video_ptr_l		; output low address 
	
	out	VIDEOPORT,video_tmp		; 1.bit 
	asr	video_tmp
	
	out	VIDEOPORT,video_tmp		; 2.bit 
	asr	video_tmp
	inc	video_ptr_l
	
	out	VIDEOPORT,video_tmp		; 3.bit 
	asr	video_tmp
	in	XL,DATAIN			; load next 6 pixels :X X 5 4 3 2 1 0
	
	out	VIDEOPORT,video_tmp		; 4.bit 
	asr	video_tmp
	
	out	VIDEOPORT,video_tmp		; 5.bit 
	ld	video_tmp,X

	; 1.byte
	
	
	out	VIDEOPORT,video_tmp		; 0.bit 
	asr	video_tmp
	out	ADDRL,video_ptr_l		; output low address 
	
	out	VIDEOPORT,video_tmp		; 1.bit 
	asr	video_tmp
	
	out	VIDEOPORT,video_tmp		; 2.bit 
	asr	video_tmp
	inc	video_ptr_l
	
	out	VIDEOPORT,video_tmp		; 3.bit 
	asr	video_tmp
	in	XL,DATAIN			; load next 6 pixels :X X 5 4 3 2 1 0
	
	out	VIDEOPORT,video_tmp		; 4.bit 
	asr	video_tmp
	
	out	VIDEOPORT,video_tmp		; 5.bit 
	ld	video_tmp,X

	; 2.byte
	
	
	out	VIDEOPORT,video_tmp		; 0.bit 
	asr	video_tmp
	out	ADDRL,video_ptr_l		; output low address 
	
	out	VIDEOPORT,video_tmp		; 1.bit 
	asr	video_tmp
	
	out	VIDEOPORT,video_tmp		; 2.bit 
	asr	video_tmp
	inc	video_ptr_l
	
	out	VIDEOPORT,video_tmp		; 3.bit 
	asr	video_tmp
	in	XL,DATAIN			; load next 6 pixels :X X 5 4 3 2 1 0
	
	out	VIDEOPORT,video_tmp		; 4.bit 
	asr	video_tmp
	
	out	VIDEOPORT,video_tmp		; 5.bit 
	ld	video_tmp,X

	; 3.byte
	
	
	out	VIDEOPORT,video_tmp		; 0.bit 
	asr	video_tmp
	out	ADDRL,video_ptr_l		; output low address 
	
	out	VIDEOPORT,video_tmp		; 1.bit 
	asr	video_tmp
	
	out	VIDEOPORT,video_tmp		; 2.bit 
	asr	video_tmp
	inc	video_ptr_l
	
	out	VIDEOPORT,video_tmp		; 3.bit 
	asr	video_tmp
	in	XL,DATAIN			; load next 6 pixels :X X 5 4 3 2 1 0
	
	out	VIDEOPORT,video_tmp		; 4.bit 
	asr	video_tmp
	
	out	VIDEOPORT,video_tmp		; 5.bit 
	ld	video_tmp,X

	; 4.byte
	
	
	out	VIDEOPORT,video_tmp		; 0.bit 
	asr	video_tmp
	out	ADDRL,video_ptr_l		; output low address 
	
	out	VIDEOPORT,video_tmp		; 1.bit 
	asr	video_tmp
	
	out	VIDEOPORT,video_tmp		; 2.bit 
	asr	video_tmp
	inc	video_ptr_l
	
	out	VIDEOPORT,video_tmp		; 3.bit 
	asr	video_tmp
	in	XL,DATAIN			; load next 6 pixels :X X 5 4 3 2 1 0
	
	out	VIDEOPORT,video_tmp		; 4.bit 
	asr	video_tmp
	
	out	VIDEOPORT,video_tmp		; 5.bit 
	ld	video_tmp,X

	; 5.byte
	
	
	out	VIDEOPORT,video_tmp		; 0.bit 
	asr	video_tmp
	out	ADDRL,video_ptr_l		; output low address 
	
	out	VIDEOPORT,video_tmp		; 1.bit 
	asr	video_tmp
	
	out	VIDEOPORT,video_tmp		; 2.bit 
	asr	video_tmp
	inc	video_ptr_l
	
	out	VIDEOPORT,video_tmp		; 3.bit 
	asr	video_tmp
	in	XL,DATAIN			; load next 6 pixels :X X 5 4 3 2 1 0
	
	out	VIDEOPORT,video_tmp		; 4.bit 
	asr	video_tmp
	
	out	VIDEOPORT,video_tmp		; 5.bit 
	ld	video_tmp,X

	; 6.byte
	
	
	out	VIDEOPORT,video_tmp		; 0.bit 
	asr	video_tmp
	out	ADDRL,video_ptr_l		; output low address 
	
	out	VIDEOPORT,video_tmp		; 1.bit 
	asr	video_tmp
	
	out	VIDEOPORT,video_tmp		; 2.bit 
	asr	video_tmp
	inc	video_ptr_l
	
	out	VIDEOPORT,video_tmp		; 3.bit 
	asr	video_tmp
	in	XL,DATAIN			; load next 6 pixels :X X 5 4 3 2 1 0
	
	out	VIDEOPORT,video_tmp		; 4.bit 
	asr	video_tmp
	
	out	VIDEOPORT,video_tmp		; 5.bit 
	ld	video_tmp,X

	; 7.byte
	
	
	out	VIDEOPORT,video_tmp		; 0.bit 
	asr	video_tmp
	out	ADDRL,video_ptr_l		; output low address 
	
	out	VIDEOPORT,video_tmp		; 1.bit 
	asr	video_tmp
	
	out	VIDEOPORT,video_tmp		; 2.bit 
	asr	video_tmp
	inc	video_ptr_l
	
	out	VIDEOPORT,video_tmp		; 3.bit 
	asr	video_tmp
	in	XL,DATAIN			; load next 6 pixels :X X 5 4 3 2 1 0
	
	out	VIDEOPORT,video_tmp		; 4.bit 
	asr	video_tmp
	
	out	VIDEOPORT,video_tmp		; 5.bit 
	ld	video_tmp,X

	; 8.byte
	
	
	out	VIDEOPORT,video_tmp		; 0.bit 
	asr	video_tmp
	out	ADDRL,video_ptr_l		; output low address 
	
	out	VIDEOPORT,video_tmp		; 1.bit 
	asr	video_tmp
	
	out	VIDEOPORT,video_tmp		; 2.bit 
	asr	video_tmp
	inc	video_ptr_l
	
	out	VIDEOPORT,video_tmp		; 3.bit 
	asr	video_tmp
	in	XL,DATAIN			; load next 6 pixels :X X 5 4 3 2 1 0
	
	out	VIDEOPORT,video_tmp		; 4.bit 
	asr	video_tmp
	
	out	VIDEOPORT,video_tmp		; 5.bit 
	ld	video_tmp,X

	; 9.byte
	
	
	out	VIDEOPORT,video_tmp		; 0.bit 
	asr	video_tmp
	out	ADDRL,video_ptr_l		; output low address 
	
	out	VIDEOPORT,video_tmp		; 1.bit 
	asr	video_tmp
	
	out	VIDEOPORT,video_tmp		; 2.bit 
	asr	video_tmp
	inc	video_ptr_l
	
	out	VIDEOPORT,video_tmp		; 3.bit 
	asr	video_tmp
	in	XL,DATAIN			; load next 6 pixels :X X 5 4 3 2 1 0
	
	out	VIDEOPORT,video_tmp		; 4.bit 
	asr	video_tmp
	
	out	VIDEOPORT,video_tmp		; 5.bit 
	ld	video_tmp,X

	; 10.byte
	
	
	out	VIDEOPORT,video_tmp		; 0.bit 
	asr	video_tmp
	out	ADDRL,video_ptr_l		; output low address 
	
	out	VIDEOPORT,video_tmp		; 1.bit 
	asr	video_tmp
	
	out	VIDEOPORT,video_tmp		; 2.bit 
	asr	video_tmp
	inc	video_ptr_l
	
	out	VIDEOPORT,video_tmp		; 3.bit 
	asr	video_tmp
	in	XL,DATAIN			; load next 6 pixels :X X 5 4 3 2 1 0
	
	out	VIDEOPORT,video_tmp		; 4.bit 
	asr	video_tmp
	
	out	VIDEOPORT,video_tmp		; 5.bit 
	ld	video_tmp,X

	; 11.byte
	
	
	out	VIDEOPORT,video_tmp		; 0.bit 
	asr	video_tmp
	out	ADDRL,video_ptr_l		; output low address 
	
	out	VIDEOPORT,video_tmp		; 1.bit 
	asr	video_tmp
	
	out	VIDEOPORT,video_tmp		; 2.bit 
	asr	video_tmp
	inc	video_ptr_l
	
	out	VIDEOPORT,video_tmp		; 3.bit 
	asr	video_tmp
	in	XL,DATAIN			; load next 6 pixels :X X 5 4 3 2 1 0
	
	out	VIDEOPORT,video_tmp		; 4.bit 
	asr	video_tmp
	
	out	VIDEOPORT,video_tmp		; 5.bit 
	ld	video_tmp,X

	; 12.byte
	
	
	out	VIDEOPORT,video_tmp		; 0.bit 
	asr	video_tmp
	out	ADDRL,video_ptr_l		; output low address 
	
	out	VIDEOPORT,video_tmp		; 1.bit 
	asr	video_tmp
	
	out	VIDEOPORT,video_tmp		; 2.bit 
	asr	video_tmp
	inc	video_ptr_l
	
	out	VIDEOPORT,video_tmp		; 3.bit 
	asr	video_tmp
	in	XL,DATAIN			; load next 6 pixels :X X 5 4 3 2 1 0
	
	out	VIDEOPORT,video_tmp		; 4.bit 
	asr	video_tmp
	
	out	VIDEOPORT,video_tmp		; 5.bit 
	ld	video_tmp,X

	; 13.byte
	
	
	out	VIDEOPORT,video_tmp		; 0.bit 
	asr	video_tmp
	out	ADDRL,video_ptr_l		; output low address 
	
	out	VIDEOPORT,video_tmp		; 1.bit 
	asr	video_tmp
	
	out	VIDEOPORT,video_tmp		; 2.bit 
	asr	video_tmp
	inc	video_ptr_l
	
	out	VIDEOPORT,video_tmp		; 3.bit 
	asr	video_tmp
	in	XL,DATAIN			; load next 6 pixels :X X 5 4 3 2 1 0
	
	out	VIDEOPORT,video_tmp		; 4.bit 
	asr	video_tmp
	
	out	VIDEOPORT,video_tmp		; 5.bit 
	ld	video_tmp,X

	; 14.byte
	
	
	out	VIDEOPORT,video_tmp		; 0.bit 
	asr	video_tmp
	out	ADDRL,video_ptr_l		; output low address 
	
	out	VIDEOPORT,video_tmp		; 1.bit 
	asr	video_tmp
	
	out	VIDEOPORT,video_tmp		; 2.bit 
	asr	video_tmp
	inc	video_ptr_l
	
	out	VIDEOPORT,video_tmp		; 3.bit 
	asr	video_tmp
	in	XL,DATAIN			; load next 6 pixels :X X 5 4 3 2 1 0
	
	out	VIDEOPORT,video_tmp		; 4.bit 
	asr	video_tmp
	
	out	VIDEOPORT,video_tmp		; 5.bit 
	ld	video_tmp,X

	; 15.byte
	
	
	out	VIDEOPORT,video_tmp		; 0.bit 
	asr	video_tmp
	out	ADDRL,video_ptr_l		; output low address 
	
	out	VIDEOPORT,video_tmp		; 1.bit 
	asr	video_tmp
	
	out	VIDEOPORT,video_tmp		; 2.bit 
	asr	video_tmp
	inc	video_ptr_l
	
	out	VIDEOPORT,video_tmp		; 3.bit 
	asr	video_tmp
	in	XL,DATAIN			; load next 6 pixels :X X 5 4 3 2 1 0
	
	out	VIDEOPORT,video_tmp		; 4.bit 
	asr	video_tmp
	
	out	VIDEOPORT,video_tmp		; 5.bit 
	ld	video_tmp,X

	; 16.byte
	
	
	out	VIDEOPORT,video_tmp		; 0.bit 
	asr	video_tmp
	out	ADDRL,video_ptr_l		; output low address 
	
	out	VIDEOPORT,video_tmp		; 1.bit 
	asr	video_tmp
	
	out	VIDEOPORT,video_tmp		; 2.bit 
	asr	video_tmp
	inc	video_ptr_l
	
	out	VIDEOPORT,video_tmp		; 3.bit 
	asr	video_tmp
	in	XL,DATAIN			; load next 6 pixels :X X 5 4 3 2 1 0
	
	out	VIDEOPORT,video_tmp		; 4.bit 
	asr	video_tmp
	
	out	VIDEOPORT,video_tmp		; 5.bit 
	ld	video_tmp,X

	; 17.byte
	
	
	out	VIDEOPORT,video_tmp		; 0.bit 
	asr	video_tmp
	out	ADDRL,video_ptr_l		; output low address 
	
	out	VIDEOPORT,video_tmp		; 1.bit 
	asr	video_tmp
	
	out	VIDEOPORT,video_tmp		; 2.bit 
	asr	video_tmp
	inc	video_ptr_l
	
	out	VIDEOPORT,video_tmp		; 3.bit 
	asr	video_tmp
	in	XL,DATAIN			; load next 6 pixels :X X 5 4 3 2 1 0
	
	out	VIDEOPORT,video_tmp		; 4.bit 
	asr	video_tmp
	
	out	VIDEOPORT,video_tmp		; 5.bit 
	ld	video_tmp,X

	; 18.byte
	
	
	out	VIDEOPORT,video_tmp		; 0.bit 
	asr	video_tmp
	out	ADDRL,video_ptr_l		; output low address 
	
	out	VIDEOPORT,video_tmp		; 1.bit 
	asr	video_tmp
	
	out	VIDEOPORT,video_tmp		; 2.bit 
	asr	video_tmp
	inc	video_ptr_l
	
	out	VIDEOPORT,video_tmp		; 3.bit 
	asr	video_tmp
	in	XL,DATAIN			; load next 6 pixels :X X 5 4 3 2 1 0
	
	out	VIDEOPORT,video_tmp		; 4.bit 
	asr	video_tmp
	
	out	VIDEOPORT,video_tmp		; 5.bit 
	ld	video_tmp,X

	; 19.byte
	
	
	out	VIDEOPORT,video_tmp		; 0.bit 
	asr	video_tmp
	out	ADDRL,video_ptr_l		; output low address 
	
	out	VIDEOPORT,video_tmp		; 1.bit 
	asr	video_tmp
	
	out	VIDEOPORT,video_tmp		; 2.bit 
	asr	video_tmp
	inc	video_ptr_l
	
	out	VIDEOPORT,video_tmp		; 3.bit 
	asr	video_tmp
	in	XL,DATAIN			; load next 6 pixels :X X 5 4 3 2 1 0
	
	out	VIDEOPORT,video_tmp		; 4.bit 
	asr	video_tmp
	
	out	VIDEOPORT,video_tmp		; 5.bit 
	ld	video_tmp,X

	; 20.byte
	
	
	out	VIDEOPORT,video_tmp		; 0.bit 
	asr	video_tmp
	out	ADDRL,video_ptr_l		; output low address 
	
	out	VIDEOPORT,video_tmp		; 1.bit 
	asr	video_tmp
	
	out	VIDEOPORT,video_tmp		; 2.bit 
	asr	video_tmp
	inc	video_ptr_l
	
	out	VIDEOPORT,video_tmp		; 3.bit 
	asr	video_tmp
	in	XL,DATAIN			; load next 6 pixels :X X 5 4 3 2 1 0
	
	out	VIDEOPORT,video_tmp		; 4.bit 
	asr	video_tmp
	
	out	VIDEOPORT,video_tmp		; 5.bit 
	ld	video_tmp,X

	; 21.byte
	
	
	out	VIDEOPORT,video_tmp		; 0.bit 
	asr	video_tmp
	out	ADDRL,video_ptr_l		; output low address 
	
	out	VIDEOPORT,video_tmp		; 1.bit 
	asr	video_tmp
	
	out	VIDEOPORT,video_tmp		; 2.bit 
	asr	video_tmp
	inc	video_ptr_l
	
	out	VIDEOPORT,video_tmp		; 3.bit 
	asr	video_tmp
	in	XL,DATAIN			; load next 6 pixels :X X 5 4 3 2 1 0
	
	out	VIDEOPORT,video_tmp		; 4.bit 
	asr	video_tmp
	
	out	VIDEOPORT,video_tmp		; 5.bit 
	ld	video_tmp,X

	; 22.byte
	
	
	out	VIDEOPORT,video_tmp		; 0.bit 
	asr	video_tmp
	out	ADDRL,video_ptr_l		; output low address 
	
	out	VIDEOPORT,video_tmp		; 1.bit 
	asr	video_tmp
	
	out	VIDEOPORT,video_tmp		; 2.bit 
	asr	video_tmp
	inc	video_ptr_l
	
	out	VIDEOPORT,video_tmp		; 3.bit 
	asr	video_tmp
	in	XL,DATAIN			; load next 6 pixels :X X 5 4 3 2 1 0
	
	out	VIDEOPORT,video_tmp		; 4.bit 
	asr	video_tmp
	
	out	VIDEOPORT,video_tmp		; 5.bit 
	ld	video_tmp,X

	; 23.byte
	
	
	out	VIDEOPORT,video_tmp		; 0.bit 
	asr	video_tmp
	out	ADDRL,video_ptr_l		; output low address 
	
	out	VIDEOPORT,video_tmp		; 1.bit 
	asr	video_tmp
	
	out	VIDEOPORT,video_tmp		; 2.bit 
	asr	video_tmp
	inc	video_ptr_l
	
	out	VIDEOPORT,video_tmp		; 3.bit 
	asr	video_tmp
	in	XL,DATAIN			; load next 6 pixels :X X 5 4 3 2 1 0
	
	out	VIDEOPORT,video_tmp		; 4.bit 
	asr	video_tmp
	
	out	VIDEOPORT,video_tmp		; 5.bit 
	ld	video_tmp,X

	; 24.byte
	
	
	out	VIDEOPORT,video_tmp		; 0.bit 
	asr	video_tmp
	out	ADDRL,video_ptr_l		; output low address 
	
	out	VIDEOPORT,video_tmp		; 1.bit 
	asr	video_tmp
	
	out	VIDEOPORT,video_tmp		; 2.bit 
	asr	video_tmp
	inc	video_ptr_l
	
	out	VIDEOPORT,video_tmp		; 3.bit 
	asr	video_tmp
	in	XL,DATAIN			; load next 6 pixels :X X 5 4 3 2 1 0
	
	out	VIDEOPORT,video_tmp		; 4.bit 
	asr	video_tmp
	
	out	VIDEOPORT,video_tmp		; 5.bit 
	ld	video_tmp,X

	; 25.byte
	
	
	out	VIDEOPORT,video_tmp		; 0.bit 
	asr	video_tmp
	out	ADDRL,video_ptr_l		; output low address 
	
	out	VIDEOPORT,video_tmp		; 1.bit 
	asr	video_tmp
	
	out	VIDEOPORT,video_tmp		; 2.bit 
	asr	video_tmp
	inc	video_ptr_l
	
	out	VIDEOPORT,video_tmp		; 3.bit 
	asr	video_tmp
	in	XL,DATAIN			; load next 6 pixels :X X 5 4 3 2 1 0
	
	out	VIDEOPORT,video_tmp		; 4.bit 
	asr	video_tmp
	
	out	VIDEOPORT,video_tmp		; 5.bit 
	ld	video_tmp,X

	; 26.byte
	
	
	out	VIDEOPORT,video_tmp		; 0.bit 
	asr	video_tmp
	out	ADDRL,video_ptr_l		; output low address 
	
	out	VIDEOPORT,video_tmp		; 1.bit 
	asr	video_tmp
	
	out	VIDEOPORT,video_tmp		; 2.bit 
	asr	video_tmp
	inc	video_ptr_l
	
	out	VIDEOPORT,video_tmp		; 3.bit 
	asr	video_tmp
	in	XL,DATAIN			; load next 6 pixels :X X 5 4 3 2 1 0
	
	out	VIDEOPORT,video_tmp		; 4.bit 
	asr	video_tmp
	
	out	VIDEOPORT,video_tmp		; 5.bit 
	ld	video_tmp,X

	; 27.byte
	
	
	out	VIDEOPORT,video_tmp		; 0.bit 
	asr	video_tmp
	out	ADDRL,video_ptr_l		; output low address 
	
	out	VIDEOPORT,video_tmp		; 1.bit 
	asr	video_tmp
	
	out	VIDEOPORT,video_tmp		; 2.bit 
	asr	video_tmp
	inc	video_ptr_l
	
	out	VIDEOPORT,video_tmp		; 3.bit 
	asr	video_tmp
	in	XL,DATAIN			; load next 6 pixels :X X 5 4 3 2 1 0
	
	out	VIDEOPORT,video_tmp		; 4.bit 
	asr	video_tmp
	
	out	VIDEOPORT,video_tmp		; 5.bit 
	ld	video_tmp,X

	; 28.byte
	
	
	out	VIDEOPORT,video_tmp		; 0.bit 
	asr	video_tmp
	out	ADDRL,video_ptr_l		; output low address 
	
	out	VIDEOPORT,video_tmp		; 1.bit 
	asr	video_tmp
	
	out	VIDEOPORT,video_tmp		; 2.bit 
	asr	video_tmp
	inc	video_ptr_l
	
	out	VIDEOPORT,video_tmp		; 3.bit 
	asr	video_tmp
	in	XL,DATAIN			; load next 6 pixels :X X 5 4 3 2 1 0
	
	out	VIDEOPORT,video_tmp		; 4.bit 
	asr	video_tmp
	
	out	VIDEOPORT,video_tmp		; 5.bit 
	ld	video_tmp,X

	; 29.byte
	
	
	out	VIDEOPORT,video_tmp		; 0.bit 
	asr	video_tmp
	out	ADDRL,video_ptr_l		; output low address 
	
	out	VIDEOPORT,video_tmp		; 1.bit 
	asr	video_tmp
	
	out	VIDEOPORT,video_tmp		; 2.bit 
	asr	video_tmp
	inc	video_ptr_l
	
	out	VIDEOPORT,video_tmp		; 3.bit 
	asr	video_tmp
	in	XL,DATAIN			; load next 6 pixels :X X 5 4 3 2 1 0
	
	out	VIDEOPORT,video_tmp		; 4.bit 
	asr	video_tmp
	
	out	VIDEOPORT,video_tmp		; 5.bit 
	ld	video_tmp,X

	; 30.byte
	
	
	out	VIDEOPORT,video_tmp		; 0.bit 
	asr	video_tmp
	out	ADDRL,video_ptr_l		; output low address 
	
	out	VIDEOPORT,video_tmp		; 1.bit 
	asr	video_tmp
	
	out	VIDEOPORT,video_tmp		; 2.bit 
	asr	video_tmp
	inc	video_ptr_l
	
	out	VIDEOPORT,video_tmp		; 3.bit 
	asr	video_tmp
	in	XL,DATAIN			; load next 6 pixels :X X 5 4 3 2 1 0
	
	out	VIDEOPORT,video_tmp		; 4.bit 
	asr	video_tmp
	
	out	VIDEOPORT,video_tmp		; 5.bit 
	ld	video_tmp,X

	; 31.byte
	
	
	out	VIDEOPORT,video_tmp		; 0.bit 
	asr	video_tmp
	out	ADDRL,video_ptr_l		; output low address 
	
	out	VIDEOPORT,video_tmp		; 1.bit 
	asr	video_tmp
	
	out	VIDEOPORT,video_tmp		; 2.bit 
	asr	video_tmp
	inc	video_ptr_l
	
	out	VIDEOPORT,video_tmp		; 3.bit 
	asr	video_tmp
	in	XL,DATAIN			; load next 6 pixels :X X 5 4 3 2 1 0
	
	out	VIDEOPORT,video_tmp		; 4.bit 
	asr	video_tmp
	
	out	VIDEOPORT,video_tmp		; 5.bit 
	ld	video_tmp,X

	; 32.byte
	
	
	out	VIDEOPORT,video_tmp		; 0.bit 
	asr	video_tmp
	out	ADDRL,video_ptr_l		; output low address 
	
	out	VIDEOPORT,video_tmp		; 1.bit 
	asr	video_tmp
	
	out	VIDEOPORT,video_tmp		; 2.bit 
	asr	video_tmp
	inc	video_ptr_l
	
	out	VIDEOPORT,video_tmp		; 3.bit 
	asr	video_tmp
	in	XL,DATAIN			; load next 6 pixels :X X 5 4 3 2 1 0
	
	out	VIDEOPORT,video_tmp		; 4.bit 
	asr	video_tmp
	
	out	VIDEOPORT,video_tmp		; 5.bit 
	ld	video_tmp,X

	; 33.byte
	
	
	out	VIDEOPORT,video_tmp		; 0.bit 
	asr	video_tmp
	out	ADDRL,video_ptr_l		; output low address 
	
	out	VIDEOPORT,video_tmp		; 1.bit 
	asr	video_tmp
	
	out	VIDEOPORT,video_tmp		; 2.bit 
	asr	video_tmp
	inc	video_ptr_l
	
	out	VIDEOPORT,video_tmp		; 3.bit 
	asr	video_tmp
	in	XL,DATAIN			; load next 6 pixels :X X 5 4 3 2 1 0
	
	out	VIDEOPORT,video_tmp		; 4.bit 
	asr	video_tmp
	
	out	VIDEOPORT,video_tmp		; 5.bit 
	ld	video_tmp,X

	; 34.byte
	
	
	out	VIDEOPORT,video_tmp		; 0.bit 
	asr	video_tmp
	out	ADDRL,video_ptr_l		; output low address 
	
	out	VIDEOPORT,video_tmp		; 1.bit 
	asr	video_tmp
	
	out	VIDEOPORT,video_tmp		; 2.bit 
	asr	video_tmp
	inc	video_ptr_l
	
	out	VIDEOPORT,video_tmp		; 3.bit 
	asr	video_tmp
	in	XL,DATAIN			; load next 6 pixels :X X 5 4 3 2 1 0
	
	out	VIDEOPORT,video_tmp		; 4.bit 
	asr	video_tmp
	
	out	VIDEOPORT,video_tmp		; 5.bit 
	ld	video_tmp,X

	; 35.byte
	
	
	out	VIDEOPORT,video_tmp		; 0.bit 
	asr	video_tmp
	out	ADDRL,video_ptr_l		; output low address 
	
	out	VIDEOPORT,video_tmp		; 1.bit 
	asr	video_tmp
	
	out	VIDEOPORT,video_tmp		; 2.bit 
	asr	video_tmp
	inc	video_ptr_l
	
	out	VIDEOPORT,video_tmp		; 3.bit 
	asr	video_tmp
	in	XL,DATAIN			; load next 6 pixels :X X 5 4 3 2 1 0
	
	out	VIDEOPORT,video_tmp		; 4.bit 
	asr	video_tmp
	
	out	VIDEOPORT,video_tmp		; 5.bit 
	ld	video_tmp,X

	; 36.byte
	
	
	out	VIDEOPORT,video_tmp		; 0.bit 
	asr	video_tmp
	out	ADDRL,video_ptr_l		; output low address 
	
	out	VIDEOPORT,video_tmp		; 1.bit 
	asr	video_tmp
	
	out	VIDEOPORT,video_tmp		; 2.bit 
	asr	video_tmp
	inc	video_ptr_l
	
	out	VIDEOPORT,video_tmp		; 3.bit 
	asr	video_tmp
	in	XL,DATAIN			; load next 6 pixels :X X 5 4 3 2 1 0
	
	out	VIDEOPORT,video_tmp		; 4.bit 
	asr	video_tmp
	
	out	VIDEOPORT,video_tmp		; 5.bit 
	ld	video_tmp,X

	; 37.byte
	
	
	out	VIDEOPORT,video_tmp		; 0.bit 
	asr	video_tmp
	out	ADDRL,video_ptr_l		; output low address 
	
	out	VIDEOPORT,video_tmp		; 1.bit 
	asr	video_tmp
	
	out	VIDEOPORT,video_tmp		; 2.bit 
	asr	video_tmp
	inc	video_ptr_l
	
	out	VIDEOPORT,video_tmp		; 3.bit 
	asr	video_tmp
	in	XL,DATAIN			; load next 6 pixels :X X 5 4 3 2 1 0
	
	out	VIDEOPORT,video_tmp		; 4.bit 
	asr	video_tmp
	
	out	VIDEOPORT,video_tmp		; 5.bit 
	ld	video_tmp,X

	; 38.byte
	
	
	out	VIDEOPORT,video_tmp		; 0.bit 
	asr	video_tmp
	out	ADDRL,video_ptr_l		; output low address 
	
	out	VIDEOPORT,video_tmp		; 1.bit 
	asr	video_tmp
	
	out	VIDEOPORT,video_tmp		; 2.bit 
	asr	video_tmp
	inc	video_ptr_l
	
	out	VIDEOPORT,video_tmp		; 3.bit 
	asr	video_tmp
	in	XL,DATAIN			; load next 6 pixels :X X 5 4 3 2 1 0
	
	out	VIDEOPORT,video_tmp		; 4.bit 
	asr	video_tmp
	
	out	VIDEOPORT,video_tmp		; 5.bit 
	ld	video_tmp,X

	; 39.byte
	
	
	out	VIDEOPORT,video_tmp		; 0.bit 
	asr	video_tmp
	out	ADDRL,video_ptr_l		; output low address 
	
	out	VIDEOPORT,video_tmp		; 1.bit 
	asr	video_tmp
	
	out	VIDEOPORT,video_tmp		; 2.bit 
	asr	video_tmp
	inc	video_ptr_l
	
	out	VIDEOPORT,video_tmp		; 3.bit 
	asr	video_tmp
	in	XL,DATAIN			; load next 6 pixels :X X 5 4 3 2 1 0
	
	out	VIDEOPORT,video_tmp		; 4.bit 
	asr	video_tmp
	
	out	VIDEOPORT,video_tmp		; 5.bit 
	ld	video_tmp,X

	; 40.byte
	
	
	out	VIDEOPORT,video_tmp		; 0.bit 
	asr	video_tmp
	out	ADDRL,video_ptr_l		; output low address 
	
	out	VIDEOPORT,video_tmp		; 1.bit 
	asr	video_tmp
	
	out	VIDEOPORT,video_tmp		; 2.bit 
	asr	video_tmp
	inc	video_ptr_l
	
	out	VIDEOPORT,video_tmp		; 3.bit 
	asr	video_tmp
	in	XL,DATAIN			; load next 6 pixels :X X 5 4 3 2 1 0
	
	out	VIDEOPORT,video_tmp		; 4.bit 
	asr	video_tmp
	
	out	VIDEOPORT,video_tmp		; 5.bit 
	ld	video_tmp,X

	; 41.byte
	
	
	out	VIDEOPORT,video_tmp		; 0.bit 
	asr	video_tmp
	out	ADDRL,video_ptr_l		; output low address 
	
	out	VIDEOPORT,video_tmp		; 1.bit 
	asr	video_tmp
	
	out	VIDEOPORT,video_tmp		; 2.bit 
	asr	video_tmp
	inc	video_ptr_l
	
	out	VIDEOPORT,video_tmp		; 3.bit 
	asr	video_tmp
	in	XL,DATAIN			; load next 6 pixels :X X 5 4 3 2 1 0
	
	out	VIDEOPORT,video_tmp		; 4.bit 
	asr	video_tmp
	
	out	VIDEOPORT,video_tmp		; 5.bit 
	ld	video_tmp,X

	; 42.byte
	
	
	out	VIDEOPORT,video_tmp		; 0.bit 
	asr	video_tmp
	out	ADDRL,video_ptr_l		; output low address 
	
	out	VIDEOPORT,video_tmp		; 1.bit 
	asr	video_tmp
	
	out	VIDEOPORT,video_tmp		; 2.bit 
	asr	video_tmp
	inc	video_ptr_l
	
	out	VIDEOPORT,video_tmp		; 3.bit 
	asr	video_tmp
	in	XL,DATAIN			; load next 6 pixels :X X 5 4 3 2 1 0
	
	out	VIDEOPORT,video_tmp		; 4.bit 
	asr	video_tmp
	
	out	VIDEOPORT,video_tmp		; 5.bit 
	ld	video_tmp,X

	; 43.byte
	
	
	out	VIDEOPORT,video_tmp		; 0.bit 
	asr	video_tmp
	out	ADDRL,video_ptr_l		; output low address 
	
	out	VIDEOPORT,video_tmp		; 1.bit 
	asr	video_tmp
	
	out	VIDEOPORT,video_tmp		; 2.bit 
	asr	video_tmp
	inc	video_ptr_l
	
	out	VIDEOPORT,video_tmp		; 3.bit 
	asr	video_tmp
	in	XL,DATAIN			; load next 6 pixels :X X 5 4 3 2 1 0
	
	out	VIDEOPORT,video_tmp		; 4.bit 
	asr	video_tmp
	
	out	VIDEOPORT,video_tmp		; 5.bit 
	ld	video_tmp,X

	; 44.byte
	
	
	out	VIDEOPORT,video_tmp		; 0.bit 
	asr	video_tmp
	out	ADDRL,video_ptr_l		; output low address 
	
	out	VIDEOPORT,video_tmp		; 1.bit 
	asr	video_tmp
	
	out	VIDEOPORT,video_tmp		; 2.bit 
	asr	video_tmp
	inc	video_ptr_l
	
	out	VIDEOPORT,video_tmp		; 3.bit 
	asr	video_tmp
	in	XL,DATAIN			; load next 6 pixels :X X 5 4 3 2 1 0
	
	out	VIDEOPORT,video_tmp		; 4.bit 
	asr	video_tmp
	
	out	VIDEOPORT,video_tmp		; 5.bit 
	ld	video_tmp,X

	; 45.byte
	
	
	out	VIDEOPORT,video_tmp		; 0.bit 
	asr	video_tmp
	out	ADDRL,video_ptr_l		; output low address 
	
	out	VIDEOPORT,video_tmp		; 1.bit 
	asr	video_tmp
	
	out	VIDEOPORT,video_tmp		; 2.bit 
	asr	video_tmp
	inc	video_ptr_l
	
	out	VIDEOPORT,video_tmp		; 3.bit 
	asr	video_tmp
	in	XL,DATAIN			; load next 6 pixels :X X 5 4 3 2 1 0
	
	out	VIDEOPORT,video_tmp		; 4.bit 
	asr	video_tmp
	
	out	VIDEOPORT,video_tmp		; 5.bit 
	ld	video_tmp,X

	; 46.byte
	
	
	out	VIDEOPORT,video_tmp		; 0.bit 
	asr	video_tmp
	out	ADDRL,video_ptr_l		; output low address 
	
	out	VIDEOPORT,video_tmp		; 1.bit 
	asr	video_tmp
	
	out	VIDEOPORT,video_tmp		; 2.bit 
	asr	video_tmp
	inc	video_ptr_l
	
	out	VIDEOPORT,video_tmp		; 3.bit 
	asr	video_tmp
	in	XL,DATAIN			; load next 6 pixels :X X 5 4 3 2 1 0
	
	out	VIDEOPORT,video_tmp		; 4.bit 
	asr	video_tmp
	
	out	VIDEOPORT,video_tmp		; 5.bit 
	ld	video_tmp,X


	; last byte on microline
	
	out	VIDEOPORT,video_tmp		; 0.bit 
	asr	video_tmp
	out	ADDRL,video_ADDRL
	
	out	VIDEOPORT,video_tmp		; 1.bit 
	asr	video_tmp
	
	out	VIDEOPORT,video_tmp		; 2.bit 
	asr	video_tmp
        out	ADDRH,video_ADDRH


	out	VIDEOPORT,video_tmp		; 3.bit 
	asr	video_tmp
	ldi	XL,16 			
	                                        ; skip also next 16 bytes => 16
						; after 48 shown bytes is 16 bytes video-memory gap
						; also correct for 16.000 MHz clock
						
	out	VIDEOPORT,video_tmp		; 4.bit 
	asr	video_tmp
		 
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
;    
;    PMDEmu - AVR based emulator of Czechoslovak microcomputer PMD-85 originally based on I8080
;    Copyright (C) 2003  Peter Chrenko <peto@kmit.sk>, J.Matusku 2178/21, 955 01 Topolcany, Slovakia
;
;    This program is free software; you can redistribute it and/or modify
;    it under the terms of the GNU General Public License as published by
;    the Free Software Foundation; either version 2 of the License, or
;    (at your option) any later version.
;
;    This program is distributed in the hope that it will be useful,
;    but WITHOUT ANY WARRANTY; without even the implied warranty of
;    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;    GNU General Public License for more details.
;
;    You should have received a copy of the GNU General Public License
;    along with this program; if not, write to the Free Software
;    Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
;

; KBD.PHP ; included from video.php
; test every microline (each 64 us), if keystroke

.macro STORE_KBD_REGS
		; SREG is saved in video_SREG register
		mov		video_CONTROLRAM,kbd_reg
		movw		video_ADDRL,ZL		; save Z

.endmacro

.macro RESTORE_KBD_REGS
		movw		ZL,video_ADDRL		; restore Z
		mov		kbd_reg,video_CONTROLRAM
		out		SREG,video_SREG		; must be
.endmacro

;################################################################
; routine executed if USART received some char 
		
		; SREG is saved in video_SREG register
		
		STORE_KBD_REGS

		in	video_tmp,UCSR0A
		in	kbd_reg,UDR0			; kb_data from USART
		
		andi	video_tmp, (1<<FE0)|(1<<UPE0)|(1<<DOR0)
		brne	kb_end				; USART receiver error detected

		cpi		kbd_reg,0xf0		; if 0xF0 received we know key is released, othervise is pressed.
		breq		f0_handle

		; kbd_reg = scan code (PC keyboard)
		; now we compute column and row of pressed/released key from its scan 
		bst		kbd_flags,F0_bit	; T := 0 if pressed, 1 if released 
		ldi		video_tmp,~(1<< F0_bit)
		and		kbd_flags,video_tmp	; clear it
		
		cpi		kbd_reg,0x11        	; ALT ?
		breq		alt_handle

		sbrc		kbd_flags,ALT_bit
		rjmp		alt_isnt_pressed
		brts		kb_end			; return if released
		
		; in kbd_reg is scan code (PC keyboard)
		cpi		kbd_reg,0x16		; ALT+1 ===> RESET PMD-85
		breq		reboot_pmd
		cpi		kbd_reg,0x76		; ALT+ESC ===> RESET PMD-85
		breq		reboot_pmd
		cpi		kbd_reg,0x1b		; ALT+S ===> dynamic stop
		breq		alt_s_handle
		cpi		kbd_reg,0x21		; ALT+C ===> color mode switch
		breq		alt_c_handle		
		rjmp		kb_end

alt_isnt_pressed:	

		cpi		kbd_reg,0x12		; left shift ?
		breq		shift_handle
		cpi		kbd_reg,0x59		; right shift ?	
		breq		shift_handle
		cpi		kbd_reg,0x84
		brsh		kb_end			; not in look-up table --> ignore key
		cpi		kbd_reg,0x14		; CTRL ?
		breq		stop_handle
		
		; kbd_reg = SCAN code of pressed (T=0)/released(T=1) key
		; T <=>  0 == pressed, 1 == released
		
		

		ldi		ZH, high(kb_lookup << 1)
		ldi		ZL, low(kb_lookup << 1)
		add		ZL, kbd_reg 
		adc		ZH, _zero
		
		; Z := kb_lookup + 1*SCAN_CODE
		lpm		video_tmp,Z
		ldi		ZL, low ( kb_cols )
		ldi		ZH, high ( kb_cols )
		
		
		cpi		kbd_reg,0x5A        ; second EOL (ENTER) handle
		brne	_no_enter_hit	
				
		; ative/deactive also EOL on r4:13
		ldd		kbd_reg, Z + 13 	; load 13th column 
		bld		kbd_reg,4 		; copy bit , EOL2 (4.bit)
		std		Z + 13,kbd_reg  	; store 13th column	
		


_no_enter_hit:
		mov	kbd_reg,video_tmp
		andi	video_tmp,0x0f 			; row mask: 0=invalid, 1,2,4,8 and 15 (must ---> 16)   - valid
		breq	kb_end  			; 0 ==  not used key 
		
		swap	kbd_reg
		andi	kbd_reg,0x0f
		
		; now:
		; video_tmp = part of row mask
		; kbd_reg = column
		
		
		cpi	video_tmp,14  ; 5th row? clear carry  if video_tmp == 15, set carry if video_tmp < 15
		sbci	video_tmp,-1  ; calculate with carry ;) 
		
		add		ZL, kbd_reg      ; Z := kb_cols + kbd_reg (column address)

		ld		kbd_reg,Z
		
		or		kbd_reg,video_tmp
		brts		kb_write_one
		com		video_tmp
		and		kbd_reg,video_tmp
kb_write_one:	st		Z,kbd_reg
		

kb_end:
		RESTORE_KBD_REGS
		reti		

f0_handle:
		set
		bld		kbd_flags, F0_bit 		; store it (released/pressed bit)
		rjmp		kb_end	

shift_handle:
		bld		kbd_flags,SHIFT_bit		; store SHIFT bit (5. bit)
		rjmp		kb_end		

alt_handle:
		bld		kbd_flags,ALT_bit	; store ALT bit, ALT := T	
		rjmp		kb_end

stop_handle:
		bld		kbd_flags,6	     	; copy to STOP bit
		rjmp		kb_end	     		; end			

reboot_pmd:	
		rjmp		PMD_RESET



alt_s_handle:
		brts		kb_end			
		lds		kbd_reg,stop_flag
		com		kbd_reg
		sts		stop_flag,kbd_reg
		
		breq		kb_end		; if stop_flag is zero
		
		RESTORE_KBD_REGS		; if stop_flag is non zero ===> dynamic stop
		sei
		
		rcall		video_osd	; print intro text	
		;rcall		video_scrollup
		reti

alt_c_handle:	; switch colors scheme
		RESTORE_KBD_REGS		 
		sei
		push		ZL
		push		ZH
		push		YL
		push		YH
		in		ZL,SREG
		push		ZL

		ldi		ZH,high(blink_lookup_table)
		ldi		ZL,low(blink_lookup_table)	; zero
		ldi		YH,0x80				; invert 7th bit 
switch_attributtes:
		ld		YL,Z
		eor		YL,YH
		st		Z+,YL
		cpi		ZH,high(blink_lookup_table+0x200)
		brne		switch_attributtes	

		
		pop		ZL
		out		SREG,ZL
		pop		YH
		pop		YL
		pop		ZH
		pop		ZL

		ret

	
text_info:	.db	"            P= PJ9P B  M= E.5E U  D= TM5T I  -= EA O L  8= RT0@ T  5=  U1K :  -= CS M    1= HKTI 2   = RUOT 3  E= E P. .  M= N2OS 4  U= K1LK .  L= O7C  2  A=  8A  0  T=  /N  0  O=  2Y  8  R=  1              2          1          :          0          6            "

	

	; OSD routines

video_osd:
	.def	ptrl	=	r22
	.def	ptrh	=	r23
	.equ	chr_space = 0x40
	

	push	ptrl
	push	ptrh
	push	YL
	push	YH
	push	ZL
	push	ZH
	push	r24
	push	r25
	
	push	kbd_portC		; disable sound
	mov	kbd_portC,_zero
	
	in ZL,CONTROLRAM
	push	ZL
	in ZL,ADDRL	
	push	ZL
	in ZL,ADDRH
	push	ZL
	in ZL,DATADIR	
	push	ZL
	in ZL,DATAOUT
	push	ZL
	in	ZL,SREG
	push	ZL

osd_read:
	
	ldi	ptrl,low( 0xD18C  )	
	ldi	ptrh,high ( 0xD18C )
	
	out	DATADIR,_zero		; input for read operation
	MEMRD_active

	ldi	YH, 110	
osd_read_y:
	out	ADDRH,ptrh
	ldi	YL, 24
osd_read_x:	
	out	ADDRL,ptrl
	inc	ptrl
	dec	YL
		in	ZL,DATAIN
	push	ZL
	
	brne	osd_read_x
	
	subi	ptrl,low(-40)
	sbci	ptrh,high(-40)

        dec	YH
	brne	osd_read_y
	
	; here we print text	
	ldi	ptrl,low( 0xD18C  )	
	ldi	ptrh,high ( 0xD18C )
	ldi	ZL,low ( text_info * 2 )
	ldi	ZH,high( text_info * 2 )

osd_print_char_loop:
	lpm	YL,Z+

	;compute char address
	clr	YH
	lsl	YL		; char is always with 7th bit cleared
	lsl	YL
	rol	YH
	lsl	YL
	rol	YH		; Y *= 8
	subi	YH,-133		; Y += 0x8500
	
	ldi	r25,9		; 9+1=10 microlines
	ldi	r24, chr_space
	rjmp	osd_blank
osd_one_char:
	out	ADDRH,YH
	out	ADDRL,YL
	adiw	YL,1
		in	r24,DATAIN
	ori	r24,0x40	; add bright attribute
osd_blank:
	
	;WRITE(ptrh,ptrl,r24):

	out	DATAOUT,r24
	MEMRD_deactive
	out	DATADIR,_255
	
		out		ADDRL,ptrl    ; output 16 bit address 
		out		ADDRH,ptrh
	rjmp PC+1		;MDELAY: inserted two wait cycles

		MEMWR_active


	subi	ptrl,low(-(64))

	sbci	ptrh,high(-(64))
		
		MEMWR_deactive

	
	nop		;MDELAY: inserted one wait cycle
		
		out		DATADIR,_zero			; DATAOUT input
		MEMRD_active

	;END OF WRITE
	dec	r25
	brne	osd_one_char
	ldi	r24, chr_space	; 10th microline
	
	;WRITE(ptrh,ptrl,r24):

	out	DATAOUT,r24
	MEMRD_deactive
	out	DATADIR,_255
	
		out		ADDRL,ptrl    ; output 16 bit address 
		out		ADDRH,ptrh
	rjmp PC+1		;MDELAY: inserted two wait cycles

		MEMWR_active


	subi	ptrl,low(-(64))

	sbci	ptrh,high(-(64))
		
		MEMWR_deactive

	
	nop		;MDELAY: inserted one wait cycle
		
		out		DATADIR,_zero			; DATAOUT input
		MEMRD_active

	;END OF WRITE
	
	cpi	ptrh,high(0xD18C + 11*64*10)
	brlo	osd_print_char_loop

	subi	ptrl, low(7039)	
	sbci	ptrh, high(7039)	
	
	cpi	ptrl, low(0xD18C + 24)
	brne	osd_print_char_loop
	

	

dynamic_stop:
		lds		ZL,stop_flag
		cpse		ZL,_zero	
		rjmp		dynamic_stop



osd_write:
	ldi	ptrl,low( 60643 )	
	ldi	ptrh,high ( 60643 )

	ldi	YH, 110	
osd_write_y:	
	ldi	YL, 24
osd_write_x:
	pop	ZL
	
	;WRITE(ptrh,ptrl,ZL):

	out	DATAOUT,ZL
	MEMRD_deactive
	out	DATADIR,_255
	
		out		ADDRL,ptrl    ; output 16 bit address 
		out		ADDRH,ptrh
	rjmp PC+1		;MDELAY: inserted two wait cycles

		MEMWR_active


	subi	ptrl,low(-(-1))

	sbci	ptrh,high(-(-1))
		
		MEMWR_deactive

	
	nop		;MDELAY: inserted one wait cycle

	;END OF WRITE
	
	dec	YL
	brne	osd_write_x	

	subi	ptrl,low(40)
	sbci	ptrh,high(40)

	dec	YH
	brne	osd_write_y	

	pop	ZL
	out	SREG,ZL
	pop	ZL
	out	DATAOUT,ZL
	pop	ZL
	out	DATADIR,ZL
	pop	ZL
	out	ADDRH,ZL
	pop	ZL
	out	ADDRL,ZL
	pop	ZL
	out	CONTROLRAM,ZL

	pop	kbd_portC
	
	pop	r25
	pop	r24
	pop	ZH
	pop	ZL
	pop	YH
	pop	YL
	pop	ptrh
	pop	ptrl
	ret





		
		


after_reset:			; continue RESET procedure

				sts	last_count,ZL
				sts	stop_flag, _zero
				sts	mgf_pointer+2,_zero

				;------------ USART 8251 transmitter speed emulation - for game HLIPA
				
				ldi	ZL,143
				out	OCR2,ZL

				ldi	ZL,0b00001101		; run TCCR2 at CLK/1024, CTC mode 
				out	TCCR2,ZL		; this set TxRDY for first write UDR
				
				;------------ Load look-up parity table

				ldi	ZH,high(parity_table)
				ldi	ZL,low(parity_table)
calculate_new_byte_parity:				
				mov 	r0,ZL
				swap 	r0
				eor 	r0,ZL
				mov	r1,r0
				lsr	r1	
				lsr	r1
				eor	r0,r1
				mov	r1,r0
				lsr	r1
				eor	r0,r1
				com	r0	
				
				
				st	Z+,r0
				cp	ZL,_zero
				brne	calculate_new_byte_parity

				
				;---------------- inicialize video subsystem -------------------------------
				; Timer3 on ATmega128
				
				ldi		r30,0b00011001		; divide 1; FAST PWM mode; ICR3 = TOP; mode = 14
				sts		TCCR3B,r30
				out		TCCR1B,r30		; T1

				ldi		r30,0b10000010		; inverted PWM for channel T3/A, mode = 14
				sts		TCCR3A,r30
				ldi		r30,0b00000010		; mode = 14 T1
				out		TCCR1A,r30
				
				ldi		r30,high(1023)		; ICR1 = ICR3 = TOP = 64 us
				sts		ICR3H,r30
				out		ICR1H,r30

				ldi		r30,low(1023)	
				sts		ICR3L,r30
				out		ICR1L,r30


				ldi		r30,high(948)	 ; when sync goes low 
				sts		OCR3AH,r30			 ; channel T3/A
				ldi		r30,low(948)	
				sts		OCR3AL,r30

				
				ldi		r30,high(131)	 ; when start video generation routine (T3/A)
				out		OCR1AH,r30
				ldi		r30,low(131)	
				out		OCR1AL,r30
				
				mov		video_state,_zero		 ; video_state := 0
				mov		video_ptr_l,_zero		 ; video address := 0xc000
				ldi		video_ptr_h,0xc0			
				
				; blink subsystem
				.equ	blink_period = 50			 ;	1 Hz => 50 halfscreens
				ldi		ZL,blink_period
				sts		blink_counter,ZL
				ldi		ZL,0				 ; precompute blink lookup table	
				ldi		ZH, high(blink_lookup_table) 
				ldi		XH, high(blink_lookup_table) ^ 1 ; mask_register

blink_c0:		
				mov		video_tmp,ZL
				rol		video_tmp
				st		Z+,video_tmp
				cp		ZL,_zero
				brne		blink_c0		
				
				
blink_c1:		
				mov		video_tmp,ZL
				rol		video_tmp
				brcc		PC+2
				mov		video_tmp,_zero
				st		Z+,video_tmp
				cp		ZL,_zero
				brne		blink_c1		

				ldi		ZH,high(push_a_table)   
				ldi		ZL,0

push_a_cycle:
				ldi		PSW,PMD_PSW
				bst		ZL,0
				bld		PSW,0    ; CY copied
				bst		ZL,1
				bld		PSW,6    ; Z copied
				bst		ZL,2
				bld		PSW,7	; S copied
				bst		ZL,5
				bld		PSW,4	; A copied

				st		Z+,PSW
				cp		ZL,_zero
				brne		push_a_cycle


pop_a_cycle:

				ldi		PSW,0x80; I = 1, we must have enabled interrupts
				bst		ZL,0  	; CY copied
				bld		PSW,0
				bst		ZL,6    ; Z copied
				bld		PSW,1
				bst		ZL,7	; S copied
				bld		PSW,2
				bst		ZL,4	; A copied
				bld		PSW,5


				st		Z+,PSW
				cp		ZL,_zero
				brne		pop_a_cycle




				ldi		r30,(1<<OCIE1A)			; enable interrupt on OCR3A (video routine)
				out		TIMSK,r30


			; download ROM firmware (PMD-85 monitor) to SRAM location 0x8000 - 0x8ffff 	
			
			.equ	monitor_start	=	0x8000
			.equ	monitor_go	=	0x8000
			.equ	monitor_length  =       0x1000
			

				ldi		ZL, low( monitor_start )	; address in PMD-85
				ldi		ZH, high( monitor_start ) 
				

				out		DATADIR,_255		; DATA bus = output direction

				

_monitor_download:				
				out		EEARL,ZL		; BAD TRICK - EEPROM IS ADDRESSING LOWEST 12 BITS OF ADDRESS
				out		EEARH,ZH		

				sbi		EECR,EERE
				in		A,EEDR
				
				
	;WRITE(ZH,ZL,A):

	out	DATAOUT,A
	
		out		ADDRL,ZL    ; output 16 bit address 
		out		ADDRH,ZH
	rjmp PC+1		;MDELAY: inserted two wait cycles

		MEMWR_active


	adiw	ZL,1
		
		MEMWR_deactive

	
	nop		;MDELAY: inserted one wait cycle

	;END OF WRITE
				
				cpi		ZH, high(monitor_start+monitor_length)  ; high of (end address + 1)
				brlo		_monitor_download

						



PMD_RESET:			
				MEMWR_deactive					; cold reset by keyboard (from kbd.asm)


	                        ; SHIFT & STOP & ALT released
		      		; f0_received = false

				ldi		ZL,(1<<SHIFT_bit)|(1<<STOP_bit)|(1<<ALT_bit)
				mov		kbd_flags,ZL
				
				
				ldi		ZL, low ( kb_cols )  		; inicialize PMD keyboard model
				ldi		ZH, high ( kb_cols )
				ldi		YH, 0x1f			; 0b11111    
				ldi		YL,16
				
kb_inic:			st		Z+,YH				; 16 keyboard cols set to 0x1f	
				dec		YL
				brne	kb_inic


				ldi		r30, low(stack_top-1)               	; AVR STACK
				ldi		r31, high(stack_top-1)               	
				cli						; disable if goes from kbd.asm
				out	   	SPL,r30
				out		SPH,r31				; STACK POINTER SET
				sei						; enable interrupt
								
				
				out		DATADIR,_zero			; DATA bus = input direction
				
				MEMRD_active
				
				mov		kbd_portC,_zero
				sts		kbd_ports + 2,_zero		; SPEAKER Off
				

				ldi		_PCL,low(monitor_go)
				ldi		_PCH,high(monitor_go)  		; after RESET 
				ldi		PSW,0x80			; I = 1, we must have enabled interrupts


_nop:			
_none:
_ei: 
_mov_aa:    
_mov_bb: 
_mov_hh:	
_mov_ll:
_mov_cc: 
_mov_dd:	
_mov_ee:
  _di:

;------------- begin of instruction cycle without handling PSW & flags ------

i_cycle:
				out		ADDRL,_PCL
				out		ADDRH,_PCH
				adiw		_PCL,1			; wait a minute
				ldi		ZH, high(i_table)      
								in		ZL, DATAIN
				ijmp					; make instruction cycles



;------------- begin of instruction cycle with handling PSW & flags ------

set_flags:		
				in		PSW,SREG
save_parity:
				
				out		ADDRL,_PCL
				out		ADDRH,_PCH
				mov		_last_result,A		; for calculate Parity bit
				adiw		_PCL,1			; wait a minute
				ldi		ZH, high(i_table)      
								
				in		ZL, DATAIN
				ijmp					; make instruction cycles

clr_CH:			

				out		ADDRL,_PCL
				out		ADDRH,_PCH

				in		PSW,SREG
				andi		PSW,~((1<<ATMEL_C)|(1<<ATMEL_H))
				mov		_last_result,A		; for calculate Parity bit
				
				adiw		_PCL,1			; wait a minute
				ldi		ZH, high(i_table)      

								in		ZL, DATAIN
				ijmp					; make instruction cycles


;------------- begin of instruction cycle with substractions handling PSW & flags ------

set_flags_sub:		
		 		 mov	_last_result,A
set_flags_cmp:		



				out		ADDRL,_PCL
				out		ADDRH,_PCH

				ldi		ZL,1<< ATMEL_H		; after substraction invert half-carry bit(H)
				in		PSW,SREG
				eor		PSW,ZL
				adiw		_PCL,1			; wait a minute
				ldi		ZH, high(i_table)      
								in		ZL, DATAIN
				ijmp					; make instruction cycles

				
;-------------------------------------------------------------------------------------------------------------------------
				
							





		

;***********************************************************************************************
;***********************************************************************************************
;***********************************************************************************************
;***********************************************************************************************

_inr_a:

		bst		PSW,0 		; save CY
		ldi		ZL,1
		add		A,ZL
		in		PSW,SREG
		bld		PSW,0 		; restore CY
	        
rjmp	i_cycle

_dcr_a:

		 bst		PSW,0 		; save CY
		 ldi		ZL,1
		 sub		A,ZL

		 in		PSW,SREG
		 bld		PSW,0 		; restore CY
		 
rjmp	i_cycle

_mvi_a:

		out		ADDRL,_PCL
		out		ADDRH,_PCH 
		adiw		_PCL,1 
		
		in		A,DATAIN 
		
rjmp	i_cycle

_mov_am:

		out		ADDRL,L
		out		ADDRH,H
		rjmp PC+1		;MDELAY: inserted two wait cycles

                in		A,DATAIN
	
	
rjmp	i_cycle

_mov_ma:

	;WRITE(H,L,A):

	out	DATAOUT,A
	MEMRD_deactive
	out	DATADIR,_255
	
		out		ADDRL,L    ; output 16 bit address 
		out		ADDRH,H

		sbrc		H,7	    ; skip if address < 0x8000
		sbrc		H,6	    ; skip if 6th bit is clear



		MEMWR_active

		
		MEMWR_deactive

	
	nop		;MDELAY: inserted one wait cycle
		
		out		DATADIR,_zero			; DATAOUT input
		MEMRD_active

	;END OF WRITE

rjmp	i_cycle

_add_a:

	     add A,A
	     
rjmp	set_flags

_adc_a:

	     ror	PSW
	     adc 	A,A
	     
rjmp	set_flags

_sub_a:

		 
		 sub	A,A
		 rjmp	set_flags_sub

		 
_sbb_a:

		 ror	PSW
		 sez		; must be	
		 sbc	A,A
		 rjmp	set_flags_sub
		 
_ana_a:
and		A,A		
rjmp	clr_CH

_ora_a:

   		or		A,A
   		
rjmp	clr_CH

_xra_a:

   		eor		A,A
   		
rjmp	clr_CH

_cmp_a:

			mov	ZH,A
			sub	ZH,A
			mov	_last_result,ZH
			rjmp	set_flags_cmp
	     
_inr_b:

		bst		PSW,0 		; save CY
		ldi		ZL,1
		add		B,ZL
		in		PSW,SREG
		bld		PSW,0 		; restore CY
	        
rjmp	i_cycle

_dcr_b:

		 bst		PSW,0 		; save CY
		 ldi		ZL,1
		 sub		B,ZL

		 in		PSW,SREG
		 bld		PSW,0 		; restore CY
		 
rjmp	i_cycle

_mvi_b:

		out		ADDRL,_PCL
		out		ADDRH,_PCH 
		adiw		_PCL,1 
		
		in		B,DATAIN 
		
rjmp	i_cycle

_mov_bm:

		out		ADDRL,L
		out		ADDRH,H
		rjmp PC+1		;MDELAY: inserted two wait cycles

                in		B,DATAIN
	
	
rjmp	i_cycle

_mov_mb:

	;WRITE(H,L,B):

	out	DATAOUT,B
	MEMRD_deactive
	out	DATADIR,_255
	
		out		ADDRL,L    ; output 16 bit address 
		out		ADDRH,H

		sbrc		H,7	    ; skip if address < 0x8000
		sbrc		H,6	    ; skip if 6th bit is clear



		MEMWR_active

		
		MEMWR_deactive

	
	nop		;MDELAY: inserted one wait cycle
		
		out		DATADIR,_zero			; DATAOUT input
		MEMRD_active

	;END OF WRITE

rjmp	i_cycle

_add_b:

	     add A,B
	     
rjmp	set_flags

_adc_b:

	     ror	PSW
	     adc 	A,B
	     
rjmp	set_flags

_sub_b:

		 
		 sub	A,B
		 rjmp	set_flags_sub

		 
_sbb_b:

		 ror	PSW
		 sez		; must be	
		 sbc	A,B
		 rjmp	set_flags_sub
		 
_ana_b:
and		A,B		
rjmp	clr_CH

_ora_b:

   		or		A,B
   		
rjmp	clr_CH

_xra_b:

   		eor		A,B
   		
rjmp	clr_CH

_cmp_b:

			mov	ZH,A
			sub	ZH,B
			mov	_last_result,ZH
			rjmp	set_flags_cmp
	     
_inr_c:

		bst		PSW,0 		; save CY
		ldi		ZL,1
		add		C,ZL
		in		PSW,SREG
		bld		PSW,0 		; restore CY
	        
rjmp	i_cycle

_dcr_c:

		 bst		PSW,0 		; save CY
		 ldi		ZL,1
		 sub		C,ZL

		 in		PSW,SREG
		 bld		PSW,0 		; restore CY
		 
rjmp	i_cycle

_mvi_c:

		out		ADDRL,_PCL
		out		ADDRH,_PCH 
		adiw		_PCL,1 
		
		in		C,DATAIN 
		
rjmp	i_cycle

_mov_cm:

		out		ADDRL,L
		out		ADDRH,H
		rjmp PC+1		;MDELAY: inserted two wait cycles

                in		C,DATAIN
	
	
rjmp	i_cycle

_mov_mc:

	;WRITE(H,L,C):

	out	DATAOUT,C
	MEMRD_deactive
	out	DATADIR,_255
	
		out		ADDRL,L    ; output 16 bit address 
		out		ADDRH,H

		sbrc		H,7	    ; skip if address < 0x8000
		sbrc		H,6	    ; skip if 6th bit is clear



		MEMWR_active

		
		MEMWR_deactive

	
	nop		;MDELAY: inserted one wait cycle
		
		out		DATADIR,_zero			; DATAOUT input
		MEMRD_active

	;END OF WRITE

rjmp	i_cycle

_add_c:

	     add A,C
	     
rjmp	set_flags

_adc_c:

	     ror	PSW
	     adc 	A,C
	     
rjmp	set_flags

_sub_c:

		 
		 sub	A,C
		 rjmp	set_flags_sub

		 
_sbb_c:

		 ror	PSW
		 sez		; must be	
		 sbc	A,C
		 rjmp	set_flags_sub
		 
_ana_c:
and		A,C		
rjmp	clr_CH

_ora_c:

   		or		A,C
   		
rjmp	clr_CH

_xra_c:

   		eor		A,C
   		
rjmp	clr_CH

_cmp_c:

			mov	ZH,A
			sub	ZH,C
			mov	_last_result,ZH
			rjmp	set_flags_cmp
	     
_inr_d:

		bst		PSW,0 		; save CY
		ldi		ZL,1
		add		D,ZL
		in		PSW,SREG
		bld		PSW,0 		; restore CY
	        
rjmp	i_cycle

_dcr_d:

		 bst		PSW,0 		; save CY
		 ldi		ZL,1
		 sub		D,ZL

		 in		PSW,SREG
		 bld		PSW,0 		; restore CY
		 
rjmp	i_cycle

_mvi_d:

		out		ADDRL,_PCL
		out		ADDRH,_PCH 
		adiw		_PCL,1 
		
		in		D,DATAIN 
		
rjmp	i_cycle

_mov_dm:

		out		ADDRL,L
		out		ADDRH,H
		rjmp PC+1		;MDELAY: inserted two wait cycles

                in		D,DATAIN
	
	
rjmp	i_cycle

_mov_md:

	;WRITE(H,L,D):

	out	DATAOUT,D
	MEMRD_deactive
	out	DATADIR,_255
	
		out		ADDRL,L    ; output 16 bit address 
		out		ADDRH,H

		sbrc		H,7	    ; skip if address < 0x8000
		sbrc		H,6	    ; skip if 6th bit is clear



		MEMWR_active

		
		MEMWR_deactive

	
	nop		;MDELAY: inserted one wait cycle
		
		out		DATADIR,_zero			; DATAOUT input
		MEMRD_active

	;END OF WRITE

rjmp	i_cycle

_add_d:

	     add A,D
	     
rjmp	set_flags

_adc_d:

	     ror	PSW
	     adc 	A,D
	     
rjmp	set_flags

_sub_d:

		 
		 sub	A,D
		 rjmp	set_flags_sub

		 
_sbb_d:

		 ror	PSW
		 sez		; must be	
		 sbc	A,D
		 rjmp	set_flags_sub
		 
_ana_d:
and		A,D		
rjmp	clr_CH

_ora_d:

   		or		A,D
   		
rjmp	clr_CH

_xra_d:

   		eor		A,D
   		
rjmp	clr_CH

_cmp_d:

			mov	ZH,A
			sub	ZH,D
			mov	_last_result,ZH
			rjmp	set_flags_cmp
	     
_inr_e:

		bst		PSW,0 		; save CY
		ldi		ZL,1
		add		E,ZL
		in		PSW,SREG
		bld		PSW,0 		; restore CY
	        
rjmp	i_cycle

_dcr_e:

		 bst		PSW,0 		; save CY
		 ldi		ZL,1
		 sub		E,ZL

		 in		PSW,SREG
		 bld		PSW,0 		; restore CY
		 
rjmp	i_cycle

_mvi_e:

		out		ADDRL,_PCL
		out		ADDRH,_PCH 
		adiw		_PCL,1 
		
		in		E,DATAIN 
		
rjmp	i_cycle

_mov_em:

		out		ADDRL,L
		out		ADDRH,H
		rjmp PC+1		;MDELAY: inserted two wait cycles

                in		E,DATAIN
	
	
rjmp	i_cycle

_mov_me:

	;WRITE(H,L,E):

	out	DATAOUT,E
	MEMRD_deactive
	out	DATADIR,_255
	
		out		ADDRL,L    ; output 16 bit address 
		out		ADDRH,H

		sbrc		H,7	    ; skip if address < 0x8000
		sbrc		H,6	    ; skip if 6th bit is clear



		MEMWR_active

		
		MEMWR_deactive

	
	nop		;MDELAY: inserted one wait cycle
		
		out		DATADIR,_zero			; DATAOUT input
		MEMRD_active

	;END OF WRITE

rjmp	i_cycle

_add_e:

	     add A,E
	     
rjmp	set_flags

_adc_e:

	     ror	PSW
	     adc 	A,E
	     
rjmp	set_flags

_sub_e:

		 
		 sub	A,E
		 rjmp	set_flags_sub

		 
_sbb_e:

		 ror	PSW
		 sez		; must be	
		 sbc	A,E
		 rjmp	set_flags_sub
		 
_ana_e:
and		A,E		
rjmp	clr_CH

_ora_e:

   		or		A,E
   		
rjmp	clr_CH

_xra_e:

   		eor		A,E
   		
rjmp	clr_CH

_cmp_e:

			mov	ZH,A
			sub	ZH,E
			mov	_last_result,ZH
			rjmp	set_flags_cmp
	     
_inr_h:

		bst		PSW,0 		; save CY
		ldi		ZL,1
		add		H,ZL
		in		PSW,SREG
		bld		PSW,0 		; restore CY
	        
rjmp	i_cycle

_dcr_h:

		 bst		PSW,0 		; save CY
		 ldi		ZL,1
		 sub		H,ZL

		 in		PSW,SREG
		 bld		PSW,0 		; restore CY
		 
rjmp	i_cycle

_mvi_h:

		out		ADDRL,_PCL
		out		ADDRH,_PCH 
		adiw		_PCL,1 
		
		in		H,DATAIN 
		
rjmp	i_cycle

_mov_hm:

		out		ADDRL,L
		out		ADDRH,H
		rjmp PC+1		;MDELAY: inserted two wait cycles

                in		H,DATAIN
	
	
rjmp	i_cycle

_mov_mh:

	;WRITE(H,L,H):

	out	DATAOUT,H
	MEMRD_deactive
	out	DATADIR,_255
	
		out		ADDRL,L    ; output 16 bit address 
		out		ADDRH,H

		sbrc		H,7	    ; skip if address < 0x8000
		sbrc		H,6	    ; skip if 6th bit is clear



		MEMWR_active

		
		MEMWR_deactive

	
	nop		;MDELAY: inserted one wait cycle
		
		out		DATADIR,_zero			; DATAOUT input
		MEMRD_active

	;END OF WRITE

rjmp	i_cycle

_add_h:

	     add A,H
	     
rjmp	set_flags

_adc_h:

	     ror	PSW
	     adc 	A,H
	     
rjmp	set_flags

_sub_h:

		 
		 sub	A,H
		 rjmp	set_flags_sub

		 
_sbb_h:

		 ror	PSW
		 sez		; must be	
		 sbc	A,H
		 rjmp	set_flags_sub
		 
_ana_h:
and		A,H		
rjmp	clr_CH

_ora_h:

   		or		A,H
   		
rjmp	clr_CH

_xra_h:

   		eor		A,H
   		
rjmp	clr_CH

_cmp_h:

			mov	ZH,A
			sub	ZH,H
			mov	_last_result,ZH
			rjmp	set_flags_cmp
	     
_inr_l:

		bst		PSW,0 		; save CY
		ldi		ZL,1
		add		L,ZL
		in		PSW,SREG
		bld		PSW,0 		; restore CY
	        
rjmp	i_cycle

_dcr_l:

		 bst		PSW,0 		; save CY
		 ldi		ZL,1
		 sub		L,ZL

		 in		PSW,SREG
		 bld		PSW,0 		; restore CY
		 
rjmp	i_cycle

_mvi_l:

		out		ADDRL,_PCL
		out		ADDRH,_PCH 
		adiw		_PCL,1 
		
		in		L,DATAIN 
		
rjmp	i_cycle

_mov_lm:

		out		ADDRL,L
		out		ADDRH,H
		rjmp PC+1		;MDELAY: inserted two wait cycles

                in		L,DATAIN
	
	
rjmp	i_cycle

_mov_ml:

	;WRITE(H,L,L):

	out	DATAOUT,L
	MEMRD_deactive
	out	DATADIR,_255
	
		out		ADDRL,L    ; output 16 bit address 
		out		ADDRH,H

		sbrc		H,7	    ; skip if address < 0x8000
		sbrc		H,6	    ; skip if 6th bit is clear



		MEMWR_active

		
		MEMWR_deactive

	
	nop		;MDELAY: inserted one wait cycle
		
		out		DATADIR,_zero			; DATAOUT input
		MEMRD_active

	;END OF WRITE

rjmp	i_cycle

_add_l:

	     add A,L
	     
rjmp	set_flags

_adc_l:

	     ror	PSW
	     adc 	A,L
	     
rjmp	set_flags

_sub_l:

		 
		 sub	A,L
		 rjmp	set_flags_sub

		 
_sbb_l:

		 ror	PSW
		 sez		; must be	
		 sbc	A,L
		 rjmp	set_flags_sub
		 
_ana_l:
and		A,L		
rjmp	clr_CH

_ora_l:

   		or		A,L
   		
rjmp	clr_CH

_xra_l:

   		eor		A,L
   		
rjmp	clr_CH

_cmp_l:

			mov	ZH,A
			sub	ZH,L
			mov	_last_result,ZH
			rjmp	set_flags_cmp
	     
_add_m:

   			out		ADDRL,L
			out		ADDRH,H
		     	rjmp PC+1		;MDELAY: inserted two wait cycles

         		in		ZL,DATAIN
         		
	     add A,ZL
	     
rjmp	set_flags

_adc_m:

   			out		ADDRL,L
			out		ADDRH,H
		     	rjmp PC+1		;MDELAY: inserted two wait cycles

         		in		ZL,DATAIN
         		
	     ror	PSW
	     adc 	A,ZL
	     
rjmp	set_flags

_sub_m:

   			out		ADDRL,L
			out		ADDRH,H
		     	rjmp PC+1		;MDELAY: inserted two wait cycles

         		in		ZL,DATAIN
         		
		 
		 sub	A,ZL
		 rjmp	set_flags_sub

		 
_sbb_m:

   			out		ADDRL,L
			out		ADDRH,H
		     	rjmp PC+1		;MDELAY: inserted two wait cycles

         		in		ZL,DATAIN
         		
		 ror	PSW
		 sez		; must be	
		 sbc	A,ZL
		 rjmp	set_flags_sub
		 
_ana_m:

   			out		ADDRL,L
			out		ADDRH,H
		     	rjmp PC+1		;MDELAY: inserted two wait cycles

         		in		ZL,DATAIN
         		and		A,ZL		
rjmp	clr_CH

_ora_m:

   			out		ADDRL,L
			out		ADDRH,H
		     	rjmp PC+1		;MDELAY: inserted two wait cycles

         		in		ZL,DATAIN
         		
   		or		A,ZL
   		
rjmp	clr_CH

_xra_m:

   			out		ADDRL,L
			out		ADDRH,H
		     	rjmp PC+1		;MDELAY: inserted two wait cycles

         		in		ZL,DATAIN
         		
   		eor		A,ZL
   		
rjmp	clr_CH

_cmp_m:

   			out		ADDRL,L
			out		ADDRH,H
		     	rjmp PC+1		;MDELAY: inserted two wait cycles

         		in		ZL,DATAIN
         		
			mov	ZH,A
			sub	ZH,ZL
			mov	_last_result,ZH
			rjmp	set_flags_cmp
	     
_adi:

			out		ADDRL,_PCL
			out		ADDRH,_PCH
			adiw		_PCL,1
		     
         		in		ZL,DATAIN
         		
	     add A,ZL
	     
rjmp	set_flags

_aci:

			out		ADDRL,_PCL
			out		ADDRH,_PCH
			adiw		_PCL,1
		     
         		in		ZL,DATAIN
         		
	     ror	PSW
	     adc 	A,ZL
	     
rjmp	set_flags

_sui:

			out		ADDRL,_PCL
			out		ADDRH,_PCH
			adiw		_PCL,1
		     
         		in		ZL,DATAIN
         		
		 
		 sub	A,ZL
		 rjmp	set_flags_sub

		 
_sbi:

			out		ADDRL,_PCL
			out		ADDRH,_PCH
			adiw		_PCL,1
		     
         		in		ZL,DATAIN
         		
		 ror	PSW
		 sez		; must be	
		 sbc	A,ZL
		 rjmp	set_flags_sub
		 
_ani:

			out		ADDRL,_PCL
			out		ADDRH,_PCH
			adiw		_PCL,1
		     
         		in		ZL,DATAIN
         		and		A,ZL		
rjmp	clr_CH

_ori:

			out		ADDRL,_PCL
			out		ADDRH,_PCH
			adiw		_PCL,1
		     
         		in		ZL,DATAIN
         		
   		or		A,ZL
   		
rjmp	clr_CH

_xri:

			out		ADDRL,_PCL
			out		ADDRH,_PCH
			adiw		_PCL,1
		     
         		in		ZL,DATAIN
         		
   		eor		A,ZL
   		
rjmp	clr_CH

_cpi:

			out		ADDRL,_PCL
			out		ADDRH,_PCH
			adiw		_PCL,1
		     
         		in		ZL,DATAIN
         		
			mov	ZH,A
			sub	ZH,ZL
			mov	_last_result,ZH
			rjmp	set_flags_cmp
	     

_inr_m:	
		out		ADDRL,L
		out		ADDRH,H
		bst		PSW,0 		; wait a minute & save CY
		ldi		ZH,1
				in		ZL,DATAIN

		add		ZL,ZH

 		in		PSW,SREG
		bld		PSW,0 ; restore CY

		
	;WRITE(H,L,ZL):

	out	DATAOUT,ZL
	MEMRD_deactive
	out	DATADIR,_255

		sbrc		H,7	    ; skip if address < 0x8000
		sbrc		H,6	    ; skip if 6th bit is clear



		MEMWR_active

		
		MEMWR_deactive

	
	nop		;MDELAY: inserted one wait cycle
		
		out		DATADIR,_zero			; DATAOUT input
		MEMRD_active

	;END OF WRITE
		
		
rjmp	i_cycle


_dcr_m:	
		out		ADDRL,L
		out		ADDRH,H
		bst		PSW,0 		; wait a minute & save CY
		ldi		ZH,1
		          	in		ZL,DATAIN

		sub		ZL,ZH		
		
        	in		PSW,SREG
		bld		PSW,0 	; restore CY

		
	;WRITE(H,L,ZL):

	out	DATAOUT,ZL
	MEMRD_deactive
	out	DATADIR,_255

		sbrc		H,7	    ; skip if address < 0x8000
		sbrc		H,6	    ; skip if 6th bit is clear



		MEMWR_active

		
		MEMWR_deactive

	
	nop		;MDELAY: inserted one wait cycle
		
		out		DATADIR,_zero			; DATAOUT input
		MEMRD_active

	;END OF WRITE
		
rjmp	i_cycle



_inx_b:
			sub	C, _255
			sbc	B, _255
 		 	
rjmp	i_cycle
			

_inx_d:
			sub	E, _255
			sbc	D, _255

			
rjmp	i_cycle

_inx_h:		
			
			sub	L, _255
			sbc	H, _255

 		 	
rjmp	i_cycle

_inx_sp:
			adiw 	_SPL,1
 		 	
rjmp	i_cycle


_dcx_b:
			subi	C,low(1)
			sbc	B,_zero
 		 	
rjmp	i_cycle
			

_dcx_d:		
			subi	E,low(1)
			sbc	D,_zero
 		 	
rjmp	i_cycle
			

_dcx_h:
			add	L,_255
			adc	H,_255
 		 	
rjmp	i_cycle
			
_dcx_sp:
			sbiw 	_SPL,1
 		 	
rjmp	i_cycle



;*********************** 16-bit instructions **********
; affected only i8080 PSW.CY 


_dad_b:		
	                ;  high,low 
			ror		PSW		
			add		L,C
			adc		H,B
			rol		PSW
rjmp	i_cycle
_lxi_b:		
		out		ADDRL,_PCL
		out		ADDRH,_PCH
		adiw	_PCL,1
			
		in		C,DATAIN 
		out		ADDRL,_PCL
		out		ADDRH,_PCH
		adiw	_PCL,1
		
		in		B,DATAIN
  
rjmp	i_cycle

_dad_d:		
	                ;  high,low 
			ror		PSW		
			add		L,E
			adc		H,D
			rol		PSW
rjmp	i_cycle
_lxi_d:		
		out		ADDRL,_PCL
		out		ADDRH,_PCH
		adiw	_PCL,1
			
		in		E,DATAIN 
		out		ADDRL,_PCL
		out		ADDRH,_PCH
		adiw	_PCL,1
		
		in		D,DATAIN
  
rjmp	i_cycle

_dad_h:		
	                ;  high,low 
			ror		PSW		
			add		L,L
			adc		H,H
			rol		PSW
rjmp	i_cycle
_lxi_h:		
		out		ADDRL,_PCL
		out		ADDRH,_PCH
		adiw	_PCL,1
			
		in		L,DATAIN 
		out		ADDRL,_PCL
		out		ADDRH,_PCH
		adiw	_PCL,1
		
		in		H,DATAIN
  
rjmp	i_cycle

_dad_sp:	
	                ;  high,low 
			ror		PSW		
			add		L,_SPL
			adc		H,_SPH
			rol		PSW
rjmp	i_cycle
_lxi_sp:	
		out		ADDRL,_PCL
		out		ADDRH,_PCH
		adiw	_PCL,1
			
		in		_SPL,DATAIN 
		out		ADDRL,_PCL
		out		ADDRH,_PCH
		adiw	_PCL,1
		
		in		_SPH,DATAIN
  
rjmp	i_cycle








;**************************** MOV ra,rb  ********

rjmp	i_cycle
_mov_ab:	
     		mov		A,B
          
rjmp	i_cycle
_mov_ac:	
     		mov		A,C
          
rjmp	i_cycle
_mov_ad:	
     		mov		A,D
          
rjmp	i_cycle
_mov_ae:	
     		mov		A,E
          
rjmp	i_cycle
_mov_ah:	
     		mov		A,H
          
rjmp	i_cycle
_mov_al:	
     		mov		A,L
          
rjmp	i_cycle
_mov_ba:	
     		mov		B,A
          
rjmp	i_cycle

rjmp	i_cycle
_mov_bc:	
     		mov		B,C
          
rjmp	i_cycle
_mov_bd:	
     		mov		B,D
          
rjmp	i_cycle
_mov_be:	
     		mov		B,E
          
rjmp	i_cycle
_mov_bh:	
     		mov		B,H
          
rjmp	i_cycle
_mov_bl:	
     		mov		B,L
          
rjmp	i_cycle
_mov_ca:	
     		mov		C,A
          
rjmp	i_cycle
_mov_cb:	
     		mov		C,B
          
rjmp	i_cycle

rjmp	i_cycle
_mov_cd:	
     		mov		C,D
          
rjmp	i_cycle
_mov_ce:	
     		mov		C,E
          
rjmp	i_cycle
_mov_ch:	
     		mov		C,H
          
rjmp	i_cycle
_mov_cl:	
     		mov		C,L
          
rjmp	i_cycle
_mov_da:	
     		mov		D,A
          
rjmp	i_cycle
_mov_db:	
     		mov		D,B
          
rjmp	i_cycle
_mov_dc:	
     		mov		D,C
          
rjmp	i_cycle

rjmp	i_cycle
_mov_de:	
     		mov		D,E
          
rjmp	i_cycle
_mov_dh:	
     		mov		D,H
          
rjmp	i_cycle
_mov_dl:	
     		mov		D,L
          
rjmp	i_cycle
_mov_ea:	
     		mov		E,A
          
rjmp	i_cycle
_mov_eb:	
     		mov		E,B
          
rjmp	i_cycle
_mov_ec:	
     		mov		E,C
          
rjmp	i_cycle
_mov_ed:	
     		mov		E,D
          
rjmp	i_cycle

rjmp	i_cycle
_mov_eh:	
     		mov		E,H
          
rjmp	i_cycle
_mov_el:	
     		mov		E,L
          
rjmp	i_cycle
_mov_ha:	
     		mov		H,A
          
rjmp	i_cycle
_mov_hb:	
     		mov		H,B
          
rjmp	i_cycle
_mov_hc:	
     		mov		H,C
          
rjmp	i_cycle
_mov_hd:	
     		mov		H,D
          
rjmp	i_cycle
_mov_he:	
     		mov		H,E
          
rjmp	i_cycle

rjmp	i_cycle
_mov_hl:	
     		mov		H,L
          
rjmp	i_cycle
_mov_la:	
     		mov		L,A
          
rjmp	i_cycle
_mov_lb:	
     		mov		L,B
          
rjmp	i_cycle
_mov_lc:	
     		mov		L,C
          
rjmp	i_cycle
_mov_ld:	
     		mov		L,D
          
rjmp	i_cycle
_mov_le:	
     		mov		L,E
          
rjmp	i_cycle
_mov_lh:	
     		mov		L,H
          
rjmp	i_cycle

rjmp	i_cycle




;******************************** Bit & rotation instructions ********************
			.equ	_CY  =		1
			.equ	_Z	 = 		2
			.equ	_S	 =		0x10
			.equ	_AC	 =		0x20

_cmc:		
			ldi		ZL,_CY
			eor		PSW,ZL	; Atmel CY(C) is LSB(0.) bit
			
rjmp	i_cycle

_stc:	
			ori		PSW,1<<0
			
rjmp	i_cycle

_cma:			; one's complement A; PSW unchanged
			com		A
			
rjmp	i_cycle


_rlca:			; i8080 affcect only CY
			ror		PSW
			bst		A,7
			rol		A
			bld		A,0
			rol		PSW
			
rjmp	i_cycle
			

_rrca:			; i8080 affcect only CY
			ror		PSW
			bst		A,0
			ror		A
			bld		A,7
			rol		PSW
			
rjmp	i_cycle
			

_rla:			; i8080 affcect only CY
			ror		PSW
			rol		A
			rol		PSW
			
rjmp	i_cycle
			
			
_rra:			; i8080 affcect only CY
			ror		PSW
			ror		A
			rol		PSW
			
rjmp	i_cycle
			

;************************** STACK INSTRUCTIONS *******************************

_push_h:			
			sbiw		_SPL,1
		
	;WRITE(_SPH,_SPL,H):

	out	DATAOUT,H
	MEMRD_deactive
	out	DATADIR,_255
	
		out		ADDRL,_SPL    ; output 16 bit address 
		out		ADDRH,_SPH

		sbrc		_SPH,7	    ; skip if address < 0x8000
		sbrc		_SPH,6	    ; skip if 6th bit is clear



		MEMWR_active


	sbiw	_SPL,1
		
		MEMWR_deactive

	
	nop		;MDELAY: inserted one wait cycle

	;END OF WRITE

	;WRITE(_SPH,_SPL,L):

	out	DATAOUT,L
	
		out		ADDRL,_SPL    ; output 16 bit address 
		out		ADDRH,_SPH

		sbrc		_SPH,7	    ; skip if address < 0x8000
		sbrc		_SPH,6	    ; skip if 6th bit is clear



		MEMWR_active

		
		MEMWR_deactive

	
	nop		;MDELAY: inserted one wait cycle
		
		out		DATADIR,_zero			; DATAOUT input
		MEMRD_active

	;END OF WRITE
		
rjmp	i_cycle

_push_d:			
			sbiw		_SPL,1
		
	;WRITE(_SPH,_SPL,D):

	out	DATAOUT,D
	MEMRD_deactive
	out	DATADIR,_255
	
		out		ADDRL,_SPL    ; output 16 bit address 
		out		ADDRH,_SPH

		sbrc		_SPH,7	    ; skip if address < 0x8000
		sbrc		_SPH,6	    ; skip if 6th bit is clear



		MEMWR_active


	sbiw	_SPL,1
		
		MEMWR_deactive

	
	nop		;MDELAY: inserted one wait cycle

	;END OF WRITE

	;WRITE(_SPH,_SPL,E):

	out	DATAOUT,E
	
		out		ADDRL,_SPL    ; output 16 bit address 
		out		ADDRH,_SPH

		sbrc		_SPH,7	    ; skip if address < 0x8000
		sbrc		_SPH,6	    ; skip if 6th bit is clear



		MEMWR_active

		
		MEMWR_deactive

	
	nop		;MDELAY: inserted one wait cycle
		
		out		DATADIR,_zero			; DATAOUT input
		MEMRD_active

	;END OF WRITE
		
rjmp	i_cycle

_push_b:			
			sbiw		_SPL,1
		
	;WRITE(_SPH,_SPL,B):

	out	DATAOUT,B
	MEMRD_deactive
	out	DATADIR,_255
	
		out		ADDRL,_SPL    ; output 16 bit address 
		out		ADDRH,_SPH

		sbrc		_SPH,7	    ; skip if address < 0x8000
		sbrc		_SPH,6	    ; skip if 6th bit is clear



		MEMWR_active


	sbiw	_SPL,1
		
		MEMWR_deactive

	
	nop		;MDELAY: inserted one wait cycle

	;END OF WRITE

	;WRITE(_SPH,_SPL,C):

	out	DATAOUT,C
	
		out		ADDRL,_SPL    ; output 16 bit address 
		out		ADDRH,_SPH

		sbrc		_SPH,7	    ; skip if address < 0x8000
		sbrc		_SPH,6	    ; skip if 6th bit is clear



		MEMWR_active

		
		MEMWR_deactive

	
	nop		;MDELAY: inserted one wait cycle
		
		out		DATADIR,_zero			; DATAOUT input
		MEMRD_active

	;END OF WRITE
		
rjmp	i_cycle

_push_a:		
			; from PSW & _last_result ---> ZL
			; ZL & A --> STACK
					; vypocita paritu z registra _last_result; vystup bude v bite T 
		; parita v 8080 znamenala neparnu paritu => paritny bit doplnal vysledok operacie do neparneho poctu bitov
	        ; even parity = parna 
	        ; odd  parity = neparna
	        ; destroy Z register, T = result parity bit
	        
	        ldi	ZH,high(parity_table)
	        mov	ZL,_last_result
	        ld	ZL,Z
	        bst	ZL,0
			ldi		ZH,high(push_a_table)
			mov		ZL,PSW
			ld		ZL,Z

			bld		ZL,2	; P copied
					
			sbiw		_SPL,1
		
	;WRITE(_SPH,_SPL,A):

	out	DATAOUT,A
	MEMRD_deactive
	out	DATADIR,_255
	
		out		ADDRL,_SPL    ; output 16 bit address 
		out		ADDRH,_SPH

		sbrc		_SPH,7	    ; skip if address < 0x8000
		sbrc		_SPH,6	    ; skip if 6th bit is clear



		MEMWR_active


	sbiw	_SPL,1
		
		MEMWR_deactive

	
	nop		;MDELAY: inserted one wait cycle

	;END OF WRITE

	;WRITE(_SPH,_SPL,ZL):

	out	DATAOUT,ZL
	
		out		ADDRL,_SPL    ; output 16 bit address 
		out		ADDRH,_SPH

		sbrc		_SPH,7	    ; skip if address < 0x8000
		sbrc		_SPH,6	    ; skip if 6th bit is clear



		MEMWR_active

		
		MEMWR_deactive

	
	nop		;MDELAY: inserted one wait cycle
		
		out		DATADIR,_zero			; DATAOUT input
		MEMRD_active

	;END OF WRITE
    

			
rjmp	i_cycle



			
_pop_h:		
			out		ADDRL,_SPL
			out		ADDRH,_SPH
			adiw	_SPL,1
		
	
			in		L,DATAIN
			out		ADDRL,_SPL
			out		ADDRH,_SPH
			adiw	_SPL,1
	
			in		H,DATAIN			
	
rjmp	i_cycle

_pop_d:		
			out		ADDRL,_SPL
			out		ADDRH,_SPH
			adiw	_SPL,1
		
	
			in		E,DATAIN
			out		ADDRL,_SPL
			out		ADDRH,_SPH
			adiw	_SPL,1
	
			in		D,DATAIN			
	
rjmp	i_cycle

_pop_b:		
			out		ADDRL,_SPL
			out		ADDRH,_SPH
			adiw	_SPL,1
		
	
			in		C,DATAIN
			out		ADDRL,_SPL
			out		ADDRH,_SPH
			adiw	_SPL,1
	
			in		B,DATAIN			
	
rjmp	i_cycle


_pop_a:			
		
			out		ADDRL,_SPL
			out		ADDRH,_SPH
			adiw	_SPL,1
		
	
			in		ZL,DATAIN
			out		ADDRL,_SPL
			out		ADDRH,_SPH
			adiw	_SPL,1
	
			in		A,DATAIN			
				mov		_last_result,_zero
			sbrs		ZL,2  		 ; T = P; if ZL.2 == 1 => skip next
					        	 ; PARITY(0) = 1, PARITY(1) = 0, PARITY(2)=0, ..., PARITY(5) = 0etc.
			inc		_last_result	 ;	_last_result := 1			

			ldi		ZH,high(pop_a_table)
			ld		PSW,Z

			
rjmp	i_cycle


;**************** Calls & Jumps & Returns instructions *****************************************

	
	
_rc:			out		SREG,PSW
			brbs	0,_ret	  ;	bit 0 of SREG is C and if is set  (1) do return
			
rjmp	i_cycle
			

_rnc:			out		SREG,PSW
			brbc	0,_ret	  ;	bit 0 of SREG is C and if is clear (0) do return
			
rjmp	i_cycle
			

_rp:        		;return PLUS		-> use N(negative) flag at atmel
			out		SREG,PSW
			brpl	_ret	  ;	bit 2 of SREG is N and if is CLEAR !!!!  (0) do return
			
rjmp	i_cycle
			

_rm:        		;call MINUS		-> use N(negative) flag at atmel
			out		SREG,PSW
			brmi	_ret	  ;	bit 2 of SREG is N and if is SET !!!!  (1) do return
			
rjmp	i_cycle

		
_ret:		
			
			out		ADDRL,_SPL
			out		ADDRH,_SPH
			adiw	_SPL,1
		
	
			in		_PCL,DATAIN
			out		ADDRL,_SPL
			out		ADDRH,_SPH
			adiw	_SPL,1
	
			in		_PCH,DATAIN			
	
rjmp	i_cycle
			

_rpe:	
					; vypocita paritu z registra _last_result; vystup bude v bite T 
		; parita v 8080 znamenala neparnu paritu => paritny bit doplnal vysledok operacie do neparneho poctu bitov
	        ; even parity = parna 
	        ; odd  parity = neparna
	        ; destroy Z register, T = result parity bit
	        
	        ldi	ZH,high(parity_table)
	        mov	ZL,_last_result
	        ld	ZL,Z
	        bst	ZL,0
			brts	_ret
						; EVEN = (PARITY == 1)
			
rjmp	i_cycle


_rpo:       
					; vypocita paritu z registra _last_result; vystup bude v bite T 
		; parita v 8080 znamenala neparnu paritu => paritny bit doplnal vysledok operacie do neparneho poctu bitov
	        ; even parity = parna 
	        ; odd  parity = neparna
	        ; destroy Z register, T = result parity bit
	        
	        ldi	ZH,high(parity_table)
	        mov	ZL,_last_result
	        ld	ZL,Z
	        bst	ZL,0
			brtc	_ret
						; ODD = (PARITY == 0)
			
rjmp	i_cycle
			

_rz:			out		SREG,PSW
			brbs	1,_ret	  ;	bit 1 of SREG is Z and if is set  (1) do return
			
rjmp	i_cycle
			

_rnz:			out		SREG,PSW
			brbc	1,_ret	  ;	bit 1 of SREG is Z and if is clear  (0) do return
			
rjmp	i_cycle
			

_cpo:       
					; vypocita paritu z registra _last_result; vystup bude v bite T 
		; parita v 8080 znamenala neparnu paritu => paritny bit doplnal vysledok operacie do neparneho poctu bitov
	        ; even parity = parna 
	        ; odd  parity = neparna
	        ; destroy Z register, T = result parity bit
	        
	        ldi	ZH,high(parity_table)
	        mov	ZL,_last_result
	        ld	ZL,Z
	        bst	ZL,0
			brtc	_call 		; ODD = (PARITY == 0)

			adiw	_PCL,2
			
rjmp	i_cycle


			

_cc:			out	SREG,PSW
			brbs	0,_call	  ;	bit 0 of SREG is C and if is set  ( 1 ) do call
			adiw	_PCL,2
			
rjmp	i_cycle

_cnc:			out	SREG,PSW
			brbc	0,_call	  ;	bit 0 of SREG is C and if is clear  ( 0 ) do call
			adiw	_PCL,2
			
rjmp	i_cycle

_cp:        		;call PLUS		-> use N(negative) flag at atmel
			out		SREG,PSW
			brpl	_call	  ;	bit 2 of SREG is N and if is CLEAR !!!!  ( 0 ) do call
			adiw	_PCL,2
			
rjmp	i_cycle

_cm:        		;call MINUS		-> use N(negative) flag at atmel
			out		SREG,PSW
			brmi	_call	  ;	bit 2 of SREG is N and if is SET !!!!  ( 1 ) do call
			adiw	_PCL,2
			
rjmp	i_cycle


_cz:			out	SREG,PSW
			brbs	1,_call	  ;	bit 1 of SREG is Z and if is set  ( 1 ) do call
			adiw	_PCL,2
			
rjmp	i_cycle

_cnz:			out	SREG,PSW
			brbc	1,_call	  ;	bit 1 of SREG is Z and if is clear  ( 0 ) do call
			adiw	_PCL,2
			
rjmp	i_cycle



_call:		
			out		ADDRL,_PCL	
			out		ADDRH,_PCH
			adiw	_PCL,1
			
			in		ZL,DATAIN
			out		ADDRL,_PCL	
			out		ADDRH,_PCH
			adiw	_PCL,1
			
			in		ZH,DATAIN
_rst_entry:
					
			sbiw		_SPL,1
		
	;WRITE(_SPH,_SPL,_PCH):

	out	DATAOUT,_PCH
	MEMRD_deactive
	out	DATADIR,_255
	
		out		ADDRL,_SPL    ; output 16 bit address 
		out		ADDRH,_SPH

		sbrc		_SPH,7	    ; skip if address < 0x8000
		sbrc		_SPH,6	    ; skip if 6th bit is clear



		MEMWR_active


	sbiw	_SPL,1
		
		MEMWR_deactive

	
	nop		;MDELAY: inserted one wait cycle

	;END OF WRITE

	;WRITE(_SPH,_SPL,_PCL):

	out	DATAOUT,_PCL
	
		out		ADDRL,_SPL    ; output 16 bit address 
		out		ADDRH,_SPH

		sbrc		_SPH,7	    ; skip if address < 0x8000
		sbrc		_SPH,6	    ; skip if 6th bit is clear



		MEMWR_active

		
		MEMWR_deactive

	
	nop		;MDELAY: inserted one wait cycle
		
		out		DATADIR,_zero			; DATAOUT input
		MEMRD_active

	;END OF WRITE
	 ; Return address --> stack
			movw		_PCL,ZL
			
rjmp	i_cycle

_cpe:	
					; vypocita paritu z registra _last_result; vystup bude v bite T 
		; parita v 8080 znamenala neparnu paritu => paritny bit doplnal vysledok operacie do neparneho poctu bitov
	        ; even parity = parna 
	        ; odd  parity = neparna
	        ; destroy Z register, T = result parity bit
	        
	        ldi	ZH,high(parity_table)
	        mov	ZL,_last_result
	        ld	ZL,Z
	        bst	ZL,0
			brts	_call 		; EVEN = (PARITY == 1)
			adiw	_PCL,2
			
rjmp	i_cycle
			




_jm:        		;call MINUS	-> use N(negative) flag at atmel
			out		SREG,PSW
			brmi	_jmp	  ;	bit 2 of SREG is N and if is SET !!!!  (1) do jump
			adiw	_PCL,2
			
rjmp	i_cycle

			
_jc:			out	SREG,PSW
			brbs	0,_jmp	  ;	bit 0 of SREG is C and if is set  (1) do jump
			adiw	_PCL,2
			
rjmp	i_cycle

_jnc:			out	SREG,PSW
			brbc	0,_jmp	  ;	bit 0 of SREG is C and if is clear  (0) do jump
			adiw	_PCL,2
			
rjmp	i_cycle

_jp:        		;call PLUS	-> use N(negative) flag at atmel
			out	SREG,PSW
			brpl	_jmp	  ;	bit 2 of SREG is N and if is CLEAR !!!!  (1) do jump
			adiw	_PCL,2
			
rjmp	i_cycle

_jmp:
			out		ADDRL,_PCL	
			out		ADDRH,_PCH
			adiw		_PCL,1
						in		ZL,DATAIN
			out		ADDRL,_PCL	
			out		ADDRH,_PCH
			mov		_PCL,ZL
				nop		;MDELAY: inserted one wait cycle
 	
			in		_PCH,DATAIN
			
rjmp	i_cycle

_jpe:	
					; vypocita paritu z registra _last_result; vystup bude v bite T 
		; parita v 8080 znamenala neparnu paritu => paritny bit doplnal vysledok operacie do neparneho poctu bitov
	        ; even parity = parna 
	        ; odd  parity = neparna
	        ; destroy Z register, T = result parity bit
	        
	        ldi	ZH,high(parity_table)
	        mov	ZL,_last_result
	        ld	ZL,Z
	        bst	ZL,0
			brts	_jmp 		; EVEN = (PARITY == 1)
			adiw	_PCL,2
			
rjmp	i_cycle

_jpo:					; vypocita paritu z registra _last_result; vystup bude v bite T 
		; parita v 8080 znamenala neparnu paritu => paritny bit doplnal vysledok operacie do neparneho poctu bitov
	        ; even parity = parna 
	        ; odd  parity = neparna
	        ; destroy Z register, T = result parity bit
	        
	        ldi	ZH,high(parity_table)
	        mov	ZL,_last_result
	        ld	ZL,Z
	        bst	ZL,0
			brtc	_jmp 		; ODD = (PARITY == 0)
			adiw	_PCL,2
			
rjmp	i_cycle

_jz:			out	SREG,PSW
			brbs	1,_jmp	  ;	bit 1 of SREG is Z and if is set  (1) do jump
			adiw	_PCL,2
			
rjmp	i_cycle

_jnz:			out	SREG,PSW
			brbc	1,_jmp	  ;	bit 1 of SREG is Z and if is clear  (0) do jump
			adiw	_PCL,2
			
rjmp	i_cycle



                                                 

;******************* RST instructions ****************************************			

_rst0:
_rst1:
_rst2:
_rst3:
_rst4:
_rst5:
_rst6:
_rst7:
   
   
		andi	ZL, 0b00111000	;	ZL is instruction opcode now
		ldi	ZH,0
		rjmp	_rst_entry


;************************************************************

;************************ Operations with memory *********************

_lda:		
			out		ADDRL,_PCL	
			out		ADDRH,_PCH
			adiw		_PCL,1
						in		ZL,DATAIN
			out		ADDRL,_PCL	
			out		ADDRH,_PCH
			adiw		_PCL,1
						in		ZH,DATAIN
			
			out		ADDRL,ZL
			out		ADDRH,ZH
				rjmp PC+1		;MDELAY: inserted two wait cycles
			in		A,DATAIN
			
rjmp	i_cycle


_sta:		
			out		ADDRL,_PCL	
			out		ADDRH,_PCH
			adiw		_PCL,1
						in		ZL,DATAIN
			out		ADDRL,_PCL	
			out		ADDRH,_PCH
			adiw		_PCL,1
						in		ZH,DATAIN
			
	;WRITE(ZH,ZL,A):

	out	DATAOUT,A
	MEMRD_deactive
	out	DATADIR,_255
	
		out		ADDRL,ZL    ; output 16 bit address 
		out		ADDRH,ZH

		sbrc		ZH,7	    ; skip if address < 0x8000
		sbrc		ZH,6	    ; skip if 6th bit is clear



		MEMWR_active

		
		MEMWR_deactive

	
	nop		;MDELAY: inserted one wait cycle
		
		out		DATADIR,_zero			; DATAOUT input
		MEMRD_active

	;END OF WRITE
			
rjmp	i_cycle
			

_mvi_m:
			out		ADDRL,_PCL	
			out		ADDRH,_PCH
			adiw		_PCL,1
						in		ZL,DATAIN
			
	;WRITE(H,L,ZL):

	out	DATAOUT,ZL
	MEMRD_deactive
	out	DATADIR,_255
	
		out		ADDRL,L    ; output 16 bit address 
		out		ADDRH,H

		sbrc		H,7	    ; skip if address < 0x8000
		sbrc		H,6	    ; skip if 6th bit is clear



		MEMWR_active

		
		MEMWR_deactive

	
	nop		;MDELAY: inserted one wait cycle
		
		out		DATADIR,_zero			; DATAOUT input
		MEMRD_active

	;END OF WRITE
			
rjmp	i_cycle

; /** for save flash space, jump table is moved here **/

.org	(high(PC) + (low(PC) != 0) ) *256 ; alignment 256 words

i_table:	.include	"8080.asm"		

kb_lookup: 	.include	"kb_lookup.asm"


;************************ A := [r16] ; indirect addressing instructions *****

_ldax_b:	
			out		ADDRL,C
			out		ADDRH,B
				rjmp PC+1		;MDELAY: inserted two wait cycles
			in		A,DATAIN
			
rjmp	i_cycle

_stax_b:	
			
	;WRITE(B,C,A):

	out	DATAOUT,A
	MEMRD_deactive
	out	DATADIR,_255
	
		out		ADDRL,C    ; output 16 bit address 
		out		ADDRH,B

		sbrc		B,7	    ; skip if address < 0x8000
		sbrc		B,6	    ; skip if 6th bit is clear



		MEMWR_active

		
		MEMWR_deactive

	
	nop		;MDELAY: inserted one wait cycle
		
		out		DATADIR,_zero			; DATAOUT input
		MEMRD_active

	;END OF WRITE
			
rjmp	i_cycle


_ldax_d:	
			out		ADDRL,E
			out		ADDRH,D
				rjmp PC+1		;MDELAY: inserted two wait cycles
			in		A,DATAIN
			
rjmp	i_cycle

_stax_d:	
			
	;WRITE(D,E,A):

	out	DATAOUT,A
	MEMRD_deactive
	out	DATADIR,_255
	
		out		ADDRL,E    ; output 16 bit address 
		out		ADDRH,D

		sbrc		D,7	    ; skip if address < 0x8000
		sbrc		D,6	    ; skip if 6th bit is clear



		MEMWR_active

		
		MEMWR_deactive

	
	nop		;MDELAY: inserted one wait cycle
		
		out		DATADIR,_zero			; DATAOUT input
		MEMRD_active

	;END OF WRITE
			
rjmp	i_cycle

_lhld:
			out		ADDRL,_PCL
			out		ADDRH,_PCH
			adiw		_PCL,1
						in		ZL,DATAIN
			
			out		ADDRL,_PCL	
			out		ADDRH,_PCH
			adiw		_PCL,1
						in		ZH,DATAIN

			out		ADDRL,ZL
			out		ADDRH,ZH
			adiw		ZL,1
						in		L,DATAIN
			
			out		ADDRL,ZL
			out		ADDRH,ZH
				rjmp PC+1		;MDELAY: inserted two wait cycles
			in		H,DATAIN
			
rjmp	i_cycle


_shld:			out		ADDRL,_PCL
			out		ADDRH,_PCH
			adiw		_PCL,1
						in		ZL,DATAIN
			out		ADDRL,_PCL	
			out		ADDRH,_PCH
			adiw		_PCL,1
						in		ZH,DATAIN

			
	;WRITE(ZH,ZL,L):

	out	DATAOUT,L
	MEMRD_deactive
	out	DATADIR,_255
	
		out		ADDRL,ZL    ; output 16 bit address 
		out		ADDRH,ZH

		sbrc		ZH,7	    ; skip if address < 0x8000
		sbrc		ZH,6	    ; skip if 6th bit is clear



		MEMWR_active


	adiw	ZL,1
		
		MEMWR_deactive

	
	nop		;MDELAY: inserted one wait cycle

	;END OF WRITE

			
	;WRITE(ZH,ZL,H):

	out	DATAOUT,H
	
		out		ADDRL,ZL    ; output 16 bit address 
		out		ADDRH,ZH

		sbrc		ZH,7	    ; skip if address < 0x8000
		sbrc		ZH,6	    ; skip if 6th bit is clear



		MEMWR_active

		
		MEMWR_deactive

	
	nop		;MDELAY: inserted one wait cycle
		
		out		DATADIR,_zero			; DATAOUT input
		MEMRD_active

	;END OF WRITE
			
rjmp	i_cycle


_sphl:
			movw		_SPL,L
			
rjmp	i_cycle



_pchl:
			movw		_PCL,L
			
rjmp	i_cycle




_xthl:		
			out		ADDRL,_SPL
			out		ADDRH,_SPH
			movw		ZL,L
				nop		;MDELAY: inserted one wait cycle
			in		L,DATAIN
			
			
	;WRITE(_SPH,_SPL,ZL):

	out	DATAOUT,ZL
	MEMRD_deactive
	out	DATADIR,_255

		sbrc		_SPH,7	    ; skip if address < 0x8000
		sbrc		_SPH,6	    ; skip if 6th bit is clear



		MEMWR_active


	adiw	_SPL,1
		
		MEMWR_deactive

	
	nop		;MDELAY: inserted one wait cycle
		
		out		DATADIR,_zero			; DATAOUT input
		MEMRD_active

	;END OF WRITE

			out		ADDRL,_SPL
			out		ADDRH,_SPH
				rjmp PC+1		;MDELAY: inserted two wait cycles
			in		H,DATAIN

			
	;WRITE(_SPH,_SPL,ZH):

	out	DATAOUT,ZH
	MEMRD_deactive
	out	DATADIR,_255

		sbrc		_SPH,7	    ; skip if address < 0x8000
		sbrc		_SPH,6	    ; skip if 6th bit is clear



		MEMWR_active


	sbiw	_SPL,1
		
		MEMWR_deactive

	
	nop		;MDELAY: inserted one wait cycle
		
		out		DATADIR,_zero			; DATAOUT input
		MEMRD_active

	;END OF WRITE
			
rjmp	i_cycle


_xchg:			
			movw		ZL,L
			movw		L,E
			movw		E,ZL
			
rjmp	i_cycle


_daa:			; decimal adjust accumulator
			clr		ZH 	    ; add register
			mov		ZL,A	
			andi		ZL,0x0f   ; low nibble of A
			cpi		ZL,9 + 1
			brlo		_daa1
			ori		ZH,6
	_daa1:		sbrc		PSW,ATMEL_H		
			ori		ZH,6
			sbrc		PSW,ATMEL_C
			ori		ZH,0x60
			mov		ZL,A
			cpi		ZL,0x9f+1
			brlo		_daa2
			ori		ZH,0x60
	_daa2:		
			cpi		ZL,0x99+1
			brlo		_daa3
			set
			bld		PSW,ATMEL_C ; CY :=1	
	_daa3:		
			cpi		ZL,0x90+1
			brlo		_daa4
			andi		ZL,0x0f   ; low nibble of A
			cpi		ZL,9 + 1
			brlo		_daa4
			ori		ZH,0x60
	_daa4:		
			add		A,ZH
			rjmp		save_parity
					
			



;*********************************************************************
;****            I/O subsystem                                    ****
;*********************************************************************
in_channels:
			rjmp	in_channel0
			rjmp	in_channel1	
			rjmp	in_channel2
            		rjmp	in_channel3
            		rjmp	in_channel4
            		rjmp	in_channel5
            		rjmp	in_channel6
            		rjmp	in_channel7

out_channels:
			rjmp	out_channel0
			rjmp	out_channel1	
			rjmp	out_channel2
            		rjmp	out_channel3
            		rjmp	out_channel4
            		rjmp	out_channel5
            		rjmp	out_channel6
            		rjmp	out_channel7

rd_usart_status:
			
			
			ldi		ZH,6	; receiver always ready; TxE = 1, RxRDY=1
	
			in		ZL,TIFR
			bst		ZL,OCF2	; T = TxRDY (1 = transmitter ready, 0 = transmitter busy)

			bld		ZH,0	; TxRDY (transmitted flag) T -> A[0.bit] 
			mov		A,ZH
			rjmp	i_cycle

			
							





rd_kbd_pb:		lds	ZL,kbd_ports + 0  		; value of PortA (8255) 
			andi	ZL,0b1111			; mask 4 bits(16 cols)
			subi	ZL, low( -kb_cols )
			ldi	ZH, high( kb_cols )
			ld	A,Z				; column value
			mov	ZL,kbd_flags
			andi	ZL,(1<<SHIFT_bit)|(1<<STOP_bit)
			or	A,ZL				; write SHIFT + STOP
			
			rjmp	i_cycle

rd_pmd_kbd: 		andi	ZL,0b11       ; internal port number in IC 8255
			cpi	ZL,1          ; PB ?
			breq	rd_kbd_pb
			subi		ZL, low( -kbd_ports )
			ldi		ZH, high( kbd_ports )
			ld		A,Z				; read to A
			rjmp	i_cycle


rd_rom_modul: 
			andi	ZL,0b11       ; internal port number in 8255
			breq	rd_rom_modul_from_flash
			subi		ZL,low(-_rom)
			ldi		ZH,high(_rom)
			ld		A,Z
			rjmp	i_cycle

rd_channel_0_7:
			swap		ZL
			andi		ZL,0x07
			subi		ZL,low(-in_channels)
			ldi		ZH,high(in_channels)

_hlt:									; forever loop (HALT)
			ijmp


_in:		
			out		ADDRL,_PCL
			out		ADDRH,_PCH
			adiw	_PCL,1
						in		ZL,DATAIN

			mov	ZH,ZL		; in ZL is port address

			
			
			andi	ZH,0b10001100
			cpi	ZH,0b10000100
			breq	rd_pmd_kbd
			cpi	ZH,0b10001000
			breq	rd_rom_modul
			cpi	ZH,0b00001100
			breq	rd_channel_0_7
			cpi	ZL,0xf0		; support for Didaktik Alfa's USART  ....'
			breq	in_channel1
			cpi	ZL,0xf1
			breq	in_channel1
			
			rjmp	i_cycle		; read from other port (not implemented/not exists port) 
			
rd_rom_modul_from_flash:  
	
			ldi		ZL,low(basic1_start << 1)
			ldi		ZH,high(basic1_start << 1)
			lds		A,_rom + 1	; byte1
			add		ZL,A
			lds		A,_rom + 2	; byte2
			;andi		A,0b01111111	?? TODO
			adc		ZH,A
			lpm		A,Z		
			
			rjmp		i_cycle

.dseg

last_byte:	.byte	1
last_count:	.byte	1

.cseg


in_channel1:  
			;1C and 1E  = DATA
			;1D and 1F  = USART STATUS register
			
			sbic	DATAIN,0 		; DATA/status (0 = DATA, 1 = STATUS)
			rjmp	rd_usart_status



rd_usart_data:		; output: reg. A := data from tape (and increment tape pointer)
			; uses RLE compression

			push		YL
			push		YH
			lds		ZL,mgf_pointer+0
			lds		ZH,mgf_pointer+1
			lds		YL,mgf_pointer+2
			out		RAMPZ, YL

			lds		YH,last_count
			cpi		YH,1			; 1 == must read, >1 ... unpack from buffer :) 
			breq		must_read_next_char
			lds		A,last_byte
			cpi		YH,2
			breq		check_doubles
			dec		YH			; decrement count of bytes to read from buffer
			sts		last_count,YH
			rjmp		rd_usart_data_ret
			
must_read_next_char:	
			elpm		A,Z+			; this char will be returned (A)

check_doubles:
			elpm		YH,Z+			; YH
			sts		last_byte,YH		; remember next char
			
			cp		YH,A
			ldi		YH,2			; count := 2
			brne		no_packed
	
			elpm		YH,Z+			; read count 
			
no_packed:
			sts		last_count,YH		; remember count
			in		YL,RAMPZ	

			cpi		ZL,byte1(2*games_end)    ; ZL
			ldi		YH,byte2(2*games_end)
			cpc		ZH,YH			 ; ZH	
			ldi		YH,byte3(2*games_end)
			cpc		YL,YH			 ; YL
								 ; over 128 KB? (Atmega128 has capacity 128 KB) 
			brlo		store_mgf_pointer

			ldi		ZL,byte1(2*games_start)
			ldi		ZH,byte2(2*games_start)
			ldi		YL,byte3(2*games_start)
			
store_mgf_pointer:
			sts		mgf_pointer+0,ZL
			sts		mgf_pointer+1,ZH
			sts		mgf_pointer+2,YL
rd_usart_data_ret:
			pop		YH
			pop		YL
			rjmp	i_cycle







				
out_channel1:		; some games i.e. HLIPA uses USART as a timer (write to data register and then 
                        ; read status. TxC will set in status word 11/1200 s = 9.16 ms (after 143 TV row scans) 

			sbic	DATAIN,0 		; DATA/status (0 = DATA, 1 = STATUS)
			rjmp	i_cycle
wr_usart_data:                        
			out	TCCR2,_zero		; stop CTC2 

			out	TCNT2,_zero		; count from 0 to OCR2

			ldi	ZL,1<<OCF2		; clear TIFR.OCF2 (this is done by write one OCF2 bit!)
			out	TIFR,ZL
				
			ldi	ZL,0b00001101		; run TCCR2 at CLK/1024, CTC mode 
			out	TCCR2,ZL
			
			; go to i_cycle 
				
out_channel0:	
out_channel2:
out_channel3:
out_channel4:				
out_channel5: 
out_channel6:
out_channel7: 	
			rjmp	i_cycle


in_channel4:					; PMD-85 joystick disconnected ;-)
in_channel5: ; TODO
in_channel7: ; TODO
			mov		A,_255
in_channel0:
in_channel2:
in_channel3:
in_channel6:
			rjmp	i_cycle




wr_rom_modul:
			andi		ZL,0b11      ; internal port number in IC 8255
			subi		ZL,low(-_rom)
			ldi		ZH,high(_rom)
			st		Z,A
			rjmp		i_cycle

wr_channel_0_7:
			
			swap		ZL
			andi		ZL,0x07
			subi		ZL,low(-out_channels)
			ldi		ZH,high(out_channels)

			ijmp



_out:
			out		ADDRL,_PCL
			out		ADDRH,_PCH
			adiw		_PCL,1
						in		ZL,DATAIN

			mov		ZH,ZL		; ZL is port number
			
			
			andi	ZH,0b10001100		; decode port number
			cpi		ZH,0b10000100
			breq	wr_pmd_kbd
			cpi		ZH,0b10001000
			breq	wr_rom_modul
			cpi		ZH,0b00001100
			breq	wr_channel_0_7

			rjmp	i_cycle


wr_pmd_kbd:		andi		ZL,0b11       ; internal port number in IC 8255
			subi		ZL, low( -kbd_ports )
			ldi		ZH, high( kbd_ports )

			st		Z,A			; write register A to virtual port
			
			cpi		ZL,low(3 + kbd_ports)	; CW ?
			breq		wr_kbd_cw
			
			cpi		ZL,low(2 + kbd_ports)	; PC ?
			breq		wr_kbd_pc			

         		rjmp	i_cycle
				




wr_kbd_cw:
				sbrc		A,7		  ; CW.7 == 0 is ADDRH bit set/reset instruction
				rjmp		i_cycle		  ; CW.7 == 1 is control word (not implemented)	
				
			
				mov		ZH,A
				lsr		ZH				 
				andi		ZH,0b111	  ; in ZH is bit number(0..7)
				sec
				clr		ZL

mask_compute:			rol		ZL
				dec		ZH
				brne		mask_compute
				
				lds 	ZH,kbd_ports + 2     	       ; ZH = port C of 8255
				com		ZL                     ; mask AND  
				and		ZH,ZL			   
				com		ZL		       ; mask OR 	
				sbrc	A,0			       ; skip if zero bit must be written	
				or		ZH,ZL
				
						  
				sts 	kbd_ports + 2,ZH    	 	; port C := ZH

				; continue to wr_kbd_pc		


wr_kbd_pc:
          ; on port C was connected  LEDs and repro (sound)
          ; PC0        00 = repro off   11=tone3
          ;      =     01 = tone1
          ; PC1        10 = tone2
         
          ; PC2 = yellow LED - log.1 lights LED and turn on repro
          ; PC3 = red LED
          
				lds	ZL,kbd_ports + 2 ; PC0
				bst	ZL,0		 ; PC3 := PC0 
				bld	ZL,3
				andi	ZL,0b1110
				mov	kbd_portC,ZL

			rjmp	i_cycle
 



basic1_start:
		.include	"basic1.asm"

games_start:
		.include	"games_rom.asm"
games_end:
		



.dseg


		    .org	ramend - 5*256 +1
stack_top:		    
blink_lookup_table: .byte 	0x200	; 512 bytes
parity_table:	    .byte	0x100	; reserve 256 bytes for look-up parity table	
push_a_table:	    .byte	0x100
pop_a_table:	    .byte	0x100

 
.eseg 
		.include	"monit1.asm"
 
