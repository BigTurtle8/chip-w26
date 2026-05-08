# SPDX-FileCopyrightText: © 2024 Tiny Tapeout
# SPDX-License-Identifier: Apache-2.0

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles, RisingEdge


async def decode(dut, instruction):
    """Helper: send one instruction and wait for decode_done."""
    dut.ins.value = instruction
    dut.begin_decode.value = 1
    await RisingEdge(dut.clk)
    dut.begin_decode.value = 0
    await RisingEdge(dut.clk)  # decode_done goes low


@cocotb.test()
async def test_reset(dut):
    """checks all vals == 0 after reset"""
    clock = Clock(dut.clk, 10, units="us")
    cocotb.start_soon(clock.start())

    dut.rst_n.value = 0
    dut.begin_decode.value = 0
    dut.ins.value = 0
    await ClockCycles(dut.clk, 3)

    assert dut.store.value == 0
    assert dut.load.value == 0
    assert dut.decode_done.value == 0
    assert dut.shft.value == 0
    assert dut.r2_or_imm.value == 0

    dut.rst_n.value = 1


@cocotb.test()
async def test_store(dut):
    """tests store"""
    clock = Clock(dut.clk, 10, units="us")
    cocotb.start_soon(clock.start())

    dut.rst_n.value = 0
    dut.begin_decode.value = 0
    await ClockCycles(dut.clk, 2)
    dut.rst_n.value = 1

    # opcode in bits [2:0] = 0b011
    await decode(dut, 0b0000_000_000_000_011)

    assert dut.store.value == 1
    assert dut.load.value == 0
    assert dut.decode_done.value == 1


@cocotb.test()
async def test_load(dut):
    """tests load"""
    clock = Clock(dut.clk, 10, units="us")
    cocotb.start_soon(clock.start())

    dut.rst_n.value = 0
    dut.begin_decode.value = 0
    await ClockCycles(dut.clk, 2)
    dut.rst_n.value = 1

    await decode(dut, 0b0000_000_000_000_010)

    assert dut.load.value == 1
    assert dut.store.value == 0


@cocotb.test()
async def test_shift_opcodes(dut):
    """tests shft and shft1"""
    clock = Clock(dut.clk, 10, units="us")
    cocotb.start_soon(clock.start())

    dut.rst_n.value = 0
    dut.begin_decode.value = 0
    await ClockCycles(dut.clk, 2)
    dut.rst_n.value = 1

    await decode(dut, 0b0000_000_000_000_110)
    assert dut.shft.value == 1

    await decode(dut, 0b0000_000_000_000_111)
    assert dut.shft.value == 1


@cocotb.test()
async def test_r2_or_imm(dut):
    """tests r2 or imm checker"""
    clock = Clock(dut.clk, 10, units="us")
    cocotb.start_soon(clock.start())

    dut.rst_n.value = 0
    dut.begin_decode.value = 0
    await ClockCycles(dut.clk, 2)
    dut.rst_n.value = 1

    await decode(dut, 0b0000_000_000_000_001)
    assert dut.r2_or_imm.value == 1

    await decode(dut, 0b0000_000_000_000_111)
    assert dut.r2_or_imm.value == 1


@cocotb.test()
async def test_field_extraction(dut):
    """checks se, rt, imm, l extracted from the correct bit positions"""
    clock = Clock(dut.clk, 10, units="us")
    cocotb.start_soon(clock.start())

    dut.rst_n.value = 0
    dut.begin_decode.value = 0
    await ClockCycles(dut.clk, 2)
    dut.rst_n.value = 1

    # Craft an instruction with known fields:
    # l=1, imm=ins[14:9], rt=ins[11:9], se=ins[8:6], tf[3:1]=ins[5:3]
    # Use opcode=000 so no special flags are set
    # ins = 1_011011_101_010_000  (bit 15 down to 0)
    #   l=1, ins[14:9]=011011 (imm=27), ins[11:9]=011 (rt=3, also part of imm),
    #   ins[8:6]=101 (se=5), ins[5:3]=010 (tf[3:1]=2), opcode=000
    ins = 0b1_011011_101_010_000
    await decode(dut, ins)

    assert dut.l.value == 1
    assert dut.se.value == 0b101   # ins[8:6]
    assert dut.rt.value == 0b011   # ins[11:9]
    assert dut.imm.value == 0b011011  # ins[14:9]


@cocotb.test()
async def test_decode_done_clears(dut):
    """decode_done = 0 when begin_decode isn't on"""
    clock = Clock(dut.clk, 10, units="us")
    cocotb.start_soon(clock.start())

    dut.rst_n.value = 0
    dut.begin_decode.value = 0
    await ClockCycles(dut.clk, 2)
    dut.rst_n.value = 1

    await decode(dut, 0b0000_000_000_000_010)
    assert dut.decode_done.value == 1

    # One more cycle with begin_decode=0 => done should clear
    await RisingEdge(dut.clk)
    assert dut.decode_done.value == 0