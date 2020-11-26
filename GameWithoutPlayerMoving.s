# x3 basket direction 1/0
# x4 register for rinport
# x5 offset for rinport memory address
# x6 mask check register for rinport values
# x7 check left most bit value 
# x8 delay
# x9 mask check for basket
# x10 ground value
# x11 base basket value
# x13 ball value
# x14 highscore value
# x15 current score value 
# x17 ball dropped true false 1/0
# x18 ball memory address row
# x19 base memory address row
# x20 score needed to go to level 2 difficulty
# x21 mask check for disible by 2 for difficulty
# x22 check for level for speed
# x23 constant length of basket


setupconstants:
#Register sets up at start 
addi x10, x0, -1 # gnd
addi x15, x0, 0 # current score
sw x15, 4(x0) # store current score = 0
sw x10, 16(x0) # store ground
#sw x14, 8(x0) # store high score
lui x5, 0x00010 # offset for rinport
lui x7, 0x80000 # mask check for left most bit 
#addi x3, x0, 1 # basket moving register 0=left
#addi x16, x0, 1 # check basket direction constant
addi x19, x0, 24 #basket base memory row
addi x11, x0, 0xff # base basket dynamic moves around 
addi x20, x0, 8 # stop shifting bits off when score 6 
addi x23, x0, 0xff # starting basket length, used to shsift bits off too

#start game
pollForRInport2Eq1:            # read rInport, mask bit (2), repeat until rInport(2) = 1 
lw x4, 0xc(x5) 
andi x6, x4, 4   
beq x6, x0, pollForRInport2Eq1

pollForRInport2Eq0: # read rInport, mask bit (2), repeat until rInport(2) = 0
 lw x4, 0xc(x5)  
 andi x6, x4, 4   
 bne x6, x0, pollForRInport2Eq0 
 
seedBasket:
sw x11, 0(x19)

seedBall:
addi x18, x0, 56 # ball starting starting row 
lui x13, 0x10 # ball
sw x13, 0(x18)

mainLoop:  			             # program-based decrementing delay loop [ref 1]
#check which one t branch to 
lui x8, 0x00601 # load defualt 
andi x22, x15, 8  #mask check to see if min basket length reached
bne x22, x0, loadDelay2
beq x0,x0, decrDelayCountUntil0
  loadDelay2:
    jal x1, delay2
    beq x0, x0, decrDelayCountUntil0

#   loadDelay3:
#     jal x1, delay3

 #lui    x8, 0x00601  		         # delayCount 0x00601000. Approx 1 second delay for 12.5MHz clk
 #addi   x8, x0,   1 		         # test: (uncomment if testing) initial count value
  decrDelayCountUntil0:              
   addi x8, x8,  -1                
   bne x8, x0,  decrDelayCountUntil0 

checkBasketDirection:
beq x3, x0, basketMovingLeft   #check basket moving register = 0
bne x3, x0, basketMovingRight # check basket moving register != 0 i.e = 1

basketMovingLeft:
addi x3, x0, 0  # add 0 to basket direction register 
and x9, x11, x7 # and with left most bit 
bne x9, x0, basketMovingRight #if and comes back with 1 you are in left most bit so go right
slli x11, x11,1
sw x11, 24(x0)
beq x0,x0, ballDroppedCheck

basketMovingRight:
addi x3, x0, 1 
andi x9, x11, 1
bne x9, x0, basketMovingLeft
srli x11, x11,1
sw x11, 24(x0)

ballDroppedCheck: 
bne x17, x0, dropBall # ball has been dropped skip player moving stuff

pollRInport10_chkPlayerMove:         # inport(1)/(0) player left/right move control. Use AND mask to isolate bit.
 lw x4, 0xc(x5)
 mskRInport1_If1ShiftPlayerLeft_ifPosnNotBit31:
 andi x6, x4,  2   			     
 #  #addi x12, x0,   2 			     # test: (uncomment if testing), force inport(0) asserted flag
 beq x6, x0,  mskRInport0_If1ShiftPlayerRight_ifPosnNotBit0
 and x6, x13, x7  	                               # mask player bit 31. Can't move further left 
 bne x6, x0,  chkIfDropBallBit
 slli x13, x13,  1   		     # shift player left 1 bit
 sw x13, 56(x0) 
 beq x0,  x0,  chkIfDropBallBit# unconditional branch
 mskRInport0_If1ShiftPlayerRight_ifPosnNotBit0:
 andi x6, x4,  1   			     
 #  #addi   x12, x0,   1 			     # test: (uncomment if testing), force inport(1) asserted flag
 beq x6, x0,   chkIfDropBallBit
 andi x6, x13,  1   			     # mask player bit 0. Can't move further right 
 bne x6, x0,   chkIfDropBallBit
 srli x13, x13,  1    			 # shift player right 1 bit
 sw x13, 56(x0)

chkIfDropBallBit: #check rinport to see if ball is dropped
 andi x6, x4, 4
 beq x6, x0, mainLoop 

dropBall:
addi x17, x0, 1 # ball has began dropping
sw x0, 0(x18) # clear row where ball is now
addi x18, x18, -8 # minus 8 to move ball down 2 rows
beq x18, x19, scoreKeeper # when ball and base same row move to scorekeeper
sw x13, 0(x18) # store ball in new memory row
beq x0, x0, mainLoop # testing to go back to start

scoreKeeper:
and x6, x11, x13 # check if ball lands on base 
bne x6, x0, addScore # player scores so go to addScore
# ball missed so game over
or x11, x11, x13 # or ball and base so it appears on one line in led array
sw x11, 0(x19) # store on led array
#add delay code here
addi x17, x0, 0 # deassert ball has been dropped reg
bgt x15, x14, updateHighScore # if current score is greater than highscore, update highscore
beq x0, x0, setupconstants  

addScore:
addi x17, x0, 0 # deassert ball has been dropped reg
addi x15, x15, 1 #add one to curent score
sw x15, 4(x0) # store current score
jal x1, waitPlayerDeassertBallDrop
andi x21, x15, 1 # change to 2 later , 1 easier for testing
beq x21, x0, makeBasketSmaller
#beq x15, x2, makeBasketSmaller
beq x0, x0, seedBall
#jal x1, updateHighScore #checks if update is needed to highscore

#wait for player to deassert drop ball to continue game 
waitPlayerDeassertBallDrop: # read rInport, mask bit (2), repeat until rInport(2) = 0
 lw x4, 0xc(x5)  
 andi x6, x4, 4   
 #addi x5, x0, 0 	      # test: (uncomment if testing) deasserts rInport(2) 
 bne x6, x0, waitPlayerDeassertBallDrop 
 ret 

updateHighScore:
addi x14, x15, 0  #add new highscore to highscore register
sw x14, 8(x0) # store high score
beq x0, x0, setupconstants  #game is over reset game

makeBasketSmaller:
bge x15,x20, seedBasket
addi x11, x23, 0
srli x11, x11, 1
addi x23, x11, 0
beq x0, x0, seedBasket
#player deasserts drop ball bit -> seed ball and begin main again

delay2:
lui x8, 0x002EE
ret


