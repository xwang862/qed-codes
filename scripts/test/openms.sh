#!/bin/bash
# OpenMS's own QED-HF test tests/qedhf/01-qed_hf.py (C3H4O2/STO-3G, coherent state and Fock basis).
source "$(dirname "$0")/_common.sh" openms
python "$R/src/OpenMS/tests/qedhf/01-qed_hf.py" -v
