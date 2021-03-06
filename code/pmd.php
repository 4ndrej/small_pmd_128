    
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
	 
<? 
        //configuration
	
	// XTAL frequency (range 18.432 MHz .... 20.000 MHz)

	//$f	= 20000000;  	// external crystal (no working with ATmega128-16)
	//$f      = 18432000;  	// external crystal (original PMD-85-1 screen size)
	//$f      = 18000000;	// external crystal (optimal for most ATmega128)
 	$f      = 16000000;  	// external crystal - nominal for ATmega128-16AI
// 	$f      = 16934400;  	// external crystal - najdeny na starej CDROMke
// 	$f      = 8000000;  	// internal RC oscillator - FOR TESTS
        
	$memory_latency = 70e-9;  // 70 ns latency


        $memory_requires_delay = ceil($memory_latency*$f);   // IN, OUT + Memory delay
	echo "\t; SRAM ===> $memory_requires_delay sys cycles\n\n";	

include("macro.asm"); 

	
function T($microsecond, $echo = true)
{
  global $f;
  
  $rv = max(0,round($f*$microsecond*1e-6)-1);	
  
  if( $echo ) echo $rv;
  return $rv;

}

		 $tt1= 9;                // horizontal screen position (in microsecond)
		                                     
		 $ocr1 = T($tt1- 12/$f*1e6, false); // 12 cycles is approx. delayed when video generation routine is executed
	
		 $ocr3 = T(64-4.7, false);  // when horizontal sync signal is going down(to zero); going up at $icr
		 $icr  = T(64, false);	   // TV line = 64 us 	
		 $ocr3_vertical  = T(32, false);  // when vertical sync is going down (to zero); going up at $icr
?>

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
		
		<? require	"video.php" ?>		
		


after_reset:			; continue RESET procedure

				sts	last_count,ZL
				sts	stop_flag, _zero
				sts	mgf_pointer+2,_zero

				;------------ USART 8251 transmitter speed emulation - for game HLIPA
				
				ldi	ZL,<? echo round(  ($f/1024.) / (1200./(1+8+1+1)) )."\n"; ?>
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
				
				ldi		r30,high(<? echo $icr; ?>)		; ICR1 = ICR3 = TOP = 64 us
				sts		ICR3H,r30
				out		ICR1H,r30

				ldi		r30,low(<? echo $icr; ?>)	
				sts		ICR3L,r30
				out		ICR1L,r30


				ldi		r30,high(<? echo $ocr3; ?>)	 ; when sync goes low 
				sts		OCR3AH,r30			 ; channel T3/A
				ldi		r30,low(<? echo $ocr3; ?>)	
				sts		OCR3AL,r30

				
				ldi		r30,high(<? echo $ocr1; ?>)	 ; when start video generation routine (T3/A)
				out		OCR1AH,r30
				ldi		r30,low(<? echo $ocr1; ?>)	
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
				
				<? _write('ZH','ZL',A,true,false,false,1,false); ?>
				
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
				<? MDELAY(3); ?>
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
				<? MDELAY(4); ?>
				
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

				<? MDELAY(6); ?>
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
				<? MDELAY(6); ?>
				in		ZL, DATAIN
				ijmp					; make instruction cycles

				
;-------------------------------------------------------------------------------------------------------------------------
				
							


<? 
function _write($h, $l, $data, $output_address=true, $deactive=true, $active=true, $add=0, $protect_rom=true)
{
	/**
		; write to PMD memory (models PMD-85-1, PMD-85-2 and Didaktik Alfa 1)
		; Memory areas (each 16 KB):
		; RAM        0x0000 to 0x7fff  
		; ROM        0x8000 to 0x8fff  
		; <free>     0x9000 to 0xbfff
		; videoram   0xc000 to 0xffff  

	**/

	echo  "\n\t;WRITE($h,$l,$data):\n\n"; 
	
	echo   "\tout\tDATAOUT,$data\n";


	if( $deactive ) 
	{ 
		echo "\tMEMRD_deactive\n";
	        echo "\tout\tDATADIR,_255\n";
        } 

	
	if( $output_address ) { 
	?>
	
		out		ADDRL,<? echo $l; ?>    ; output 16 bit address 
		out		ADDRH,<? echo $h; ?>

<? } 

		MDELAY( $protect_rom ? 2 : 0 ); 
if ( $protect_rom )
{ 
?>

		sbrc		<? echo $h; ?>,7	    ; skip if address < 0x8000
		sbrc		<? echo $h; ?>,6	    ; skip if 6th bit is clear


<?
		
}
?>

		MEMWR_active

<?
if( abs($add) >= 64 || ($add != 0 && $GLOBALS['write_add_special'])) 
{
                   echo "\n\tsubi\t$l,low(-(". $add. "))\n";
                   echo "\n\tsbci\t$h,high(-(". $add. "))\n";
		   $GLOBALS['write_add_special'] = false;                //some regs without support adiw, sbiw
}
else if( $add > 0 )
{
                   echo "\n\tadiw\t$l,". abs($add). "\n";
}
else if( $add < 0 )
{
                   echo "\n\tsbiw\t$l,". abs($add). "\n";
}

		  MDELAY( $add != 0 ? 4 : 2 ); 
?>		
		MEMWR_deactive

	
<? 	
		MDELAY(1);		    		// fall time	

if( $active ) 
{ 
?>
		
		out		DATADIR,_zero			; DATAOUT input
		MEMRD_active
<? 
}

                echo  "\n\t;END OF WRITE\n"; 

} 
	        	
?>



		

;***********************************************************************************************
;***********************************************************************************************
;***********************************************************************************************
;***********************************************************************************************

<?
	
function prepare($r)
{
   	if( $r == 'i' )
   	{
   		echo "
			out		ADDRL,_PCL
			out		ADDRH,_PCH
			adiw		_PCL,1
		     ";
		MDELAY(2);     
   	}	
   	
   	
   	if( $r == 'm' )
   	{
   		echo "
   			out		ADDRL,L
			out		ADDRH,H
		     ";
			MDELAY(0);
	}
		     		
   	if( $r == 'm' || $r == 'i')
   	{

		echo	"
         		in		ZL,DATAIN
         		";
         	return "ZL";     
         }
         else
         {
         	return strtoupper($r);
         }         		
	
}

$reg = array ( 'a', 'b','c','d','e','h','l', 'm','i' );
 
 foreach( $reg as $r1) 
 {
   $R1 = strtoupper($r1);
   
   if( $r1 != 'm' && $r1 != 'i' )
   {
   
   echo "_inr_$r1:\n";
   INR8($R1);
   echo "\n";

   echo "_dcr_$r1:\n";
   DCR8($R1);
   echo "\n";
   
   echo "_mvi_$r1:\n";
   MVI($R1);
   echo "\n";
   
   echo "_mov_${r1}m:\n";
   MOVRM($R1);
   echo "\n";

   echo "_mov_m${r1}:\n";
   MOVMR($R1);
   echo "\n";
   
   }
   
   
   if( $r1 != 'i' )
     echo "_add_$r1:\n";
   else
     echo "_adi:\n";
     
   ADD8(prepare($r1));
   echo "\n";


   if( $r1 != 'i' )
     echo "_adc_$r1:\n";
   else
     echo "_aci:\n";

   ADC8(prepare($r1));
   echo "\n";

  if( $r1 != 'i' )
     echo "_sub_$r1:\n";
   else
     echo "_sui:\n";

   SUB8(prepare($r1));
   echo "\n";

   
   if( $r1 != 'i' )
     echo "_sbb_$r1:\n";
   else
     echo "_sbi:\n";

   SBB8(prepare($r1));
   echo "\n";

   

   $r = "i";
   if( $r1 != 'i' ) $r = "a_$r1";

   echo "_an$r:\n";
   AND8(prepare($r1));
   echo "\n";

   echo "_or$r:\n";
   OR8(prepare($r1));
   echo "\n";

   echo "_xr$r:\n";
   XOR8(prepare($r1));
   echo "\n";

   if( $r1 != 'i' )
     echo "_cmp_$r1:\n";
   else
     echo "_cpi:\n";
   
   CMP8(prepare($r1));
   echo "\n";

 }


function i_cycle()
{
 
  echo "\nrjmp	i_cycle\n";	
	
}

function set_flags()
{
 
  echo "\nrjmp	set_flags\n";	
	
}


function i_cycle_clr_CH()
{
  echo "\nrjmp	clr_CH\n";	
}				

// DCR8/INR8 not affected parity flag

function INR8($r) 
{
  echo "
		bst		PSW,0 		; save CY
		ldi		ZL,1
		add		$r,ZL
		in		PSW,SREG
		bld		PSW,0 		; restore CY
	        ";
i_cycle();
}



function DCR8($r)
{
	echo "
		 bst		PSW,0 		; save CY
		 ldi		ZL,1
		 sub		$r,ZL

		 in		PSW,SREG
		 bld		PSW,0 		; restore CY
		 ";
		 
		 i_cycle();
}		 
		 

?>

_inr_m:	
		out		ADDRL,L
		out		ADDRH,H
		bst		PSW,0 		; wait a minute & save CY
		ldi		ZH,1
		<? MDELAY(2); ?>
		in		ZL,DATAIN

		add		ZL,ZH

 		in		PSW,SREG
		bld		PSW,0 ; restore CY

		<? _write(H,L,ZL,false,true,true,0,true); ?>
		
		<? i_cycle(); ?>


_dcr_m:	
		out		ADDRL,L
		out		ADDRH,H
		bst		PSW,0 		; wait a minute & save CY
		ldi		ZH,1
		<? MDELAY(2); ?>
          	in		ZL,DATAIN

		sub		ZL,ZH		
		
        	in		PSW,SREG
		bld		PSW,0 	; restore CY

		<? _write(H,L,ZL,false,true,true,0,true); ?>
		<? i_cycle(); ?>



_inx_b:
			sub	C, _255
			sbc	B, _255
 		 	<? i_cycle(); ?>
			

_inx_d:
			sub	E, _255
			sbc	D, _255

			<? i_cycle();  ?>

_inx_h:		
			
			sub	L, _255
			sbc	H, _255

 		 	<? i_cycle(); ?>

_inx_sp:
			adiw 	_SPL,1
 		 	<? i_cycle(); ?>


_dcx_b:
			subi	C,low(1)
			sbc	B,_zero
 		 	<? i_cycle(); ?>
			

_dcx_d:		
			subi	E,low(1)
			sbc	D,_zero
 		 	<? i_cycle(); ?>
			

_dcx_h:
			add	L,_255
			adc	H,_255
 		 	<? i_cycle(); ?>
			
_dcx_sp:
			sbiw 	_SPL,1
 		 	<? i_cycle(); ?>



;*********************** 16-bit instructions **********
; affected only i8080 PSW.CY 

<?

function LXI( $r1, $r2)
{
   echo "
		out		ADDRL,_PCL
		out		ADDRH,_PCH
		adiw	_PCL,1
	";
   		MDELAY(2); 	
   echo "		
		in		$r2,DATAIN 
		out		ADDRL,_PCL
		out		ADDRH,_PCH
		adiw	_PCL,1
	";
   		MDELAY(2); 	
	
   echo "	
		in		$r1,DATAIN
  ";
  		i_cycle();
}
function ADD16($h,$l)
{
	echo "
	                ;  high,low 
			ror		PSW		
			add		L,$l
			adc		H,$h
			rol		PSW"; 
	  		i_cycle();

}  ?>

_dad_b:		<? ADD16('B','C'); ?>
_lxi_b:		<? LXI('B','C'); ?>

_dad_d:		<? ADD16('D','E'); ?>
_lxi_d:		<? LXI('D','E'); ?>

_dad_h:		<? ADD16('H','L'); ?>
_lxi_h:		<? LXI('H','L'); ?>

_dad_sp:	<? ADD16('_SPH','_SPL'); ?>
_lxi_sp:	<? LXI('_SPH','_SPL'); ?>


<?


function SUB8($r)
{
 	echo	 "
		 
		 sub	A,$r
		 rjmp	set_flags_sub

		 ";
}			


function SBB8($r)
{
 	echo	 "
		 ror	PSW
		 sez		; must be	
		 sbc	A,$r
		 rjmp	set_flags_sub
		 ";
}			



function  ADD8($r)
{  
  	echo  "
	     add A,$r
	     ";
	 set_flags();    
} 

function  ADC8($r)
{  
  	echo  "
	     ror	PSW
	     adc 	A,$r
	     ";
	 set_flags();    
} 



function CMP8($r)
{
	echo "
			mov	ZH,A
			sub	ZH,$r
			mov	_last_result,ZH
			rjmp	set_flags_cmp
	     ";
}


function AND8($r)
{
   echo 	"and		A,$r		";
   		i_cycle_clr_CH();
}  		


function XOR8($r)
{
   echo 	"
   		eor		A,$r
   		";
   		i_cycle_clr_CH();   		
}  		


function OR8($r)
{
   echo "
   		or		A,$r
   		";
   		i_cycle_clr_CH();   		
}  		


?>






;**************************** MOV ra,rb  ********
<?
 $reg = array ( 'a', 'b','c','d','e','h','l' );
 
 foreach( $reg as $r1) 
 {
   $R1 = strtoupper($r1);
   foreach( $reg as $r2 )
   
   {
   $R2 = strtoupper($r2);
   if( $R2 != $R1 )
     echo "_mov_$r1$r2:\t
     		mov		$R1,$R2
          ";
          i_cycle();

   }
 
 
 
 
 }


function MVI($r)
{
   echo "
		out		ADDRL,_PCL
		out		ADDRH,_PCH 
		adiw		_PCL,1 
	";
      		MDELAY(2); 	
   echo "	
		in		$r,DATAIN 
		";
		i_cycle();
}

function MOVRM($r)
{
   static $i=1;
   $i++;
   echo "
		out		ADDRL,L
		out		ADDRH,H
	";
      		MDELAY(0); 	
   	
   echo "
                in		$r,DATAIN
	
	";
	
	i_cycle();	
	
	
}	

function MOVMR($r)
{
        _write(H,L,$r,true,true,true,0,true); 
	i_cycle();	
}
?>




;******************************** Bit & rotation instructions ********************
			.equ	_CY  =		1
			.equ	_Z	 = 		2
			.equ	_S	 =		0x10
			.equ	_AC	 =		0x20

_cmc:		
			ldi		ZL,_CY
			eor		PSW,ZL	; Atmel CY(C) is LSB(0.) bit
			<? i_cycle(); ?>

_stc:	
			ori		PSW,1<<0
			<? i_cycle(); ?>

_cma:			; one's complement A; PSW unchanged
			com		A
			<? i_cycle(); ?>


_rlca:			; i8080 affcect only CY
			ror		PSW
			bst		A,7
			rol		A
			bld		A,0
			rol		PSW
			<? i_cycle(); ?>
			

_rrca:			; i8080 affcect only CY
			ror		PSW
			bst		A,0
			ror		A
			bld		A,7
			rol		PSW
			<? i_cycle(); ?>
			

_rla:			; i8080 affcect only CY
			ror		PSW
			rol		A
			rol		PSW
			<? i_cycle(); ?>
			
			
_rra:			; i8080 affcect only CY
			ror		PSW
			ror		A
			rol		PSW
			<? i_cycle(); ?>
			

;************************** STACK INSTRUCTIONS *******************************
<?php
function PUSH16($h,$l)
{

      echo 	"		
			sbiw		_SPL,1
		";
      _write(_SPH,_SPL,$h,true,true,false,-1); 
		
      _write(_SPH,_SPL,$l,true,false,true,0); 
		
       			
}

function POP16( $r0,$r1) 
{
   echo "
			out		ADDRL,_SPL
			out		ADDRH,_SPH
			adiw	_SPL,1
	";
         		MDELAY(2); 	
   echo "	
	
			in		$r1,DATAIN
			out		ADDRL,_SPL
			out		ADDRH,_SPH
			adiw	_SPL,1
	";
	   		MDELAY(2); 	
   echo "
			in		$r0,DATAIN			
	";		
}

?>

_push_h:	<?	PUSH16('H','L'); ?>
		<?	i_cycle(); ?>

_push_d:	<?	PUSH16('D','E'); ?>
		<?	i_cycle(); ?>

_push_b:	<?	PUSH16('B','C'); ?>
		<?	i_cycle(); ?>

_push_a:		
			; from PSW & _last_result ---> ZL
			; ZL & A --> STACK
			<? calculate_parity(); ?>
			ldi		ZH,high(push_a_table)
			mov		ZL,PSW
			ld		ZL,Z

			bld		ZL,2	; P copied
			<?	PUSH16('A','ZL'); ?>    

			<?	i_cycle(); ?>



			
_pop_h:		<? POP16('H','L');
		   i_cycle();
		 ?>

_pop_d:		<? POP16('D','E');
		   i_cycle();	
		 ?>

_pop_b:		<? POP16('B','C');
		   i_cycle();
 ?>


_pop_a:			
		<?	POP16('A','ZL'); ?>
			mov		_last_result,_zero
			sbrs		ZL,2  		 ; T = P; if ZL.2 == 1 => skip next
					        	 ; PARITY(0) = 1, PARITY(1) = 0, PARITY(2)=0, ..., PARITY(5) = 0etc.
			inc		_last_result	 ;	_last_result := 1			

			ldi		ZH,high(pop_a_table)
			ld		PSW,Z

			<? 	i_cycle(); ?>


;**************** Calls & Jumps & Returns instructions *****************************************

<?
//1 = parna
//0 = neparna parita(ako u 8080)

function calculate_parity()
{
	
	
?>
		; vypocita paritu z registra _last_result; vystup bude v bite T 
		; parita v 8080 znamenala neparnu paritu => paritny bit doplnal vysledok operacie do neparneho poctu bitov
	        ; even parity = parna 
	        ; odd  parity = neparna
	        ; destroy Z register, T = result parity bit
	        
	        ldi	ZH,high(parity_table)
	        mov	ZL,_last_result
	        ld	ZL,Z
	        bst	ZL,0
<? } ?>
	
	
_rc:			out		SREG,PSW
			brbs	0,_ret	  ;	bit 0 of SREG is C and if is set  (1) do return
			<? i_cycle(); ?>
			

_rnc:			out		SREG,PSW
			brbc	0,_ret	  ;	bit 0 of SREG is C and if is clear (0) do return
			<? i_cycle(); ?>
			

_rp:        		;return PLUS		-> use N(negative) flag at atmel
			out		SREG,PSW
			brpl	_ret	  ;	bit 2 of SREG is N and if is CLEAR !!!!  (0) do return
			<? i_cycle(); ?>
			

_rm:        		;call MINUS		-> use N(negative) flag at atmel
			out		SREG,PSW
			brmi	_ret	  ;	bit 2 of SREG is N and if is SET !!!!  (1) do return
			<? i_cycle(); ?>

		
_ret:		
			<? POP16('_PCH','_PCL');
			i_cycle();
			 ?>
			

_rpe:	
			<? calculate_parity(); ?>
			brts	_ret
						; EVEN = (PARITY == 1)
			<? i_cycle(); ?>


_rpo:       
			<? calculate_parity(); ?>
			brtc	_ret
						; ODD = (PARITY == 0)
			<? i_cycle(); ?>
			

_rz:			out		SREG,PSW
			brbs	1,_ret	  ;	bit 1 of SREG is Z and if is set  (1) do return
			<? i_cycle(); ?>
			

_rnz:			out		SREG,PSW
			brbc	1,_ret	  ;	bit 1 of SREG is Z and if is clear  (0) do return
			<? i_cycle(); ?>
			

_cpo:       
			<? calculate_parity(); ?>
			brtc	_call 		; ODD = (PARITY == 0)

			adiw	_PCL,2
			<? i_cycle(); ?>


			

_cc:			out	SREG,PSW
			brbs	0,_call	  ;	bit 0 of SREG is C and if is set  ( 1 ) do call
			adiw	_PCL,2
			<? i_cycle(); ?>

_cnc:			out	SREG,PSW
			brbc	0,_call	  ;	bit 0 of SREG is C and if is clear  ( 0 ) do call
			adiw	_PCL,2
			<? i_cycle(); ?>

_cp:        		;call PLUS		-> use N(negative) flag at atmel
			out		SREG,PSW
			brpl	_call	  ;	bit 2 of SREG is N and if is CLEAR !!!!  ( 0 ) do call
			adiw	_PCL,2
			<? i_cycle(); ?>

_cm:        		;call MINUS		-> use N(negative) flag at atmel
			out		SREG,PSW
			brmi	_call	  ;	bit 2 of SREG is N and if is SET !!!!  ( 1 ) do call
			adiw	_PCL,2
			<? i_cycle(); ?>


_cz:			out	SREG,PSW
			brbs	1,_call	  ;	bit 1 of SREG is Z and if is set  ( 1 ) do call
			adiw	_PCL,2
			<? i_cycle(); ?>

_cnz:			out	SREG,PSW
			brbc	1,_call	  ;	bit 1 of SREG is Z and if is clear  ( 0 ) do call
			adiw	_PCL,2
			<? i_cycle(); ?>



_call:		
			out		ADDRL,_PCL	
			out		ADDRH,_PCH
			adiw	_PCL,1
			<?    		MDELAY(2); 	?>

			in		ZL,DATAIN
			out		ADDRL,_PCL	
			out		ADDRH,_PCH
			adiw	_PCL,1
			<?    		MDELAY(2); 	?>

			in		ZH,DATAIN
_rst_entry:
			<? PUSH16('_PCH','_PCL'); ?>	 ; Return address --> stack
			movw		_PCL,ZL
			<? i_cycle(); ?>

_cpe:	
			<? calculate_parity(); ?>
			brts	_call 		; EVEN = (PARITY == 1)
			adiw	_PCL,2
			<? i_cycle(); ?>
			




_jm:        		;call MINUS	-> use N(negative) flag at atmel
			out		SREG,PSW
			brmi	_jmp	  ;	bit 2 of SREG is N and if is SET !!!!  (1) do jump
			adiw	_PCL,2
			<? i_cycle(); ?>

			
_jc:			out	SREG,PSW
			brbs	0,_jmp	  ;	bit 0 of SREG is C and if is set  (1) do jump
			adiw	_PCL,2
			<? i_cycle(); ?>

_jnc:			out	SREG,PSW
			brbc	0,_jmp	  ;	bit 0 of SREG is C and if is clear  (0) do jump
			adiw	_PCL,2
			<? i_cycle(); ?>

_jp:        		;call PLUS	-> use N(negative) flag at atmel
			out	SREG,PSW
			brpl	_jmp	  ;	bit 2 of SREG is N and if is CLEAR !!!!  (1) do jump
			adiw	_PCL,2
			<? i_cycle(); ?>

_jmp:
			out		ADDRL,_PCL	
			out		ADDRH,_PCH
			adiw		_PCL,1
			<?    		MDELAY(2); 	?>
			in		ZL,DATAIN
			out		ADDRL,_PCL	
			out		ADDRH,_PCH
			mov		_PCL,ZL
			<?   		MDELAY(1);  ?> 	
			in		_PCH,DATAIN
			<? i_cycle(); ?>

_jpe:	
			<? calculate_parity(); ?>
			brts	_jmp 		; EVEN = (PARITY == 1)
			adiw	_PCL,2
			<? i_cycle(); ?>

_jpo:			<? calculate_parity(); ?>
			brtc	_jmp 		; ODD = (PARITY == 0)
			adiw	_PCL,2
			<? i_cycle(); ?>

_jz:			out	SREG,PSW
			brbs	1,_jmp	  ;	bit 1 of SREG is Z and if is set  (1) do jump
			adiw	_PCL,2
			<? i_cycle(); ?>

_jnz:			out	SREG,PSW
			brbc	1,_jmp	  ;	bit 1 of SREG is Z and if is clear  (0) do jump
			adiw	_PCL,2
			<? i_cycle(); ?>



                                                 

;******************* RST instructions ****************************************			

<? 
   for($i = 0; $i < 8 ; $i++ )
   {
    echo "_rst$i:\n";
   } 	     	 	
?>   
   
		andi	ZL, 0b00111000	;	ZL is instruction opcode now
		ldi	ZH,0
		rjmp	_rst_entry


;************************************************************

<?			

   function MDELAY($cycles)                   // insert wait cycles
   {

      // in $cycles is natural delay inserted by normal instruction sequence 

      global $memory_requires_delay;
      
      
      
      switch($memory_requires_delay - $cycles)
      {
         case  1:  echo "	nop\t\t;MDELAY: inserted one wait cycle\n";	break;
         case  2:  echo "	rjmp PC+1\t\t;MDELAY: inserted two wait cycles\n";	break;
         case  3:  echo "	nop\n\trjmp PC+1\t\t;MDELAY: inserted three wait cycles\n";	break;
         case  4:  echo "	rjmp PC+1\n\trjmp PC+1\t\t;MDELAY: inserted four wait cycles\n";	break;
         case  5:  echo "	nop\n\trjmp PC+1\n\trjmp PC+1\t\t;MDELAY: inserted five wait cycles\n";	break;
         case  6:  echo "	rjmp PC+1\n\trjmp PC+1\n\trjmp PC+1\t\t;MDELAY: inserted six wait cycles\n";	break;

	 default:		// no wait cycles requires
	 case 0:
	 		break;
      }
   	
   } 

?>
;************************ Operations with memory *********************

_lda:		
			out		ADDRL,_PCL	
			out		ADDRH,_PCH
			adiw		_PCL,1
			<? MDELAY(2); 	?>
			in		ZL,DATAIN
			out		ADDRL,_PCL	
			out		ADDRH,_PCH
			adiw		_PCL,1
			<? MDELAY(2); 	?>
			in		ZH,DATAIN
			
			out		ADDRL,ZL
			out		ADDRH,ZH
			<? MDELAY(0); 	?>
			in		A,DATAIN
			<? i_cycle(); ?>


_sta:		
			out		ADDRL,_PCL	
			out		ADDRH,_PCH
			adiw		_PCL,1
			<? MDELAY(2); 	?>
			in		ZL,DATAIN
			out		ADDRL,_PCL	
			out		ADDRH,_PCH
			adiw		_PCL,1
			<? MDELAY(2); 	?>
			in		ZH,DATAIN
			<? _write(ZH,ZL,A,true,true,true,0, true); ?>
			<? i_cycle(); ?>
			

_mvi_m:
			out		ADDRL,_PCL	
			out		ADDRH,_PCH
			adiw		_PCL,1
			<? MDELAY(2); 	?>
			in		ZL,DATAIN
			<? _write(H,L,ZL,true,true,true,0, true); ?>
			<? i_cycle(); ?>

; /** for save flash space, jump table is moved here **/

.org	(high(PC) + (low(PC) != 0) ) *256 ; alignment 256 words

i_table:	.include	"8080.asm"		

kb_lookup: 	.include	"kb_lookup.asm"


;************************ A := [r16] ; indirect addressing instructions *****

_ldax_b:	
			out		ADDRL,C
			out		ADDRH,B
			<? MDELAY(0); 	?>
			in		A,DATAIN
			<? i_cycle(); ?>

_stax_b:	
			<? _write(B,C,A,true,true,true,0); ?>
			<? i_cycle(); ?>


_ldax_d:	
			out		ADDRL,E
			out		ADDRH,D
			<? MDELAY(0); 	?>
			in		A,DATAIN
			<? i_cycle(); ?>

_stax_d:	
			<? _write(D,E,A,true,true,true,0); ?>
			<? i_cycle(); ?>

_lhld:
			out		ADDRL,_PCL
			out		ADDRH,_PCH
			adiw		_PCL,1
			<? MDELAY(2); 	?>
			in		ZL,DATAIN
			
			out		ADDRL,_PCL	
			out		ADDRH,_PCH
			adiw		_PCL,1
			<? MDELAY(2); 	?>
			in		ZH,DATAIN

			out		ADDRL,ZL
			out		ADDRH,ZH
			adiw		ZL,1
			<? MDELAY(2); 	?>
			in		L,DATAIN
			
			out		ADDRL,ZL
			out		ADDRH,ZH
			<? MDELAY(0); 	?>
			in		H,DATAIN
			<? i_cycle(); ?>


_shld:			out		ADDRL,_PCL
			out		ADDRH,_PCH
			adiw		_PCL,1
			<? MDELAY(2); 	?>
			in		ZL,DATAIN
			out		ADDRL,_PCL	
			out		ADDRH,_PCH
			adiw		_PCL,1
			<? MDELAY(2); 	?>
			in		ZH,DATAIN

			<? _write(ZH,ZL,L,true,true,false,1); // increment Z ?>

			<? _write(ZH,ZL,H,true,false,true,0); ?>
			<? i_cycle(); ?>


_sphl:
			movw		_SPL,L
			<? i_cycle(); ?>



_pchl:
			movw		_PCL,L
			<? i_cycle();?>




_xthl:		
			out		ADDRL,_SPL
			out		ADDRH,_SPH
			movw		ZL,L
			<? MDELAY(1); ?>
			in		L,DATAIN
			
			<? _write(_SPH,_SPL,ZL,false,true,true,1); // SP increment ?>

			out		ADDRL,_SPL
			out		ADDRH,_SPH
			<? MDELAY(0); ?>
			in		H,DATAIN

			<? _write(_SPH,_SPL,ZH,false,true,true,-1); // SP decrement ?>
			<? i_cycle(); ?>


_xchg:			
			movw		ZL,L
			movw		L,E
			movw		E,ZL
			<? i_cycle(); ?>


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
			<? MDELAY(2); ?>
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
			<? MDELAY(2); ?>
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
<?php 
   
   $bad_flash_offset = 0; //112; // compensation for BAD INTERNAL FLASH memory - set 0 for good ATmega device
  
   for($i=0;$i<$bad_flash_offset; $i++)
   {
      echo ".dw 0xffff\n";
   }

?>
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
 
