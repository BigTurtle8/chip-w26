import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles, FallingEdge, RisingEdge, Timer, ReadWrite, ReadOnly, NextTimeStep, First

@cocotb.test()
async def test_project(dut):
    # 0. Load the memory dictionary
    my_program = load_hex_file("dummy_vga.hex")

    # 1. Start Clock
    cocotb.start_soon(Clock(dut.clk, 10, unit="ns").start())

    # 2. Initial Setup (Reset)
    dut.rst_n.value = 0
    dut.uio_in.value = 0
    # Ensure we hit at least 2-3 rising edges of CLK while RST is high
    await Timer(50, unit="ns") 
    
    # Before beginning, start the memory background tasks
    cocotb.start_soon(flash_memory_model(dut, my_program))
    ram_lst = [0] * 256
    cocotb.start_soon(ram_memory_model(dut, ram_lst))

    await RisingEdge(dut.clk)
    await RisingEdge(dut.clk)
    dut.rst_n.value = 1

    # await ClockCycles(dut.clk, 50000)
    await ClockCycles(dut.clk, 300000)

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

async def flash_memory_model(dut, mem_dict):
    while True:
        await dut.cs.value_change
        if dut.cs.value.to_unsigned() & 1 == 0:
            await fetch_cycle(dut, mem_dict)

async def ram_memory_model(dut, mem_lst):
    while True:
        await dut.cs.value_change
        if dut.cs.value.to_unsigned() & (1 << 1) == 0:
            await ram_cycle(dut, mem_lst)

# Regular fetch cycle at a certain 24-bit address
# and for a certain 16-bit instruction.
# Assumes no other memory request occuring at same time
async def fetch_cycle(dut, mem_dict):
    dut._log.info("Fetching...")
    assert dut.cs.value == 0b110
    assert dut.sck.value == 0

    await check_mosi_value(dut, 0x03, 8)

    address = await read_mosi_value(dut, 24)
    word_idx = address >> 1
    instruction = mem_dict.get(word_idx, 0)
    dut._log.info("|- At addr [" + str(address) +"] for instruction "
                    + format(instruction, "#018b"))

    await write_miso_value(dut, instruction, 16)

# Regular RAM cycle, looks for command then calls
# correct followup (either load or store cycle)
async def ram_cycle(dut, mem_lst):
    dut._log.info("Accessing RAM...")
    assert dut.cs.value == 0b101
    assert dut.sck.value == 0

    command = await read_mosi_value(dut, 8)
    if command == 0x03:
        await load_cycle(dut, mem_lst)
    elif command == 0x02:
        await store_cycle(dut, mem_lst)
    else:
        assert 0 == 1

# Regular load cycle at a certain 24-bit address
# and for a certain 8-bit data value
async def load_cycle(dut, mem_lst):
    dut._log.info("|- Loading...")

    address = await read_mosi_value(dut, 24)
    instruction = mem_lst[address]
    dut._log.info("  |- From addr [" + str(address) +"] for data "
                    + format(data, "#010b"))

    await write_miso_value(dut, data, 8)

# Regular store cycle at a certain 24-bit address
# with a certain 8-bit data value
async def store_cycle(dut, mem_lst):
    dut._log.info("|- Storing...")

    address = await read_mosi_value(dut, 24)

    data = await read_mosi_value(dut, 8)

    dut._log.info("  |- To addr [" + str(address) +"], data "
                    + format(data, "#010b"))
    mem_lst[address] = data

# Check the next `length` values from
# `mosi`, and assuming they are sent
# MSB first, checks if they match `expected`
async def check_mosi_value(dut, expected, length):
    for i in range(length):
        idx = length - i - 1
        expected_bit = (expected & (1 << idx)) >> idx
        await check_next_mosi(dut, expected_bit)

# Move to next `sck` and check that `mosi`
# pin is a certain value, both before
# and after downstream effects (very roughly simulating
# that `mosi` should be stable when being latched)
# Leaves off on `ReadOnly` of `sck` rising
async def check_next_mosi(dut, expected):
    await RisingEdge(dut.sck)
    assert dut.mosi.value == expected
    await ReadOnly()
    assert dut.mosi.value == expected

# Read the next `length` values from
# `mosi`, and assuming they are sent
# MSB first
async def read_mosi_value(dut, length):
    val = 0
    for i in range(length):
        val = (val << 1) + await read_next_mosi(dut)

    return val

# Move to next `sck` and read `mosi`
# Leaves off on `ReadOnly` of `sck` rising
async def read_next_mosi(dut):
    await RisingEdge(dut.sck)
    await ReadOnly()
    return int(dut.mosi.value)

# Write `val` through miso over the next
# `length` cycles of `sck`s. Leaves off
# on `FallingEdge` of sck, in case is final
# read (and so `sck` would not rise again)
async def write_miso_value(dut, val, length):
    for i in range(length - 1):
        idx = length - i - 1
        bit = (val & (1 << idx)) >> idx
        await write_miso(dut, bit)
        await RisingEdge(dut.sck)

    await write_miso(dut, val & 1)

# From rising `sck` edge, go to next falling `sck`
# edge and write `val` to `miso`
# NOTE: Means this writes to next `sck`, not current
async def write_miso(dut, val):
    await FallingEdge(dut.sck)
    dut.miso.value = val
