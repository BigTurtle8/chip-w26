# Unique notes for `chip-w26`

To test different `.hex` files, go into `test.py` and edit what gets passed into `load_hex_file` and assigned to `my_program`.

~~As of 5/11, some of these `.hex` files were tested with a version of the processor that did not have VGA incorporated, and thus had `r6` and `r7` available. This includes `fibonacci.asm`, `program.hex`, and `fixed_program.hex`.``

~~fibo_vga_compat.asm` and its corresponding `program.hex` are scripts that should be compatible with only 5 registers.~~

Due to DRT convergence concerns, this version removes the connections directly to `r6` and `r7`. Instead, `r7` is used for VGA output (instead of `r5`), r1-r6 are general-purpose, and r1-r7 are all R/W-able.

Therefore should be able to run any `.hex` that would like, and might see some interesting patterns on the VGA screen.

# Sample testbench for a Tiny Tapeout project

This is a sample testbench for a Tiny Tapeout project. It uses [cocotb](https://docs.cocotb.org/en/stable/) to drive the DUT and check the outputs.
See below to get started or for more information, check the [website](https://tinytapeout.com/hdl/testing/).

## Setting up

1. Edit [Makefile](Makefile) and modify `PROJECT_SOURCES` to point to your Verilog files.
2. Edit [tb.v](tb.v) and replace `tt_um_example` with your module name.

## How to run

To run the RTL simulation:

```sh
make -B
```

To run gatelevel simulation, first harden your project and copy `../runs/wokwi/results/final/verilog/gl/{your_module_name}.v` to `gate_level_netlist.v`.

Then run:

```sh
make -B GATES=yes
```

If you wish to save the waveform in VCD format instead of FST format, edit tb.v to use `$dumpfile("tb.vcd");` and then run:

```sh
make -B FST=
```

This will generate `tb.vcd` instead of `tb.fst`.

## How to view the waveform file

Using GTKWave

```sh
gtkwave tb.fst tb.gtkw
```

Using Surfer

```sh
surfer tb.fst
```
