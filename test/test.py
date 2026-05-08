import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles, RisingEdge

@cocotb.test()
async def test_project(dut):
    dut._log.info("Start Simulation")

    # 1. Start the clock
    clock = Clock(dut.clk, 10, units="us")
    cocotb.start_soon(clock.start())

    # 2. Reset the CPU
    dut._log.info("Resetting...")
    dut.rst_n.value = 0
    # Clean up references to ui_in/uo_out since they aren't in your tb.v
    await ClockCycles(dut.clk, 10)
    dut.rst_n.value = 1
    dut._log.info("Reset Released")

    # 3. The "Sequential" Testing
    # Instead of checking math, we watch the CPU run your program.hex
    for i in range(50):
        await RisingEdge(dut.clk)
        
        # Pull the Program Counter (PC) value from deep inside your Verilog
        # Path: tb -> processor_top (dut) -> proc (no_spi) -> pc_inst -> pc_out
        try:
            current_pc = dut.dut.proc.pc_val.value # Adjust this path to match your Verilog
            dut._log.info(f"Cycle {i}: PC is {current_pc}")
        except AttributeError:
            # If the path is wrong, this prevents a crash while you're debugging names
            pass

    # 4. The Final Assertion
    # Check if a specific register reached the value you expected from your ASM
    # final_val = dut.dut.proc.executor.reg_bank[3].value
    # assert final_val == 1

    # Reset for only 2 cycles instead of 10 to see movement faster
    dut.rst_n.value = 0
    await ClockCycles(dut.clk, 2)
    dut.rst_n.value = 1

    # Run for MORE cycles
    for i in range(50):
        await RisingEdge(dut.clk)
        # Use .integer to see 0 instead of 00000000000
        pc_val = dut.dut.proc.fetch_addr.value.to_unsigned()
        instr_val = str(dut.dut.proc.fetch_instr.value)
        # dut._log.info(f"Cycle {i} | PC: {pc_val} | Hex: {instr_val}")
        # Add this inside your loop in test.py
        # Add this right after Reset Released
        try:
            # We remove '.proc' because mh is a sibling of proc, not a child
            rom_val = dut.dut.mh.rom[0].value
            dut._log.info(f"Direct ROM[0] Check: {rom_val}")
        except Exception as e:
            dut._log.info(f"Could not reach ROM: {e}")