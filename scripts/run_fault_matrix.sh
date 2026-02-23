#!/usr/bin/env bash
set -euo pipefail

mkdir -p build tb

PYTHON_BIN="python3"
if ! command -v python3 >/dev/null 2>&1 || ! python3 --version >/dev/null 2>&1; then
  PYTHON_BIN="python"
fi

IVERILOG_BIN="iverilog"
VVP_BIN="vvp"

if ! command -v iverilog >/dev/null 2>&1; then
  if [ -x "./tools/iverilog/mingw64/bin/iverilog.exe" ]; then
    IVERILOG_BIN="./tools/iverilog/mingw64/bin/iverilog.exe"
    VVP_BIN="./tools/iverilog/mingw64/bin/vvp.exe"
    export PATH="$(pwd)/tools/iverilog/mingw64/bin:${PATH}"
  else
    echo "[ERR] iverilog not found. Install Icarus Verilog (e.g., brew install icarus-verilog)" >&2
    exit 1
  fi
fi

# Build and run the fault matrix sweep testbench
"${IVERILOG_BIN}" -g2012 -s tb_fault_matrix -o build/tb_fault_matrix \
  aes128_core_masked.sv \
  trng.sv \
  power_noise.sv \
  aes128_hardened_top.sv \
  tb/tb_fault_matrix.sv

"${VVP_BIN}" build/tb_fault_matrix

# Summarize results
if command -v "${PYTHON_BIN}" >/dev/null 2>&1; then
  "${PYTHON_BIN}" scripts/summarize_fault_matrix.py tb/fault_matrix.csv || true
fi

echo "[INFO] Fault matrix sweep done. CSV at tb/fault_matrix.csv"
