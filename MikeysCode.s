#ground floor
main:
addi x10, x0, -1
sw x10, 16(x0)

# boat size bottom register 11
addi x11, x0, 255
sw x11, 24(x0)

#boat walls register x12
addi x12, x0, 129
sw x12, 28(x0)
sw x12, 32(x0)

#ball 
lui x13, 0x10
sw x13, 56(x0)

#high score register x14
addi x14, x0, 8
sw x14, 8(x0)

# current score register x15
addi x15, x0, 2
sw x15, 4(x0)

# player gets good score basket smaller test code 
srli x11, x11, 1
srli x12, x12, 1 
addi x12, x12, 1

sw x11, 24(x0)
sw x12, 28(x0)
sw x12, 32(x0)
beq x0, x0, main
