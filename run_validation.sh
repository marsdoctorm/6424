#!/usr/bin/env bash
set -euo pipefail

mkdir -p build

PYTHON_BIN="python3"
if ! command -v python3 >/dev/null 2>&1 || ! python3 --version >/dev/null 2>&1; then
  PYTHON_BIN="python"
fi

"${PYTHON_BIN}" scripts/gen_vectors.py --count 20 --output tb/generated_vectors.txt

IVERILOG_BIN="iverilog"
VVP_BIN="vvp"

if ! command -v iverilog >/dev/null 2>&1; then
  IVERILOG_BIN="./tools/iverilog/mingw64/bin/iverilog.exe"
  VVP_BIN="./tools/iverilog/mingw64/bin/vvp.exe"
  export PATH="$(pwd)/tools/iverilog/mingw64/bin:${PATH}"
fi

"${IVERILOG_BIN}" -g2012 -s tb_aes_hardened -o build/tb_aes \
  rtl/aes128_core.sv \
  rtl/power_noise.sv \
  rtl/aes128_hardened_top.sv \
  tb/tb_aes_hardened.sv

"${VVP_BIN}" build/tb_aes
