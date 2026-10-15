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
# compare_results.py in file mode: reference JSON vs the output JSON ExaChem wrote under <prefix>_files/<scf_type>/json/
cur=$(find . -name 'h2o_qed.cc-pvtz.ccsd.json' | head -1)
python "$R/src/exachem/ci/scripts/compare_results.py" "$R/src/exachem/ci/reference_output/h2o_qed.cc-pvtz.ccsd.json" "$cur"
echo "compare_results.py: h2o_qed.cc-pvtz.ccsd matches the reference"
