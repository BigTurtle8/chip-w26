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
    dut.begin_load.value = 0
    dut.addr.value = 0
    dut.mem_valid.value = 0
    dut.mem_val.value = 0
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

    assert dut.mem_req.value == 0

    dut._log.info("Go through standard expected load cycle")
    # Go to next time step, where can write again
    await NextTimeStep()
    dut.begin_load.value = 1
    dut.addr.value = 8

    assert dut.mem_req.value == 0
    await ClockCycles(dut.clk, 1) 
    await ReadOnly()
    assert dut.mem_req.value == 1
    assert dut.mem_addr.value == 8
    assert dut.load_done.value == 0

    dut._log.info("Even after many cycles, should stay steady without other inputs")
    await NextTimeStep()
    dut.begin_load.value = 0
    dut.addr.value = 4

    for _ in range(10):
        await ClockCycles(dut.clk, 1)
        await ReadOnly()

        assert dut.mem_req.value == 1
        assert dut.mem_addr.value == 8
        assert dut.load_done.value == 0;

    dut._log.info("Receive value; should combinationally pass along")
    await NextTimeStep()
    dut.mem_valid.value = 1
    dut.mem_val.value = 0xb4

    await ReadOnly()
    assert dut.load_done.value == 1
    assert dut.load_val.value == 0xb4

    dut._log.info("Then should no longer be requesting on next clock cycle")
    await ClockCycles(dut.clk, 1)
    dut.mem_valid.value = 0

    await ReadOnly()
    assert dut.mem_req.value == 0

    await ClockCycles(dut.clk, 5)
