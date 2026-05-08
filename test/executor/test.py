# SPDX-FileCopyrightText: © 2024 Tiny Tapeout
# SPDX-License-Identifier: Apache-2.0

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles, RisingEdge

async def do_reset(dut):
    """Reset the executor and zero all inputs."""
    dut.rst.value          = 0
    dut.begin_execute.value = 0
    dut.store.value        = 0
    dut.load.value         = 0
    dut.tf.value           = 0
    dut.se.value           = 0
    dut.rt.value           = 0
    dut.imm.value          = 0
    dut.l.value            = 0
    dut.r2_or_imm.value    = 0
    dut.shft.value         = 0
    dut.nand_op.value      = 0
    dut.lsi_done.value     = 0
    dut.load_val.value     = 0
    dut.new_addr.value     = 0
    await ClockCycles(dut.clk, 2)
    dut.rst.value = 1
    await RisingEdge(dut.clk)


async def execute(dut, store=0, load=0, tf=0, se=0, rt=0,
                  imm=0, l=0, r2_or_imm=0, shft=0, nand_op=0,
                  new_addr=0):
    """Drive inputs and pulse begin_execute. Returns when executor_done fires."""
    dut.store.value        = store
    dut.load.value         = load
    dut.tf.value           = tf
    dut.se.value           = se
    dut.rt.value           = rt
    dut.imm.value          = imm
    dut.l.value            = l
    dut.r2_or_imm.value    = r2_or_imm
    dut.shft.value         = shft
    dut.nand_op.value      = nand_op
    dut.new_addr.value     = new_addr
    dut.begin_execute.value = 1
    await RisingEdge(dut.clk)
    dut.begin_execute.value = 0
    for _ in range(20):
        await RisingEdge(dut.clk)
        if dut.executor_done.value == 1:
            return
    raise RuntimeError("executor_done never fired")


async def addi(dut, rd, r1, immediate):
    """Helper: ADDI rd = reg[r1] + imm  (opcode 001, r2_or_imm=1)"""
    await execute(dut,
                  tf=((rd << 1) & 0xF),
                  se=r1,
                  imm=immediate,
                  r2_or_imm=1)


def reg(dut, index):
    """Read register value directly from the internal register file."""
    return int(dut.dut.regs[index].value)

@cocotb.test()
async def test_reset(dut):
    """All outputs should be 0 after reset."""
    clock = Clock(dut.clk, 10, units="us")
    cocotb.start_soon(clock.start())
    await do_reset(dut)

    assert dut.executor_done.value == 0
    assert dut.lsi_begin.value == 0
    assert dut.pc_we.value == 0
    for i in range(8):
        assert reg(dut, i) == 0, f"reg[{i}] should be 0 after reset"


@cocotb.test()
async def test_addi(dut):
    """ADDI: rd = r1 + imm. With r0=0, sets rd = imm."""
    clock = Clock(dut.clk, 10, units="us")
    cocotb.start_soon(clock.start())
    await do_reset(dut)

    # ADDI r1 = r0 + 7  =>  r1 should be 7
    await addi(dut, rd=1, r1=0, immediate=7)
    assert reg(dut, 1) == 7

@cocotb.test()
async def test_add(dut):
    """ADD: rd = r1 + r2."""
    clock = Clock(dut.clk, 10, units="us")
    cocotb.start_soon(clock.start())
    await do_reset(dut)

    await addi(dut, rd=1, r1=0, immediate=10)  
    await addi(dut, rd=2, r1=0, immediate=6) 

    # ADD r3 = r1 + r2  (opcode 000: r2_or_imm=0, shft=0, nand_op=0, tf[0]=0)
    await execute(dut,
                  tf=((3 << 1) & 0xF),  
                  se=1,              
                  rt=2,              
                  r2_or_imm=0)
    assert reg(dut, 3) == 16


@cocotb.test()
async def test_nand(dut):
    """NAND: rd = ~(r1 & r2)."""
    clock = Clock(dut.clk, 10, unit="us")
    cocotb.start_soon(clock.start())
    await do_reset(dut)

    # Changed immediate from 204 to 0b110011 (51), which fits in 6 bits
    await addi(dut, rd=1, r1=0, immediate=0b110011)  
    await addi(dut, rd=2, r1=0, immediate=0b101010)  

    await execute(dut,
                  tf=((3 << 1) & 0xF), 
                  se=1,
                  rt=2,
                  nand_op=1)
    
    expected = (~(0b110011 & 0b101010)) & 0xFF
    assert reg(dut, 3) == expected


@cocotb.test()
async def test_shft_left(dut):
    """SHFT left: rd = r1 << r2."""
    clock = Clock(dut.clk, 10, units="us")
    cocotb.start_soon(clock.start())
    await do_reset(dut)

    await addi(dut, rd=1, r1=0, immediate=0b00000011)
    await addi(dut, rd=2, r1=0, immediate=2)  

    # SHFT left (l=1, shft=1, r2_or_imm=0)
    await execute(dut,
                  tf=((3 << 1) & 0xF), 
                  se=1, rt=2,
                  shft=1, l=1, r2_or_imm=0)
    assert reg(dut, 3) == (3 << 2) & 0xFF


@cocotb.test()
async def test_shft_right(dut):
    """SHFT right: rd = r1 >> r2."""
    clock = Clock(dut.clk, 10, units="us")
    cocotb.start_soon(clock.start())
    await do_reset(dut)

    await addi(dut, rd=1, r1=0, immediate=0b00100000) 
    await addi(dut, rd=2, r1=0, immediate=2)  

    # SHFT right (l=0, shft=1, r2_or_imm=0)
    await execute(dut,
                  tf=((3 << 1) & 0xF),
                  se=1, rt=2,
                  shft=1, l=0, r2_or_imm=0)
    assert reg(dut, 3) == 32 >> 2


@cocotb.test()
async def test_shfti(dut):
    """SHFTI: rd = r1 << imm (l=1) or r1 >> imm (l=0)."""
    clock = Clock(dut.clk, 10, units="us")
    cocotb.start_soon(clock.start())
    await do_reset(dut)

    await addi(dut, rd=1, r1=0, immediate=0b00001000)  # r1 = 8

    # SHFTI left by 3 (opcode 111: shft=1, r2_or_imm=1)
    await execute(dut,
                  tf=((2 << 1) & 0xF),
                  se=1, imm=3,
                  shft=1, l=1, r2_or_imm=1)
    assert reg(dut, 2) == (8 << 3) & 0xFF


@cocotb.test()
async def test_blt_taken(dut):
    """BLT taken: r1 < r2, so pc_we fires and pc_new_addr = new_addr + ro."""
    clock = Clock(dut.clk, 10, units="us")
    cocotb.start_soon(clock.start())
    await do_reset(dut)

    await addi(dut, rd=1, r1=0, immediate=3) 
    await addi(dut, rd=2, r1=0, immediate=10)

    await execute(dut,
                  tf=0b0101, 
                  se=1, rt=2,
                  new_addr=100)
    assert dut.pc_we.value == 1
    assert int(dut.pc_new_addr.value) == 100 + 2


@cocotb.test()
async def test_blt_not_taken(dut):
    """BLT not taken: r1 >= r2, so pc_we stays 0."""
    clock = Clock(dut.clk, 10, units="us")
    cocotb.start_soon(clock.start())
    await do_reset(dut)

    await addi(dut, rd=1, r1=0, immediate=10)
    await addi(dut, rd=2, r1=0, immediate=3) 

    await execute(dut,
                  tf=0b0101,
                  se=1, rt=2,
                  new_addr=100)
    assert dut.pc_we.value == 0


@cocotb.test()
async def test_store(dut):
    """STORE: lsi_begin fires, is_store=1, correct addr and value driven."""
    clock = Clock(dut.clk, 10, unit="us") # Fixed 'unit'
    cocotb.start_soon(clock.start())
    await do_reset(dut)

    await addi(dut, rd=1, r1=0, immediate=42) 
    await addi(dut, rd=2, r1=0, immediate=60)  

    # STORE: store=1, ra=tf[3:1]=rd=2 (address reg), rv=se=1 (value reg)
    async def respond_to_lsi():
        for _ in range(20):
            await RisingEdge(dut.clk)
            if dut.lsi_begin.value == 1:
                assert dut.is_store.value  == 1
                assert int(dut.lsi_addr.value) == 60 
                assert int(dut.store_val.value) == 42
                await RisingEdge(dut.clk)
                dut.lsi_done.value = 1
                await RisingEdge(dut.clk)
                dut.lsi_done.value = 0
                return
        raise RuntimeError("lsi_begin never fired")

    cocotb.start_soon(respond_to_lsi())
    await execute(dut,
                  store=1,
                  tf=((2 << 1) & 0xF), 
                  se=1)               


@cocotb.test()
async def test_load(dut):
    """LOAD: after lsi_done, load_val written into rv register."""
    clock = Clock(dut.clk, 10, units="us")
    cocotb.start_soon(clock.start())
    await do_reset(dut)

    await addi(dut, rd=1, r1=0, immediate=50) 

    # LOAD: load=1, ra=tf[3:1]=1 (address reg), rv=se=2 (dest reg)
    async def respond_to_lsi():
        for _ in range(20):
            await RisingEdge(dut.clk)
            if dut.lsi_begin.value == 1:
                assert dut.is_store.value == 0
                assert int(dut.lsi_addr.value) == 50
                dut.load_val.value = 99
                await RisingEdge(dut.clk)
                dut.lsi_done.value = 1
                await RisingEdge(dut.clk)
                dut.lsi_done.value = 0
                return
        raise RuntimeError("lsi_begin never fired")

    cocotb.start_soon(respond_to_lsi())
    await execute(dut,
                  load=1,
                  tf=((1 << 1) & 0xF), 
                  se=2)       

    assert reg(dut, 2) == 99
