#!/usr/bin/env bash
# run_validation.sh
# Usage:
#   ./run_validation.sh              # default: 200 random + boundary vectors
#   ./run_validation.sh --count 500  # 500 random + boundary vectors
#   ./run_validation.sh --count 20 --no-boundary
set -euo pipefail

# ── Parse arguments ────────────────────────────────────────────────────────────
COUNT=200
BOUNDARY_FLAG=""
for arg in "$@"; do
  case $arg in
    --count) shift ;;           # handled below
    --count=*) COUNT="${arg#*=}" ;;
    --no-boundary) BOUNDARY_FLAG="--no-boundary" ;;
  esac
done
# Simple positional parse for --count <N>
args=("$@")
for i in "${!args[@]}"; do
  if [[ "${args[$i]}" == "--count" ]]; then
    COUNT="${args[$((i+1))]}"
  fi
done

echo "========================================"
echo "  AES-128 Hardened Core Validation"
echo "  Random vectors : ${COUNT}"
echo "  Boundary vecs  : $([ -z "$BOUNDARY_FLAG" ] && echo enabled || echo disabled)"
echo "========================================"

mkdir -p build tb

# ── Python binary ──────────────────────────────────────────────────────────────
PYTHON_BIN="python3"
if ! command -v python3 >/dev/null 2>&1; then
  PYTHON_BIN="python"
fi

# ── Generate vectors ───────────────────────────────────────────────────────────
echo ""
echo "[1/3] Generating test vectors..."
T_GEN_START=$(date +%s%N)

"${PYTHON_BIN}" gen_vectors.py \
  --count "${COUNT}" \
  --output tb/generated_vectors.txt \
  ${BOUNDARY_FLAG}

T_GEN_END=$(date +%s%N)
GEN_MS=$(( (T_GEN_END - T_GEN_START) / 1000000 ))
TOTAL_VECTORS=$(wc -l < tb/generated_vectors.txt)
echo "  Done: ${TOTAL_VECTORS} vectors in ${GEN_MS} ms"

# ── Find iverilog / vvp ────────────────────────────────────────────────────────
IVERILOG_BIN="iverilog"
VVP_BIN="vvp"
if ! command -v iverilog >/dev/null 2>&1; then
  IVERILOG_BIN="./tools/iverilog/mingw64/bin/iverilog.exe"
  VVP_BIN="./tools/iverilog/mingw64/bin/vvp.exe"
  export PATH="$(pwd)/tools/iverilog/mingw64/bin:${PATH}"
fi

# ── Compile ────────────────────────────────────────────────────────────────────
echo ""
echo "[2/3] Compiling RTL..."
T_COMP_START=$(date +%s%N)

"${IVERILOG_BIN}" -g2012 -s tb_aes_hardened -o build/tb_aes \
  aes128_core_masked.sv \
  trng.sv \
  power_noise.sv \
  aes128_hardened_top.sv \
  tb_aes_hardened.sv

T_COMP_END=$(date +%s%N)
COMP_MS=$(( (T_COMP_END - T_COMP_START) / 1000000 ))
echo "  Done in ${COMP_MS} ms"

# ── Simulate ───────────────────────────────────────────────────────────────────
echo ""
echo "[3/3] Running simulation..."
T_SIM_START=$(date +%s%N)

SIM_LOG="build/sim_output.log"
"${VVP_BIN}" build/tb_aes 2>&1 | tee "${SIM_LOG}"

T_SIM_END=$(date +%s%N)
SIM_MS=$(( (T_SIM_END - T_SIM_START) / 1000000 ))
TOTAL_S=$(echo "scale=2; ${SIM_MS}/1000" | bc)

# ── Parse results ──────────────────────────────────────────────────────────────
TOTAL_RUN=$(grep -oP "vectors=\K[0-9]+" "${SIM_LOG}" 2>/dev/null || echo "0")
PASS=$(grep -oP "pass=\K[0-9]+" "${SIM_LOG}" 2>/dev/null || echo "0")
FAIL=$(( TOTAL_RUN - PASS ))
if [[ ${TOTAL_RUN} -eq 0 ]]; then
  PASS_RATE="N/A (no summary line found in log)"
else
  PASS_RATE=$(echo "scale=2; ${PASS}*100/${TOTAL_RUN}" | bc)
  PASS_RATE="${PASS_RATE}%"
fi

# ── Results table ──────────────────────────────────────────────────────────────
echo ""
echo "========================================"
echo "           RESULTS SUMMARY"
echo "========================================"
printf "  %-25s %s\n" "Total vectors generated:"  "${TOTAL_VECTORS}"
printf "  %-25s %s\n" "Vectors run in sim:"        "${TOTAL_RUN}"
printf "  %-25s %s\n" "PASS:"                      "${PASS}"
printf "  %-25s %s\n" "FAIL:"                      "${FAIL}"
printf "  %-25s %s\n" "Pass rate:"                 "${PASS_RATE}"
echo "  ----------------------------------------"
printf "  %-25s %s ms\n" "Vector generation time:"  "${GEN_MS}"
printf "  %-25s %s ms\n" "Compilation time:"        "${COMP_MS}"
printf "  %-25s %s s\n"  "Simulation time:"         "${TOTAL_S}"
echo "========================================"

# Save results table to file
RESULTS_FILE="build/results_table.txt"
{
  echo "AES-128 Hardened Core — Validation Results"
  echo "Date: $(date)"
  echo "Random count: ${COUNT}  |  Boundary vectors: $([ -z "$BOUNDARY_FLAG" ] && echo enabled || echo disabled)"
  echo ""
  echo "Metric                    Value"
  echo "------------------------  ----------"
  printf "%-25s %s\n" "Total vectors generated:"  "${TOTAL_VECTORS}"
  printf "%-25s %s\n" "Vectors run in sim:"       "${TOTAL_RUN}"
  printf "%-25s %s\n" "PASS:"                     "${PASS}"
  printf "%-25s %s\n" "FAIL:"                     "${FAIL}"
  printf "%-25s %s\n" "Pass rate:"                "${PASS_RATE}"
  echo ""
  echo "Timing"
  echo "------------------------  ----------"
  printf "%-25s %s ms\n" "Vector generation:"      "${GEN_MS}"
  printf "%-25s %s ms\n" "Compilation:"            "${COMP_MS}"
  printf "%-25s %s s\n"  "Simulation:"             "${TOTAL_S}"
} > "${RESULTS_FILE}"

echo ""
echo "Results table saved to: ${RESULTS_FILE}"
echo "Simulation log saved to: ${SIM_LOG}"