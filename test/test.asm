// Test 1: Simple Immediate and Addition
ADDI r1, r0, #5    // r1 = 5
ADDI r2, r0, #10   // r2 = 10

// Test 2: Label and Backward Jump (Looping)
start:
ADDI r1, r1, #1    // Increment r1

// Test 3: BLT with a Label (This triggers your placeholder logic)
// If r1 < r2, jump back to 'start'
BLT start, r1, r2

// Test 4: Forward Jump
BLT end, r0, r2    // Always true (0 < 10), jump to end
ADDI r3, r0, #99   // This should be skipped

end:
ADDI r3, r0, #1    // Final instruction