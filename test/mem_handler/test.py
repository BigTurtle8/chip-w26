# SPDX-FileCopyrightText: © 2024 Tiny Tapeout
# SPDX-License-Identifier: Apache-2.0

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles, ReadWrite, ReadOnly, NextTimeStep, RisingEdge, FallingEdge


@cocotb.test()
async def test_fetch(dut):
    # Set the clock period to 10 us (100 KHz)
    clock = Clock(dut.clk, 10, unit="us")
    cocotb.start_soon(clock.start())

    # Reset
    dut._log.info("Reset")
    dut.rst.value = 1
    dut.fetch_req.value = 0
    dut.fetch_addr.value = 0
    dut.mem_req.value = 0
    dut.mem_w_req.value = 0
    dut.mem_addr.value = 0
    dut.mem_w_val.value = 0
    dut.miso.value = 0
    await ClockCycles(dut.clk, 10)
    dut.rst.value = 0

    await test_fetch_cycle(dut, 6, 0b001_001_000_011101_0)


@cocotb.test()
async def test_load(dut):
    # Set the clock period to 10 us (100 KHz)
    clock = Clock(dut.clk, 10, unit="us")
    cocotb.start_soon(clock.start())

    # Reset
    dut._log.info("Reset")
    dut.rst.value = 1
    dut.fetch_req.value = 0
    dut.fetch_addr.value = 0
    dut.mem_req.value = 0
    dut.mem_w_req.value = 0
    dut.mem_addr.value = 0
    dut.mem_w_val.value = 0
    dut.miso.value = 0
    await ClockCycles(dut.clk, 10)
    dut.rst.value = 0

    await test_load_cycle(dut, 15, 0xe2)


@cocotb.test()
async def test_fetch_then_load(dut):
    # Set the clock period to 10 us (100 KHz)
    clock = Clock(dut.clk, 10, unit="us")
    cocotb.start_soon(clock.start())

    # Reset
    dut._log.info("Reset")
    dut.rst.value = 1
    dut.fetch_req.value = 0
    dut.fetch_addr.value = 0
    dut.mem_req.value = 0
    dut.mem_w_req.value = 0
    dut.mem_addr.value = 0
    dut.mem_w_val.value = 0
    dut.miso.value = 0
    await ClockCycles(dut.clk, 10)
    dut.rst.value = 0

    await test_fetch_cycle(dut, 1000, 0b100_011_100_000_0000)
    await test_load_cycle(dut, 15, 0xe2)
    await test_fetch_cycle(dut, 502, 0b101_011_100_010_0000)
    await test_fetch_cycle(dut, 138, 0b010_100_010_0000000)


@cocotb.test()
async def test_store(dut):
    # Set the clock period to 10 us (100 KHz)
    clock = Clock(dut.clk, 10, unit="us")
    cocotb.start_soon(clock.start())

    # Reset
    dut._log.info("Reset")
    dut.rst.value = 1
    dut.fetch_req.value = 0
    dut.fetch_addr.value = 0
    dut.mem_req.value = 0
    dut.mem_w_req.value = 0
    dut.mem_addr.value = 0
    dut.mem_w_val.value = 0
    dut.miso.value = 0
    await ClockCycles(dut.clk, 10)
    dut.rst.value = 0

    await test_store_cycle(dut, 3, 0x11)


# Test regular fetch cycle at a certain 24-bit address
# and for a certain 16-bit instruction.
# Assumes no other memory request occuring at same time
async def test_fetch_cycle(dut, address, instruction):
    dut._log.info("--!!-- Test fetch at addr [" + str(address) +"] for instruction "
                    + format(instruction, "#018b"))

    # Wait for one clock cycle to see the output values
    # https://docs.cocotb.org/en/stable/timing_model.html
    # cocotb will not have triggered the downstream effects
    # of this clock cycle
    await ClockCycles(dut.clk, 1)
    # By ReadWrite it will process the downstream effects,
    # but further writes can be made and affect the circuit
    # (i.e. like a combinational circuit)
    # After ReadOnly, all values from this clock cycle
    # are completed and we can see the effects
    await ReadOnly()

    assert dut.cs.value == 0b111
    assert dut.sck.value == 0

    dut._log.info("On fetch request, should not see any combinational output")
    await NextTimeStep()
    dut.fetch_req.value = 1;
    dut.fetch_addr.value = address

    await ReadWrite()
    assert dut.cs.value == 0b111
    assert dut.sck.value == 0

    dut._log.info("But then on next cycle, should have (de)asserted CS")
    await ClockCycles(dut.clk, 1)
    await ReadOnly()

    assert dut.cs.value == 0b110
    assert dut.sck.value == 0

    '''
    dut._log.info("Then expect to see sck 'divided' by 2 from `clk`")
    for _ in range(10):
        await ClockCycles(dut.clk, 1)
        await ReadOnly()

        assert dut.cs.value == 0b110
        assert dut.sck.value == 1

        await ClockCycles(dut.clk, 1)
        await ReadOnly()

        assert dut.cs.value == 0b110
        assert dut.sck.value == 0
    '''

    dut._log.info("Expect to see 0x03 on MOSI on rising edge of SCK")
    await check_mosi_value(dut, 0x03, 8)

    dut._log.info("Expect to see correct 24-bit address through SPI on MOSI")
    await check_mosi_value(dut, address, 24)

    dut._log.info("Write intended instruction through MISO")
    await write_miso_value(dut, instruction, 16)

    dut._log.info("Now wait for expected fetch_valid, then de-request")
    await RisingEdge(dut.fetch_valid)
    await ReadOnly()
    assert dut.fetch_instr.value == instruction

    await ClockCycles(dut.clk, 1)  # De-request is latched on clock cycle
    dut.fetch_req.value = 0

    await ClockCycles(dut.clk, 1)


# Test regular fetch cycle at a certain 24-bit address
# and for a certain 8-bit data value
async def test_load_cycle(dut, address, data):
    dut._log.info("--!!-- Test load at addr [" + str(address) +"] for data "
                    + format(data, "#010b"))

    await ClockCycles(dut.clk, 1)
    await ReadOnly()

    assert dut.cs.value == 0b111
    assert dut.sck.value == 0

    dut._log.info("On fetch request, should not see any combinational output")
    await NextTimeStep()
    dut.mem_req.value = 1
    dut.mem_addr.value = address

    await ReadWrite()
    assert dut.cs.value == 0b111
    assert dut.sck.value == 0

    dut._log.info("But then on next cycle, should have (de)asserted CS")
    await ClockCycles(dut.clk, 1)
    await ReadOnly()

    assert dut.cs.value == 0b101
    assert dut.sck.value == 0

    dut._log.info("Expect to see 0x03 on MOSI on rising edge of SCK")
    await check_mosi_value(dut, 0x03, 8)

    dut._log.info("Expect to see correct 24-bit address through SPI on MOSI")
    await check_mosi_value(dut, address, 24)

    dut._log.info("Write intended data through MISO")
    await write_miso_value(dut, data, 8)

    dut._log.info("Now wait for expected mem_valid, then de-request")
    await RisingEdge(dut.mem_valid)
    await ReadOnly()
    assert dut.mem_val.value == data 

    await ClockCycles(dut.clk, 1)  # De-request is latched on clock cycle
    dut.mem_req.value = 0

    await ClockCycles(dut.clk, 1)


# Test regular store cycle at a certain 24-bit address
# with a certain 8-bit data value
async def test_store_cycle(dut, address, data):
    dut._log.info("--!!-- Test store at addr [" + str(address) +"] of data "
                    + format(data, "#010b"))

    await ClockCycles(dut.clk, 1)
    await ReadOnly()

    assert dut.cs.value == 0b111
    assert dut.sck.value == 0

    dut._log.info("On store request, should not see any combinational output")
    await NextTimeStep()
    dut.mem_w_req.value = 1
    dut.mem_addr.value = address
    dut.mem_w_val.value = data

    await ReadWrite()
    assert dut.cs.value == 0b111
    assert dut.sck.value == 0

    dut._log.info("But then on next cycle, should have (de)asserted CS")
    await ClockCycles(dut.clk, 1)
    await ReadOnly()

    assert dut.cs.value == 0b101
    assert dut.sck.value == 0

    dut._log.info("Expect to see 0x02 on MOSI on rising edge of SCK")
    await check_mosi_value(dut, 0x02, 8)

    dut._log.info("Expect to see correct 24-bit address through SPI on MOSI")
    await check_mosi_value(dut, address, 24)

    dut._log.info("Expect to see correct data through MOSI")
    await check_mosi_value(dut, data, 8)

    dut._log.info("Now wait for expected mem_w_done, then de-request")
    await RisingEdge(dut.mem_w_done)
    await ReadOnly()

    await ClockCycles(dut.clk, 1)  # De-request is latched on clock cycle
    dut.mem_w_req.value = 0

    await ClockCycles(dut.clk, 1)


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
