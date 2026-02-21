#!/usr/bin/env bash
set -euo pipefail

TEAM_ID="${1:-XX}"
OUT_NAME="HW2 Team${TEAM_ID} Phase1.zip"

rm -f "${OUT_NAME}"

if command -v zip >/dev/null 2>&1; then
  zip -r "${OUT_NAME}" \
    rtl \
    tb \
    scripts \
    tools/iverilog \
    README.md \
    PHASE1_REQUIREMENTS_CHECK.md \
    report_template.md \
    citations.txt \
    work_log.md \
    genai_links \
    -x "*/__pycache__/*" "*/.pytest_cache/*"
else
  export OUT_NAME_ENV="${OUT_NAME}"
  python - <<'PY'
import os
import pathlib
import zipfile

out_name = pathlib.Path(os.environ["OUT_NAME_ENV"])
paths = [
    pathlib.Path("rtl"),
    pathlib.Path("tb"),
    pathlib.Path("scripts"),
    pathlib.Path("tools/iverilog"),
    pathlib.Path("README.md"),
    pathlib.Path("PHASE1_REQUIREMENTS_CHECK.md"),
    pathlib.Path("report_template.md"),
    pathlib.Path("citations.txt"),
    pathlib.Path("work_log.md"),
    pathlib.Path("genai_links"),
]

with zipfile.ZipFile(out_name, "w", compression=zipfile.ZIP_DEFLATED) as zf:
    for p in paths:
        if p.is_file():
            zf.write(p, arcname=str(p))
        else:
            for f in p.rglob("*"):
                if f.is_file():
                    if "__pycache__" in f.parts:
                        continue
                    zf.write(f, arcname=str(f))
PY
fi

echo "Created ${OUT_NAME}"
