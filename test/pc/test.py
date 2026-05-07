# SPDX-FileCopyrightText: © 2024 Tiny Tapeout
# SPDX-License-Identifier: Apache-2.0

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles, ReadOnly, NextTimeStep


@cocotb.test()
async def test_project(dut):
    dut._log.info("Start")

    # Set the clock period to 10 us (100 KHz)
    clock = Clock(dut.clk, 10, unit="us")
    cocotb.start_soon(clock.start())

    # Reset
    dut._log.info("Reset")
    dut.rst.value = 1
    dut.incr.value = 0
    dut.new_addr.value = 0
    dut.we.value = 0
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

    assert dut.pc.value == 0

    # Expect +2 increment
    # Go to next time step, where can write again
    await NextTimeStep()
    dut.incr.value = 1;

    assert dut.pc.value == 0
    await ClockCycles(dut.clk, 1) 
    await ReadOnly()
    assert dut.pc.value == 2

    # Expect no increment
    await NextTimeStep()
    dut.incr.value = 0;

    assert dut.pc.value == 2
    await ClockCycles(dut.clk, 1)
    await ReadOnly()
    assert dut.pc.value == 2

    # Try to set new address (max of 2^11 - 1 = 2047)
    await NextTimeStep()
    dut.new_addr.value = 2044
    dut.we.value = 1

    assert dut.pc.value == 2
    await ClockCycles(dut.clk, 1)
    await ReadOnly()
    assert dut.pc.value == 2044

    # Should not rewrite with `we` low
    await NextTimeStep()
    dut.new_addr.value = 6
    dut.we.value = 0

    assert dut.pc.value == 2044
    await ClockCycles(dut.clk, 1)
    await ReadOnly()
    assert dut.pc.value == 2044

    # Expect overflow
    await NextTimeStep()
    dut.incr.value = 1

    assert dut.pc.value == 2044
    await ClockCycles(dut.clk, 2)
    await ReadOnly()
    assert dut.pc.value == 0
