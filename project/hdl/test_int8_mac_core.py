import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, Timer

@cocotb.test()
async def test_reset(dut):
    """Test that reset clears accumulator"""
    cocotb.start_soon(Clock(dut.clk, 10, units="ns").start())
    dut.rst.value = 1
    dut.en.value = 0
    dut.activation.value = 0
    dut.weight.value = 0
    await RisingEdge(dut.clk)
    await Timer(1, units="ps")
    assert dut.acc_out.value.signed_integer == 0

@cocotb.test()
async def test_single_mac(dut):
    """Test single MAC operation: activation=3, weight=5 -> acc=15"""
    cocotb.start_soon(Clock(dut.clk, 10, units="ns").start())
    dut.rst.value = 1
    dut.en.value = 0
    await RisingEdge(dut.clk)
    dut.rst.value = 0
    dut.en.value = 1
    dut.activation.value = 3
    dut.weight.value = 5
    await RisingEdge(dut.clk)
    await Timer(1, units="ps")
    assert dut.acc_out.value.signed_integer == 15