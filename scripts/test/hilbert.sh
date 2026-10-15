#!/bin/bash
# hilbert's own test tests/qed_ccsd_ta-1 (H2O/STO-3G, QED-CCSD-21 without vs with TiledArray, 3 polarizations).
source "$(dirname "$0")/_common.sh" hilbert
cp "$R/src/hilbert/tests/qed_ccsd_ta-1/input.dat" .
psi4 input.dat output.dat -n 1
/usr/bin/grep -E "Passed|FAILED|total energy" output.dat || true
