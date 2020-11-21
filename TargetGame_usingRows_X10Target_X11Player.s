# RISC-V Target game, using rows X10 (target), X11 (player)
# Created by Fearghal Morgan, National University of Ireland, Galway
# Creation date: Mar 2020 / Updated Nov 2020
#
# Game app specification: 
# https://www.vicilogic.com/static/ext/RISCV/programExamples/exercises/gameApp/Spec_TargetGame_usingRows_X10Target_X11Player.pptx
#
#==============================
# RISC-V instruction formats/examples (instruction generator https://tinyurl.com/whsk5k4)

# Copy/modify/paste this assembly program to Venus online assembler / simulator (Editor Window TAB) 
# Venus https://www.kvakil.me/venus/

# Convert Venus program dump (column of 32-bit instrs) to vicilogic instruction memory format (rows of 8x32-bit instrs)
# https://www.vicilogic.com/static/ext/RISCV/programExamples/convert_VenusProgramDump_to_vicilogicInstructionMemoryFormat.pdf

# [1] code for ~1 second delay 
# https://www.vicilogic.com/static/ext/RISCV/programExamples/exercises/programBasedloop1_ToggleX10Bit0_or_invertX10.asm
# Example program for peripheral memory devices write and read 
# https://www.vicilogic.com/static/ext/RISCV/programExamples/countInPOutP/countInPOutP.s
# ============================

# assembly program   # Notes  (default imm format is decimal 0d)

# register allocation
#  x7  newTargetLoopCount = 8
#  x8  0x80000000, bit 31 asserted  
#  x9  general use register 
#  x10 target register, seed with 0x801000
#  x11 player register, seed with 0x080000 
#  x12  general use register 
#  x13 loopCount 
#  x14  general use register 
#  x15  peripheral counter base address = 0x00010000
#   Address offsets:
#    Input: 
#	   control0 register address  offset = 0,    (2:0) = Counter load, up, countCE
#      X"0000" & loadDat(15:0)    offset = 4,    counter loadDat(15:0)
#      X"0000" & count(15:0)      offset = 8,    count(15:0) 
#      X"0000" & rinport(15:0)    offset = 0xc,  Registered inport value (inport delayed by one clk period)
#    Output:
#      X"0000" & outport(15:0)    offset = 0x10, outport(15:0) value


initialiseRegisters:
addi    x7,  x0,   8      
addi    x13, x0,   0    	 
lui     x15, 0x00010          
lui     x8,  0x80000    			  


pollForRInport0Eq1:            # read rInport, mask bit (0), repeat until rInport(0) = 1 
 lw     x14, 0xc(x15)  
 andi   x12, x14,  1   
 addi   x12, x0,   1  	      # test: (uncomment if testing) asserts rInport(0)
 beq    x12, x0, pollForRInport0Eq1 
pollForRInport0Eq0: # read rInport, mask bit (0), repeat until rInport(0) = 0
 lw     x14, 0xc(x15)        
 andi   x12, x14,  1  		  
 #addi   x12, x0,   0  		  # test: (uncomment if testing) deasserts rInport(0) 
 bne    x12, x0, pollForRInport0Eq0 



strtPeriphCounter:            # assert control0 register bits (1:0)=0b11, i.e, up, ce
 addi   x12, x0,   3       
 sw     x12, 0(x15)    	       

	
	
seedTargetX10andPlayerx11:   
lui     x10, 0x00801      		
lui     x11, 0x00080       		
	
	

mainLoop:  			             # program-based decrementing delay loop [ref 1]
 lui    x12, 0x00601  		         # delayCount 0x00601000. Approx 1 second delay for 12.5MHz clk
 #addi   x12, x0,   1 		         # test: (uncomment if testing) initial count value
 decrDelayCountUntil0:              
  addi  x12, x12,  -1                
  bne   x12, x0,  decrDelayCountUntil0 



chkUpdateTarget:					 # If incremented loopCount = newTargetLoopCount, clear loopCount and add random target bit
 addi   x13, x13,  1                 
 bne    x13, x7,   pollRInport10_chkPlayerMove    
 addi   x13, x0,   0     
 rdCountAndUseToAddNewTargetBit:         
 lw     x14, 8(x15)   	            
 #addi   x14, x0,   7                # test: (uncomment if testing) count = 7 
 addi   x12, x0,   1                 # seed bit in bit(0) position and shift left by count bits
 sll    x12, x12,  x14               
 or     x10, x10,  x12               # OR with target value to assert new target bit (may already be asserted)  



pollRInport10_chkPlayerMove:         # inport(1)/(0) player left/right move control. Use AND mask to isolate bit.
 lw     x14, 0xc(x15)               
mskRInport1_If1ShiftPlayerLeft_ifPosnNotBit31:
 andi   x12, x14,  2   			     
 #addi   x12, x0,   2 			     # test: (uncomment if testing), force inport(0) asserted flag
 beq    x12, x0,  mskRInport0_If1ShiftPlayerRight_ifPosnNotBit0
  and   x12, x11, x8  	             # mask player bit 31. Can't move further left 
  bne   x12, x0,  chkIfDelTargetBit
  slli   x11, x11,  1   		     # shift player left 1 bit
  beq    x0,  x0,  chkIfDelTargetBit# unconditional branch
mskRInport0_If1ShiftPlayerRight_ifPosnNotBit0:
 andi   x12, x14,  1   			     
 #addi   x12, x0,   1 			     # test: (uncomment if testing), force inport(1) asserted flag
 beq    x12, x0,   chkIfDelTargetBit
  andi  x12, x11,  1   			     # mask player bit 0. Can't move further right 
  bne   x12, x0,   chkIfDelTargetBit
  srli  x11, x11,  1    			 # shift player right 1 bit
 
 
 
chkIfDelTargetBit: # if x10 asserted in same x11 asserted bit position (use AND), clear x10 bit if rInport(2) asserted
 and    x12, x10,  x11  			  
 beq    x12, x0,   mainLoop           
 andi   x9,  x14,  4   			     # mask inport(2), i.e, delete target bit 
 #addi   x9,  x0,   2 			     # test: (uncomment if testing), force inport(2) asserted flag
 beq    x9,  x0,   mainLoop          
 andi   x9,  x9,   3   			     # Check that inport(1:0) = 0b00, to enable clear of target bit
 bne    x9,  x0,   mainLoop     	
 clrX10BitAndIncrScore:
  xori   x12, x11,  -1  			 # x12 = not x11, i.e, all bits asserted except the bit position to be cleared in target 
  and    x10, x10,  x12  			 # clear single target bit 
  addi   x1,  x1,   1     			 # score
  beq    x0,  x0,   mainLoop  	     

# ============================
# Post-assembly program listing
# PC instruction    basic assembly     original assembly             Notes
#      (31:0)        code                 code 
# initialiseRegisters
# 00 0x00800393	addi x7 x0 8	addi x7, x0, 8
# 04 0x00000693	addi x13 x0 0	addi x13, x0, 0
# 08 0x000107b7	lui x15 16	lui x15, 0x00010
# 0c 0x80000437	lui x8 524288	lui x8, 0x80000
# pollForRInport0Eq1
# 10 0x00c7a703	lw x14 12(x15)	lw x14, 0xc(x15)
# 14 0x00177613	andi x12 x14 1	andi x12, x14, 1
# 18 0xfe060ce3	beq x12 x0 -8	beq x12, x0, pollForRInport0Eq1
# pollForRInport0Eq0
# 1c 0x00c7a703	lw x14 12(x15)	lw x14, 0xc(x15)
# 20 0x00177613	andi x12 x14 1	andi x12, x14, 1
# 24 0xfe061ce3	bne x12 x0 -8	bne x12, x0, pollForRInport0Eq0
# strtPeriphCounter
# 28 0x00300613	addi x12 x0 3	addi x12, x0, 3
# 2c 0x00c7a023	sw x12 0(x15)	sw x12, 0(x15)
# seedTargetX10andPlayerx11
# 30 0x00801537	lui x10 2049	lui x10, 0x00801
# 34 0x000805b7	lui x11 128	lui x11, 0x00080
# mainLoop
# 38 0x00601637	lui x12 1537	lui x12, 0x00601   # delayCount 0x00601000. Approx 1 second delay for 12.5MHz clk
# decrDelayCountUntil0
# 3c 0xfff60613	addi x12 x12 -1	addi x12, x12, -1
# 40 0xfe061ee3	bne x12 x0 -4	bne x12, x0, decrDelayCountUntil0
# chkUpdateTarget
# 44 0x00168693	addi x13 x13 1	addi x13, x13, 1
# 48 0x00769c63	bne x13 x7 24	bne x13, x7, pollRInport10_chkPlayerMove
# 4c 0x00000693	addi x13 x0 0	addi x13, x0, 0
# rdCountAndUseToAddNewTargetBit
# 50 0x0087a703	lw x14 8(x15)	lw x14, 8(x15)
# 54 0x00100613	addi x12 x0 1	addi x12, x0, 1    # seed bit in bit(0) position and shift left by count bits
# 58 0x00e61633	sll x12 x12 x14	sll x12, x12, x14
# 5c 0x00c56533	or x10 x10 x12	or x10, x10, x12   # OR with target value to assert new target bit (may already be asserted)
# pollRInport10_chkPlayerMove
# 60 0x00c7a703	lw x14 12(x15)	lw x14, 0xc(x15)
# mskRInport1_If1ShiftPlayerLeft_ifPosnNotBit3164 0x00277613	andi x12 x14 2	andi x12, x14, 2
# 68 0x00060a63	beq x12 x0 20	beq x12, x0, mskRInport0_If1ShiftPlayerRight_ifPosnNotBit0
# 6c 0x0085f633	and x12 x11 x8	and x12, x11, x8   # mask player bit 31. Can't move further left
# 70 0x02061063	bne x12 x0 32	bne x12, x0, chkIfDelTargetBit
# 74 0x00159593	slli x11 x11 1	slli x11, x11, 1   # shift player left 1 bit
# 78 0x00000c63	beq x0 x0 24	beq x0, x0, chkIfDelTargetBit# unconditional branch
# mskRInport0_If1ShiftPlayerRight_ifPosnNotBit0
# 7c 0x00177613	andi x12 x14 1	andi x12, x14, 1
# 80 0x00060863	beq x12 x0 16	beq x12, x0, chkIfDelTargetBit
# 84 0x0015f613	andi x12 x11 1	andi x12, x11, 1   # mask player bit 0. Can't move further right
# 88 0x00061463	bne x12 x0 8	bne x12, x0, chkIfDelTargetBit
# 8c 0x0015d593	srli x11 x11 1	srli x11, x11, 1   # shift player right 1 bit
# chkIfDelTargetBit
# 90 0x00b57633	and x12 x10 x11	and x12, x10, x11
# 94 0xfa0602e3	beq x12 x0 -92	beq x12, x0, mainLoop
# 98 0x00477493	andi x9 x14 4	andi x9, x14, 4    # mask inport(2), i.e, delete target bit
# 9c 0xf8048ee3	beq x9 x0 -100	beq x9, x0, mainLoop
# a0 0x0034f493	andi x9 x9 3	andi x9, x9, 3     # Check that inport(1:0) = 0b00, to enable clear of target bit
# a4 0xf8049ae3	bne x9 x0 -108	bne x9, x0, mainLoop
# clrX10BitAndIncrScore
# a8 0xfff5c613	xori x12 x11 -1	xori x12, x11, -1  # x12 = not x11, i.e, all bits asserted except the bit position to be cleared in target
# ac 0x00c57533	and x10 x10 x12	and x10, x10, x12  # clear single target bit
# b0 0x00108093	addi x1 x1 1	addi x1, x1, 1     # score
# b4 0xf80002e3	beq x0 x0 -124	beq x0, x0, mainLoop


# ============================
# Venus 'dump' program binary. No of instructions n = 11
# 00800393
# 00000693
# 000107b7
# 80000437
# 00c7a703
# 00177613
# fe060ce3
# 00c7a703
# 00177613
# fe061ce3
# 00300613
# 00c7a023
# 00801537
# 000805b7
# 00601637
# fff60613
# fe061ee3
# 00168693
# 00769c63
# 00000693
# 0087a703
# 00100613
# 00e61633
# 00c56533
# 00c7a703
# 00277613
# 00060a63
# 0085f633
# 02061063
# 00159593
# 00000c63
# 00177613
# 00060863
# 0015f613
# 00061463
# 0015d593
# 00b57633
# fa0602e3
# 00477493
# f8048ee3
# 0034f493
# f8049ae3
# fff5c613
# 00c57533
# 00108093
# f80002e3


# ============================
# Program binary formatted, for use in vicilogic online RISC-V processor
# i.e, 8x32-bit instructions, 
# format: m = mod(n/8)+1 = mod(11/8)+1
# 0080039300000693000107b78000043700c7a70300177613fe060ce300c7a703
# 00177613fe061ce30030061300c7a02300801537000805b700601637fff60613
# fe061ee30016869300769c63000006930087a7030010061300e6163300c56533
# 00c7a7030027761300060a630085f633020610630015959300000c6300177613
# 000608630015f613000614630015d59300b57633fa0602e300477493f8048ee3
# 0034f493f8049ae3fff5c61300c5753300108093f80002e30000000000000000
