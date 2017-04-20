#
#
#

MGFDIR= rom0 #Use dirname with  rom0|rom1|rom2 

AVRDUDE= avrdude -V -p m128 -c pony-stk200 -P lpt1
PHP= php
ASM = "..\avrassembler\avrasm32.exe"
#ASM = "c:\\AvrAssembler\\avrasm32.exe"


all:	flash eeprom


games_rom.asm: games.php Makefile
	$(PHP) -f games.php $(MGFDIR) games_rom.asm


basic1.asm:	games.php basic1.rom
	$(PHP) -f games.php basic1
	
monit1.asm:	games.php monit1.rom
	$(PHP) -f games.php monit1

pmd.asm: pmd.php 8080.asm kbd.php macro.asm video.php kb_lookup.asm games_rom.asm basic1.asm monit1.asm 
	$(PHP) -q pmd.php > pmd.asm

pmd.eep: pmd.hex

pmd.hex: pmd.asm  
	$(ASM) -fI pmd.asm -o pmd.hex -m pmd.map -e pmd.eep -l pmd.lst


flash:	pmd.hex
	$(AVRDUDE) -U flash:w:pmd.hex

eeprom:	pmd.eep
	$(AVRDUDE) -U eeprom:w:pmd.eep



