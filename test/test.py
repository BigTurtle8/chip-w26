import cocotb
from cocotb.clock import Clock
from cocotb.triggers import FallingEdge, RisingEdge, Timer, Edge, ReadOnly

def load_hex_file(file_path):
    mem = {}
    idx = 0
    with open(file_path, "r") as f:
        for line in f:
            # Strip comments and whitespace
            clean_line = line.split("//")[0].strip()
            if clean_line:
                try:
                    # CHANGE THIS: Use base 2 for binary strings
                    val = int(clean_line, 2) & 0xFFFF
                    mem[idx] = val
                    idx += 1
                except ValueError:
                    # Fallback for actual Hex if needed
                    val = int(clean_line, 16) & 0xFFFF
                    mem[idx] = val
                    idx += 1
    return mem

from cocotb.triggers import ReadOnly

async def memory_model(dut, mem_dict):
    while True:
        await Edge(dut.fetch_req) 
        if dut.fetch_req.value == 1:
            addr = dut.fetch_addr.value.to_unsigned()
            word_idx = addr >> 1
            
            # This will show up in your terminal logs
            val = mem_dict.get(word_idx, 0)
            dut._log.info(f"MEMORY: Fetch Addr {addr} (Word {word_idx}) -> Driving {val:016b}")
            
            dut.fetch_instr.value = val
            dut.fetch_valid.value = 1
        else:
            dut.fetch_valid.value = 0

@cocotb.test()
async def test_project(dut):
    # 0. Load the memory dictionary
    my_program = load_hex_file("dummy.hex")
    
    # Start the memory background task
    cocotb.start_soon(memory_model(dut, my_program))

    # 1. Start Clock
    cocotb.start_soon(Clock(dut.clk, 10, unit="ns").start())

    # 2. Initial Setup (Reset)
    dut.rst.value = 1
    # Ensure we hit at least 2-3 rising edges of CLK while RST is high
    await Timer(50, unit="ns") 
    await RisingEdge(dut.clk)
    await RisingEdge(dut.clk)
    dut.rst.value = 0

    # 4. Monitoring Loop
    for i in range(100):
        await RisingEdge(dut.clk)
        
        # Current status
        pc_val = dut.dut.pc_instance.pc.value
        instr_val = dut.fetch_instr.value
        
        dut._log.info(f"Cycle {i:2d} | PC: {pc_val} | Instr: {instr_val}")

        # If your hardware isn't generating fetch_done yet, 
        # keep your 'force' logic here, but the memory_model 
        # above will at least provide REAL instructions now.