// Initialization
ADDI r1, r0, #0     // Fib(n-2) = 0
ADDI r2, r0, #1     // Fib(n-1) = 1
ADDI r3, r0, #0     // Loop Counter (n)

loop:
// 0. (Re)-initialize r4, which is auto. used as `ro` for BLT
ADDI r4, r0, #31   // Starting memory address for storage
ADDI r4, r4, #31
ADDI r4, r4, #31
ADDI r4, r4, #7
ADD r4, r3, r4

// 1. Store the current Fibonacci number
STORE r4, r1        // Mem[r4] = Fib(n-2)

// 2. Calculate the next Fibonacci number
ADD r5, r1, r2      // r5 = Fib(n-2) + Fib(n-1)
ADDI r1, r2, #0     // r1 = r2 (Shift old Fib(n-1) to Fib(n-2))
ADDI r2, r5, #0     // r2 = r5 (New Fibonacci number)

// 3. Update loop pointers
ADDI r3, r3, #1     // Increment Counter
ADDI r4, r4, #1     // Increment Memory Pointer

// 4. Branch
ADDI r5, r0, #10
BLT loop, r3, r5    // If counter < 10, go to loop
