
#set up basket function - can change size by change in register value
setupconstants:
#Register sets up at start 
addi x10, x0, -1 # gnd
addi x14, x0, 2 # high score
#addi x15, x0, 8 # current score 
sw x10, 16(x0)
sw x14, 8(x0)

#start game
pollForRInport2Eq1:            # read rInport, mask bit (2), repeat until rInport(2) = 1 
lw x4, 0xc(x15) 
andi x5, x4, 4   
#addi x5, x0, 4
beq x5, x0, pollForRInport2Eq1

pollForRInport2Eq0: # read rInport, mask bit (2), repeat until rInport(2) = 0
 lw x4, 0xc(x15)  
 andi x5, x4, 4   
 #addi x5, x0, 0 	      # test: (uncomment if testing) deasserts rInport(2) 
 bne x5, x0, pollForRInport2Eq0 

seedBasket:
addi x11, x0, 0xff # base basket
addi x12, x0, 0x81 # walls basket 
lui x13, 0x10 # ball
sw x13, 56(x0)
sw x11, 24(x0)
sw x12, 28(x0)
sw x12, 32(x0)

mainLoop:  			             # program-based decrementing delay loop [ref 1]
 lui    x12, 0x00601  		         # delayCount 0x00601000. Approx 1 second delay for 12.5MHz clk
 #addi   x12, x0,   1 		         # test: (uncomment if testing) initial count value
 decrDelayCountUntil0:              
  addi  x12, x12,  -1                
  bne   x12, x0,  decrDelayCountUntil0 

basketMoving:
slli x11,x11,1
sw x11, 24(x0)
slli x12,x12,1
addi x0,x0,0
sw x12, 28(x0)
sw x12, 32(x0)

pollRInport10_chkPlayerMove:         # inport(1)/(0) player left/right move control. Use AND mask to isolate bit.
 lw     x4, 0xc(x15)
 lui x10,80000
mskRInport1_If1ShiftPlayerLeft_ifPosnNotBit31:
andi   x5, x4,  2   			     
#  #addi   x12, x0,   2 			     # test: (uncomment if testing), force inport(0) asserted flag
beq    x5, x0,  mskRInport0_If1ShiftPlayerRight_ifPosnNotBit0
and   x5, x13, x10  	             # mask player bit 31. Can't move further left 
bne   x5, x0,  chkIfDropBallBit
slli   x13, x13,  1   		     # shift player left 1 bit
beq    x0,  x0,  chkIfDropBallBit# unconditional branch
mskRInport0_If1ShiftPlayerRight_ifPosnNotBit0:
andi   x5, x4,  1   			     
#  #addi   x12, x0,   1 			     # test: (uncomment if testing), force inport(1) asserted flag
beq    x5, x0,   chkIfDropBallBit
andi  x5, x13,  1   			     # mask player bit 0. Can't move further right 
bne   x5, x0,   chkIfDropBallBit
srli  x13, x13,  1    			 # shift player right 1 bit

chkIfDropBallBit: # if x10 asserted in same x11 asserted bit position (use AND), clear x10 bit if rInport(2) asserted
 andi    x5, x4, 4  			  
 beq    x12, x0,   mainLoop  
#this is where we call drop ball


 #andi   x9,  x14,  4   			     # mask inport(2), i.e, delete target bit 
 #addi   x9,  x0,   2 			     # test: (uncomment if testing), force inport(2) asserted flag
#  beq    x9,  x0,   mainLoop          
#  andi   x9,  x9,   3   			     # Check that inport(1:0) = 0b00, to enable clear of target bit
#  bne    x9,  x0,   mainLoop     	