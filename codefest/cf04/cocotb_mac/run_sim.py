"""
run_sim.py — cocotb 2.x runner for Icarus Verilog on Windows (no make needed).
Usage:  python run_sim.py        (from inside the .venv or any Python with cocotb)
"""

import os
import subprocess
import sys
from pathlib import Path

# ── locate the venv Python that has cocotb ───────────────────────────────────
SCRIPT_DIR  = Path(__file__).parent.resolve()
VENV_PYTHON = SCRIPT_DIR / ".venv" / "Scripts" / "python.exe"

# If we're not already running the venv python, re-exec with it.
if VENV_PYTHON.exists() and Path(sys.executable).resolve() != VENV_PYTHON.resolve():
    os.execv(str(VENV_PYTHON), [str(VENV_PYTHON)] + sys.argv)

# ── paths ────────────────────────────────────────────────────────────────────
HDL_DIR    = SCRIPT_DIR.parent / "hdl"
# Use the iverilog-compatible local copy (same logic; cast syntax fixed)
VERILOG    = SCRIPT_DIR / "mac_correct_iv.sv"
TOP        = "mac"
MODULE     = "test_mac"
BUILD_DIR  = SCRIPT_DIR / "sim_build"
VVP_FILE   = BUILD_DIR / "sim.vvp"
RESULTS    = SCRIPT_DIR / "results.xml"

if not VERILOG.exists():
    sys.exit(f"ERROR: HDL file not found: {VERILOG}")

BUILD_DIR.mkdir(exist_ok=True)

# ── cocotb config ────────────────────────────────────────────────────────────
import subprocess as sp

def cocotb_config(*args):
    result = sp.run(
        [sys.executable, "-m", "cocotb._cocotb_config"] + list(args),
        capture_output=True, text=True
    )
    if result.returncode != 0:
        # Fall back to cocotb-config executable
        cfg_exe = SCRIPT_DIR / ".venv" / "Scripts" / "cocotb-config.exe"
        result = sp.run([str(cfg_exe)] + list(args), capture_output=True, text=True)
    return result.stdout.strip()

# Get paths via cocotb-config
cfg_exe = SCRIPT_DIR / ".venv" / "Scripts" / "cocotb-config.exe"
lib_dir     = sp.run([str(cfg_exe), "--lib-dir"],             capture_output=True, text=True).stdout.strip()
libpython   = sp.run([str(cfg_exe), "--libpython"],           capture_output=True, text=True).stdout.strip()

# VPI plugin: cocotbvpi_icarus.vpl  (Windows DLL with .vpl extension)
VPI_LIB_DIR = Path(lib_dir)
VPI_NAME    = "cocotbvpi_icarus"          # vvp strips .vpl automatically on Windows

print(f"[run_sim] lib_dir    = {VPI_LIB_DIR}")
print(f"[run_sim] libpython  = {libpython}")
print(f"[run_sim] HDL        = {VERILOG}")
print()

# ── step 1: compile ───────────────────────────────────────────────────────────
compile_cmd = [
    "iverilog",
    "-o", str(VVP_FILE),
    "-s", TOP,
    "-g2012",
    str(VERILOG),
]
print("[run_sim] Compiling:", " ".join(compile_cmd))
result = sp.run(compile_cmd, capture_output=True, text=True)
if result.returncode != 0:
    print("COMPILE ERROR:")
    print(result.stdout)
    print(result.stderr)
    sys.exit(1)
print("[run_sim] Compile OK\n")

# ── step 2: simulate ──────────────────────────────────────────────────────────
sim_env = os.environ.copy()
sim_env.update({
    # cocotb 2.x required vars
    "COCOTB_TEST_MODULES":     MODULE,   # cocotb 2.0 uses plural form
    "COCOTB_TOPLEVEL":         TOP,
    "COCOTB_RESULTS_FILE":     str(RESULTS),
    "LIBPYTHON_LOC":           libpython,
    "PYGPI_PYTHON_BIN":        sys.executable,   # cocotb 2.0: path to Python
    "PYTHONPATH":              str(SCRIPT_DIR) + os.pathsep + sim_env.get("PYTHONPATH", ""),
    "PYTHONDONTWRITEBYTECODE": "1",
})

sim_cmd = [
    "vvp",
    "-M", str(VPI_LIB_DIR),
    "-m", VPI_NAME,
    str(VVP_FILE),
]
print("[run_sim] Simulating:", " ".join(sim_cmd))
result = sp.run(sim_cmd, env=sim_env, cwd=str(BUILD_DIR))

# ── step 3: print results summary ─────────────────────────────────────────────
if RESULTS.exists():
    import xml.etree.ElementTree as ET
    tree = ET.parse(RESULTS)
    root = tree.getroot()
    print("\n" + "="*60)
    print("  TEST RESULTS SUMMARY")
    print("="*60)
    passed = failed = errors = skipped = 0
    for tc in root.iter("testcase"):
        name     = tc.get("name", "?")
        failures = tc.findall("failure")
        err_els  = tc.findall("error")
        skip_els = tc.findall("skipped")
        if failures:
            status = "FAIL"
            failed += 1
        elif err_els:
            status = "ERROR"
            errors += 1
        elif skip_els:
            status = "SKIP"
            skipped += 1
        else:
            status = "PASS"
            passed += 1
        time = tc.get("time", "")
        print(f"  [{status:5s}]  {name:<40s}  {time}s")
    print("-"*60)
    total = passed + failed + errors + skipped
    print(f"  Total: {total}  Passed: {passed}  Failed: {failed}  Errors: {errors}  Skipped: {skipped}")
    print("="*60)
else:
    print("\n[run_sim] Warning: results.xml not found — check sim output above.")

sys.exit(result.returncode)
