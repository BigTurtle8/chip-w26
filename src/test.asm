// use # for immediates and // for comments

// Step 1: Set up comparison values
ADDI r1, r0, #5
ADDI r2, r0, #10
ADDI r4, r0, #4

// Step 2: The Test
BLT r4, r1, r2
ADDI r3, r0, #1 // the jump should work and we land on line 11
ADDI r3, r0, #2