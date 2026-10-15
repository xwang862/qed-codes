#!/bin/bash
# pdaggerq examples: plain CCSD energy, then the QED-CCSD-21 equations (symbolic only).
source "$(dirname "$0")/_common.sh" pdaggerq
python "$R/build/pdaggerq/src/examples/ccsd_energy.py"
if [ -f "$R/build/pdaggerq/src/examples/qed_ccsd_21.py" ]; then
  python "$R/build/pdaggerq/src/examples/qed_ccsd_21.py" > qed_ccsd_21.out
  wc -l qed_ccsd_21.out; head -40 qed_ccsd_21.out
fi
