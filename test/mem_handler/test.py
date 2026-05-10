# SPDX-FileCopyrightText: © 2024 Tiny Tapeout
# SPDX-License-Identifier: Apache-2.0

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles, ReadWrite, ReadOnly, NextTimeStep, RisingEdge, FallingEdge


@cocotb.test()
async def test_project(dut):
    dut._log.info("Start")

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

    dut._log.info("Test project behavior")

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
    dut.fetch_addr.value = 6

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

    dut._log.info("Expect to see 6 as the 24-bit address through SPI on MOSI")
    await check_mosi_value(dut, 6, 24)

    dut._log.info("Write intended instruction through MISO")
    instruction = 0b001_001_000_011101_0
    await write_miso_value(dut, instruction, 16)

    dut._log.info("Now wait for expected fetch_valid, then de-request")
    await RisingEdge(dut.fetch_valid)
    await ReadOnly()
    assert dut.fetch_instr.value == instruction

    await ClockCycles(dut.clk, 1)  # De-request is latched on clock cycle
    dut.fetch_req.value = 0

    await ClockCycles(dut.clk, 5)


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
