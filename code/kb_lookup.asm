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

; kb_lookup.asm

; for each scan code (PC keyboard) assign pair numbers : column number & row number (PMD keyboard)
; PMD-85 has special keys K0-K11 mapped to F1-F12
 
.db (0<<4)|rx, (8<<4)|r0  ;        ; f9 = k8 
.db (0<<4)|rx, (4<<4)|r0  ;        ; f5=k4
.db (2<<4)|r0, (0<<4)|r0  ; F3(k2) ; F1(k0)      
.db (1<<4)|r0, (11<<4)|r0 ; F2(k1) ; f12=k11      
.db (6<<4)|r0, (9<<4)|r0  ;        ; f10=k9      
.db (7<<4)|r0, (5<<4)|r0  ; f8=k7  ; f6=k5     
.db (3<<4)|r0, (14<<4)|r1 ; f4(k3);  TAB  
.db (14<<4)|r0, (0<<4)|rx ;  ` = RCL    
.db (0<<4)|rx, (0<<4)|rx ;      
.db (0<<4)|rx, (0<<4)|rx ;      
.db (0<<4)|rx, (0<<4)|r2 ;       Q  	  
.db (0<<4)|r1, (0<<4)|rx ;   1   
.db (0<<4)|rx, (0<<4)|rx ;      
.db (1<<4)|r4, (1<<4)|r3 ;   Y    S  
.db (0<<4)|r3, (1<<4)|r2 ;   A    W  
.db (1<<4)|r1, (0<<4)|rx ;   2   
.db (0<<4)|rx, (3<<4)|r4 ;       c  
.db (2<<4)|r4, (2<<4)|r3 ;   x   
.db (2<<4)|r2, (3<<4)|r1 ;   E    4	  
.db (2<<4)|r1, (0<<4)|rx ;   3   
.db (0<<4)|rx, (0<<4)|r4 ;       SPACE  
.db (4<<4)|r4, (3<<4)|r3 ;   v    F  
.db (4<<4)|r2, (3<<4)|r2 ;   T     R  
.db (4<<4)|r1, (0<<4)|rx ;   5	   
.db (0<<4)|rx, (6<<4)|r4 ;       n  
.db (5<<4)|r4, (5<<4)|r3 ;   b    H  
.db (4<<4)|r3, (5<<4)|r2 ;   G    Y  
.db (5<<4)|r1, (0<<4)|rx ;   6	   
.db (0<<4)|rx, (0<<4)|rx ;      
.db (7<<4)|r4, (6<<4)|r3 ;   M    J  
.db (6<<4)|r2, (6<<4)|r1 ;   U    7  
.db (7<<4)|r1, (0<<4)|rx ;   8   
.db (0<<4)|rx, (8<<4)|r4 ;       ,  
.db (7<<4)|r3, (7<<4)|r2 ;   K    I  
.db (8<<4)|r2, (9<<4)|r1 ;   O    0  
.db (8<<4)|r1, (0<<4)|rx ;   9   
.db (0<<4)|rx, (9<<4)|r4 ;       .  
.db (10<<4)|r4, (8<<4)|r3 ;   /    L  
.db (9<<4)|r3, (9<<4)|r2 ;       P  
.db (10<<4)|r1, (0<<4)|rx ;   -   
.db (0<<4)|rx, (0<<4)|rx ;      
.db (10<<4)|r3, (0<<4)|rx ;   '   
.db (10<<4)|r2, (10<<4)|r3 ;   [    =  
.db (0<<4)|rx, (0<<4)|rx ;      
.db (0<<4)|rx, (0<<4)|rx ;      
.db (14<<4)|r4, (11<<4)|r2 ;   ENTER    ]  
.db (0<<4)|rx, (0<<4)|rx ;      
.db (0<<4)|rx, (0<<4)|rx ;      
.db (0<<4)|rx, (0<<4)|rx ;      
.db (0<<4)|rx, (0<<4)|rx ;      
.db (0<<4)|rx, (0<<4)|rx ;      
.db (12<<4)|r2, (0<<4)|rx ;   BACKSPACE   
.db (0<<4)|rx, (12<<4)|r3 ;      ; END <|-- rol arrow
.db (0<<4)|rx, (12<<4)|r2 ;      ; left arrow
.db (13<<4)|r2, (0<<4)|rx ;  HOME ;     
.db (0<<4)|rx, (0<<4)|rx ;      
.db (12<<4)|r1, (13<<4)|r1 ;   INS, DEL   
.db (14<<4)|r3, (13<<4)|r2 ;   down arrow  ;  home 
.db (14<<4)|r2, (12<<4)|r3 ;  right arrow ;  up arrow    
.db (0<<4)|rx, (12<<4)|r0 ;   ESC     ; Numlock = WRK
.db (10<<4)|r0, (13<<4)|r3 ; f11=k10     ; sede(+) = END
.db (14<<4)|r3, (0<<4)|rx ; pgdn ;      
.db (0<<4)|rx, (12<<4)|r3 ;   * (on numpad)    ; pgup     
.db (0<<4)|rx, (0<<4)|rx ;      
.db (0<<4)|rx, (0<<4)|rx ;      
.db (0<<4)|rx, (6<<4)|r0  ;           ; f7=k6      

