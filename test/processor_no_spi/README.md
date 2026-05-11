To test different `.hex` files, go into `test.py` and edit what gets passed into `load_hex_file` and assigned to `my_program`.

As of 5/11, some of these `.hex` files were tested with a version of the processor that did not have VGA incorporated, and thus had `r6` and `r7` available. This includes `fibonacci.asm`, `program.hex`, and `fixed_program.hex`.

`fibo_vga_compat.asm` and its corresponding `program.hex` are scripts that should be compatible with only 4 registers.
