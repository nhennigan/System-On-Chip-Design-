
#set up basket function - can change size by change in register value
setupconstants:
#Register sets up at start 
addi x10, x0, -1 # gnd
addi x14, x0, 2 # high score
#addi x15, x0, 8 # current score
sw x10, 16(x0)
sw x14, 8(x0)
lui x5, 0x00010 
lui x7, 0x80000
addi x3, x0, 1 # basket moving register 0=left
addi x16, x0, 1 # check basket direction constant
addi x18, x0, 56 # ball starting row offset

#start game
pollForRInport2Eq1:            # read rInport, mask bit (2), repeat until rInport(2) = 1 
lw x4, 0xc(x5) 
andi x6, x4, 4   
#addi x5, x0, 4
beq x6, x0, pollForRInport2Eq1

pollForRInport2Eq0: # read rInport, mask bit (2), repeat until rInport(2) = 0
 lw x4, 0xc(x5)  
 andi x6, x4, 4   
 #addi x5, x0, 0 	      # test: (uncomment if testing) deasserts rInport(2) 
 bne x6, x0, pollForRInport2Eq0 

seedBasket:
addi x11, x0, 0xff # base basket
addi x12, x0, 0x81 # walls basket 
lui x13, 0x10 # ball
sw x13, 0(x18)
sw x11, 24(x0)
sw x12, 28(x0)
sw x12, 32(x0)

mainLoop:  			             # program-based decrementing delay loop [ref 1]
 #lui    x8, 0x00601  		         # delayCount 0x00601000. Approx 1 second delay for 12.5MHz clk
 #addi   x8, x0,   1 		         # test: (uncomment if testing) initial count value
 # decrDelayCountUntil0:              
 #  addi  x8, x8,  -1                
 #  bne   x8, x0,  decrDelayCountUntil0 

checkBasketDirection:
beq x3, x0, basketMovingLeft
beq x3, x16, basketMovingRight

basketMovingLeft:
addi x3, x0, 0 
and x9, x11, x7
bne x9, x0, basketMovingRight
slli x11,x11,1
sw x11, 24(x0)
slli x12,x12,1
sw x12, 28(x0)
sw x12, 32(x0)
beq x0,x0, ballDroppedCheck

basketMovingRight:
addi x3, x0, 1
andi x9, x11, 1
bne x9, x0, basketMovingLeft
srli x11,x11,1
sw x11, 24(x0)
srli x12,x12,1
sw x12, 28(x0)
sw x12, 32(x0)

ballDroppedCheck: 
bne x17, x0, dropBall # ball has been dropped skip player moving stuff

pollRInport10_chkPlayerMove:         # inport(1)/(0) player left/right move control. Use AND mask to isolate bit.
 lw     x4, 0xc(x5)
mskRInport1_If1ShiftPlayerLeft_ifPosnNotBit31:
andi   x6, x4,  2   			     
#  #addi   x12, x0,   2 			     # test: (uncomment if testing), force inport(0) asserted flag
beq    x6, x0,  mskRInport0_If1ShiftPlayerRight_ifPosnNotBit0
and   x6, x13, x7  	                               # mask player bit 31. Can't move further left 
bne   x6, x0,  chkIfDropBallBit
slli   x13, x13,  1   		     # shift player left 1 bit
sw x13, 56(x0) 
beq    x0,  x0,  chkIfDropBallBit# unconditional branch
mskRInport0_If1ShiftPlayerRight_ifPosnNotBit0:
andi   x6, x4,  1   			     
#  #addi   x12, x0,   1 			     # test: (uncomment if testing), force inport(1) asserted flag
beq    x6, x0,   chkIfDropBallBit
andi  x6, x13,  1   			     # mask player bit 0. Can't move further right 
bne   x6, x0,   chkIfDropBallBit
srli  x13, x13,  1    			 # shift player right 1 bit
sw x13, 56(x0)

chkIfDropBallBit: # if x10 asserted in same x11 asserted bit position (use AND), clear x10 bit if rInport(2) asserted
 andi    x6, x4, 4
 beq    x6, x0,   mainLoop 
addi x17, x0, 1 # ball has began dropping
sw x0, 0(x18) # clear row where ball is now
addi x18, x18, -8 # minus 8 to move ball down 2 rows
sw x13, 0(x18) # store ball in new memory row
beq x0, x0,   mainLoop # testing to go back to start
#this is where we call drop ball


 #andi   x9,  x14,  4   			     # mask inport(2), i.e, delete target bit 
 #addi   x9,  x0,   2 			     # test: (uncomment if testing), force inport(2) asserted flag
#  beq    x9,  x0,   mainLoop          
#  andi   x9,  x9,   3   			     # Check that inport(1:0) = 0b00, to enable clear of target bit
#  bne    x9,  x0,   mainLoop     	