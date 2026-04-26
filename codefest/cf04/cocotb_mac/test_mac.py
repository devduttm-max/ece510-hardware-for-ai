"""
cocotb testbench for mac (Multiply-Accumulate) unit.
DUT: mac_correct_iv.sv  (iverilog-compatible copy of mac_correct.sv)
Interface:
  clk  - clock
  rst  - synchronous reset (active high)
  a    - signed 8-bit input
  b    - signed 8-bit input
  out  - signed 32-bit accumulated output

Timing convention
-----------------
Drive inputs any time before a tick().
tick() advances ONE rising edge, then waits 1 ps for non-blocking
assignments to commit, so reading dut.out.value afterward is stable.

Clock management
----------------
Each test cancels any previous Clock task before starting its own so that
only a single clock driver runs at a time.
"""

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, Timer

_clock_task = None   # module-level handle so each test can cancel the last one


def start_clock(dut):
    """Cancel any previous clock task and start a fresh one. Returns the task."""
    global _clock_task
    if _clock_task is not None:
        _clock_task.cancel()
    _clock_task = cocotb.start_soon(Clock(dut.clk, 10, unit="ns").start())
    return _clock_task


async def tick(dut):
    """Wait for the next rising edge, then let NB-assigns settle (1 ps)."""
    await RisingEdge(dut.clk)
    await Timer(1, unit="ps")


async def reset_dut(dut, cycles=2):
    """Apply synchronous reset: force a=b=0 and hold rst high for `cycles` edges."""
    dut.rst.value = 1
    dut.a.value = 0
    dut.b.value = 0
    for _ in range(cycles):
        await tick(dut)
    dut.rst.value = 0
    # Drive zero during the idle post-reset cycle so nothing accumulates.
    dut.a.value = 0
    dut.b.value = 0
    await tick(dut)


@cocotb.test()
async def test_reset(dut):
    """After reset, output must be 0."""
    start_clock(dut)
    await reset_dut(dut)
    got = dut.out.value.to_signed()
    assert got == 0, f"Expected 0 after reset, got {got}"
    cocotb.log.info("PASS: reset clears accumulator")


@cocotb.test()
async def test_single_accumulation(dut):
    """Single MAC cycle: out should equal a*b after one clock."""
    start_clock(dut)
    await reset_dut(dut)

    dut.a.value = 3
    dut.b.value = 4
    await tick(dut)   # out = 0 + 3*4 = 12

    expected = 3 * 4
    got = dut.out.value.to_signed()
    assert got == expected, f"Expected {expected}, got {got}"
    cocotb.log.info(f"PASS: single accumulation 3*4 = {got}")


@cocotb.test()
async def test_accumulation_sequence(dut):
    """Accumulate several products and verify running sum each cycle."""
    start_clock(dut)
    await reset_dut(dut)

    inputs = [(2, 3), (5, 7), (-4, 6), (10, -2), (0, 100)]
    expected_acc = 0

    for a_val, b_val in inputs:
        dut.a.value = a_val
        dut.b.value = b_val
        await tick(dut)
        expected_acc += a_val * b_val
        got = dut.out.value.to_signed()
        assert got == expected_acc, (
            f"After a={a_val} b={b_val}: expected {expected_acc}, got {got}"
        )

    cocotb.log.info(f"PASS: accumulation sequence, final value = {expected_acc}")


@cocotb.test()
async def test_negative_inputs(dut):
    """Verify signed arithmetic with negative operands."""
    start_clock(dut)
    await reset_dut(dut)

    dut.a.value = -8
    dut.b.value = -8
    await tick(dut)
    expected = (-8) * (-8)  # 64
    got = dut.out.value.to_signed()
    assert got == expected, f"Expected {expected}, got {got}"

    dut.a.value = -1
    dut.b.value = 127
    await tick(dut)
    expected += (-1) * 127
    got = dut.out.value.to_signed()
    assert got == expected, f"Expected {expected}, got {got}"

    cocotb.log.info(f"PASS: negative inputs, final value = {got}")


@cocotb.test()
async def test_reset_mid_accumulation(dut):
    """Reset in the middle of accumulation must clear the accumulator."""
    start_clock(dut)
    await reset_dut(dut)

    # Accumulate something
    dut.a.value = 10
    dut.b.value = 10
    await tick(dut)   # out = 100

    # Apply reset; also zero inputs so the idle cycle doesn't re-accumulate
    dut.rst.value = 1
    dut.a.value = 0
    dut.b.value = 0
    await tick(dut)   # out resets to 0
    dut.rst.value = 0
    await tick(dut)   # idle cycle: a=0, b=0, out stays 0

    got = dut.out.value.to_signed()
    assert got == 0, f"Expected 0 after mid-run reset, got {got}"
    cocotb.log.info("PASS: mid-accumulation reset clears output")


@cocotb.test()
async def test_max_positive(dut):
    """Max positive 8-bit signed inputs: 127 * 127 = 16129."""
    start_clock(dut)
    await reset_dut(dut)

    dut.a.value = 127
    dut.b.value = 127
    await tick(dut)
    expected = 127 * 127  # 16129
    got = dut.out.value.to_signed()
    assert got == expected, f"Expected {expected}, got {got}"
    cocotb.log.info(f"PASS: max positive 127*127 = {got}")
