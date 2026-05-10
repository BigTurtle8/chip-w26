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
    dut.fetch_done.value = 0
    dut.decode_done.value = 0
    dut.executor_done.value = 0
    await ClockCycles(dut.clk, 10)
    dut.rst.value = 0

    dut._log.info("Test project behavior")

    dut._log.info("See fetch trigger on initial start up")
    # https://docs.cocotb.org/en/stable/timing_model.html
    # cocotb will not have triggered the downstream effects
    # of a clock cycle
    # By ReadWrite it will process the downstream effects,
    # but further writes can be made and affect the circuit
    # (i.e. like a combinational circuit)
    # After ReadOnly, all values from this clock cycle
    # are completed and we can see the effects
    await ReadOnly()
    assert dut.begin_fetch.value == 1
    assert dut.begin_decode.value == 0
    assert dut.begin_executor.value == 0

    dut._log.info("Fetch trigger should be one-pulse")
    await ClockCycles(dut.clk, 1)
    await ReadOnly()
    assert dut.begin_fetch.value == 0
    assert dut.begin_decode.value == 0
    assert dut.begin_executor.value == 0

    dut._log.info("Without further signals, should not start anything else")
    for _ in range(5):
        await ClockCycles(dut.clk, 1)
        await ReadOnly()
        assert dut.begin_fetch.value == 0
        assert dut.begin_decode.value == 0
        assert dut.begin_executor.value == 0

    dut._log.info("Finishing fetch should combinationally lead to decode")
    await NextTimeStep()
    dut.fetch_done.value = 1
    await ReadOnly()
    assert dut.begin_decode.value == 1

    dut._log.info("With fetch finish as one-pulse, decode start should be one-pulse")
    await ClockCycles(dut.clk, 1)
    assert dut.begin_decode.value == 1  # Confirm that can one-pulse to begin on rising edge
    dut.fetch_done.value = 0
    await ReadOnly()
    assert dut.begin_decode.value == 0

    dut._log.info("Follow similar process with decode to executor")
    await NextTimeStep()
    dut.decode_done.value = 1
    await ReadOnly()
    assert dut.begin_executor.value == 1

    await ClockCycles(dut.clk, 1)
    assert dut.begin_executor.value == 1
    dut.decode_done.value = 0
    await ReadOnly()
    assert dut.begin_executor.value == 0


    dut._log.info("Finally, similar process with executor to fetch")
    await ClockCycles(dut.clk, 10)
    await NextTimeStep()
    dut.executor_done.value = 1
    await ReadOnly()
    assert dut.begin_fetch.value == 1

    await ClockCycles(dut.clk, 1)
    assert dut.begin_fetch.value == 1
    dut.executor_done.value = 0
    await ReadOnly()
    assert dut.begin_fetch.value == 0

    await ClockCycles(dut.clk, 5)
