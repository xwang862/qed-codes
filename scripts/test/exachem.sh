#!/bin/bash
# Inside the container: ExaChem's own QED test input (inputs/ci/h2o_qed.json, H2O/cc-pVTZ QED-HF + QED-CCSD)
# with mpirun -n 2, compared with its reference output by the package's compare script.
set -euo pipefail
R=${PIXI_PROJECT_ROOT:?run through pixi}
W=${EXACHEM_WORK:-/work}/test-exachem
rm -rf "$W"; mkdir -p "$W"; cd "$W"
export OMP_NUM_THREADS=1
cp "$R/src/exachem/inputs/ci/h2o_qed.json" .
mpirun -n 2 "${EXACHEM_WORK:-/work}/install/exachem/bin/ExaChem" h2o_qed.json
# Compare with the package's reference output. (ci/scripts/compare_results.py only works on a full CI output
# directory: its file mode fails on its own list of optional references.) Same quantities and tolerance (1e-9).
cur=$(find . -name 'h2o_qed.cc-pvtz.ccsd.json' | head -1)
python - "$R/src/exachem/ci/reference_output/h2o_qed.cc-pvtz.ccsd.json" "$cur" <<'PY'
import json, sys
ref, cur = (json.load(open(f))["output"] for f in sys.argv[1:3])
pairs = [("SCF final_energy", ref["SCF"]["final_energy"], cur["SCF"]["final_energy"]),
         ("CCSD correlation", ref["CCSD"]["final_energy"]["correlation"], cur["CCSD"]["final_energy"]["correlation"]),
         ("CCSD total", ref["CCSD"]["final_energy"]["total"], cur["CCSD"]["final_energy"]["total"])]
bad = 0
for name, a, b in pairs:
    print("%-18s ref %.12f  cur %.12f  diff %.2e" % (name, a, b, b - a))
    bad += abs(b - a) > 1e-9
sys.exit(1 if bad else 0)
PY
