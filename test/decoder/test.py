# SPDX-FileCopyrightText: © 2024 Tiny Tapeout
# SPDX-License-Identifier: Apache-2.0

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles, RisingEdge


async def decode(dut, instruction):
    """helper: send one instruction and wait for decode_done."""
    dut.instruction.value = instruction
    dut.begin_decode.value = 1
    await RisingEdge(dut.clk)
    dut.begin_decode.value = 0
    await RisingEdge(dut.clk)  # decode_done goes low


@cocotb.test()
async def test_reset(dut):
    """checks all vals == 0 after reset"""
    clock = Clock(dut.clk, 10, units="us")
    cocotb.start_soon(clock.start())

    dut.rst.value = 0
    dut.begin_decode.value = 0
    dut.instruction.value = 0
    await ClockCycles(dut.clk, 3)

    assert dut.store.value == 0
    assert dut.load.value == 0
    assert dut.decode_done.value == 0
    assert dut.shft.value == 0
    assert dut.r2_or_imm.value == 0

    dut.rst.value = 1


@cocotb.test()
async def test_store(dut):
    """tests store"""
    clock = Clock(dut.clk, 10, units="us")
    cocotb.start_soon(clock.start())

    dut.rst.value = 0
    dut.begin_decode.value = 0
    await ClockCycles(dut.clk, 2)
    dut.rst.value = 1

    await decode(dut, 0b0000_000_000_000_011)

    assert dut.store.value == 1
    assert dut.load.value == 0
    assert dut.decode_done.value == 1


@cocotb.test()
async def test_load(dut):
    """tests load"""
    clock = Clock(dut.clk, 10, units="us")
    cocotb.start_soon(clock.start())

    dut.rst.value = 0
    dut.begin_decode.value = 0
    await ClockCycles(dut.clk, 2)
    dut.rst.value = 1

    await decode(dut, 0b0000_000_000_000_010)

    assert dut.load.value == 1
    assert dut.store.value == 0


@cocotb.test()
async def test_shift_opcodes(dut):
    """tests shft and shft1"""
    clock = Clock(dut.clk, 10, units="us")
    cocotb.start_soon(clock.start())

    dut.rst.value = 0
    dut.begin_decode.value = 0
    await ClockCycles(dut.clk, 2)
    dut.rst.value = 1

    await decode(dut, 0b0000_000_000_000_110)
    assert dut.shft.value == 1

    await decode(dut, 0b0000_000_000_000_111)
    assert dut.shft.value == 1


@cocotb.test()
async def test_r2_or_imm(dut):
    """tests r2 or imm checker"""
    clock = Clock(dut.clk, 10, units="us")
    cocotb.start_soon(clock.start())

    dut.rst.value = 0
    dut.begin_decode.value = 0
    await ClockCycles(dut.clk, 2)
    dut.rst.value = 1

    await decode(dut, 0b0000_000_000_000_001)
    assert dut.r2_or_imm.value == 1

    await decode(dut, 0b0000_000_000_000_111)
    assert dut.r2_or_imm.value == 1


@cocotb.test()
async def test_field_extraction(dut):
    """checks se, rt, imm, l extracted from the correct bit positions"""
    clock = Clock(dut.clk, 10, units="us")
    cocotb.start_soon(clock.start())

    dut.rst.value = 0
    dut.begin_decode.value = 0
    await ClockCycles(dut.clk, 2)
    dut.rst.value = 1

    instruction = 0b1_011011_101_010_000
    await decode(dut, instruction)

    assert dut.l.value == 1
    assert dut.se.value == 0b101
    assert dut.rt.value == 0b011
    assert dut.imm.value == 0b011011


@cocotb.test()
async def test_decode_done_clears(dut):
    """decode_done = 0 when begin_decode isn't on"""
    clock = Clock(dut.clk, 10, units="us")
    cocotb.start_soon(clock.start())

    dut.rst.value = 0
    dut.begin_decode.value = 0
    await ClockCycles(dut.clk, 2)
    dut.rst.value = 1

    await decode(dut, 0b0000_000_000_000_010)
    assert dut.decode_done.value == 1

    await RisingEdge(dut.clk)
    assert dut.decode_done.value == 0