// Initialization
ADDI r1, r0, #0     // Fib(n-2) = 0
ADDI r2, r0, #1     // Fib(n-1) = 1
ADDI r3, r0, #0     // Loop Counter (n)
ADDI r4, r0, #10    // Stop after 10 iterations
ADDI r5, r0, #100   // Starting memory address for storage

loop:
// 1. Store the current Fibonacci number
STORE r5, r1        // Mem[r5] = Fib(n-2)

// 2. Calculate the next Fibonacci number
ADD r6, r1, r2      // r6 = Fib(n-2) + Fib(n-1)
ADDI r1, r2, #0     // r1 = r2 (Shift old Fib(n-1) to Fib(n-2))
ADDI r2, r6, #0     // r2 = r6 (New Fibonacci number)

// 3. Logic & Shifting (Testing these for complexity)
NAND r7, r1, r1     // r7 = NOT r1 (Just to test NAND)
SHFT r7, r7, r2, L  // r7 = r7 << r2 (Testing Shift logic)

// 4. Update loop pointers
ADDI r3, r3, #1     // Increment Counter
ADDI r5, r5, #1     // Increment Memory Pointer

// 5. Branch
BLT loop, r3, r4    // If counter < 10, go to loop