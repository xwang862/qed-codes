#!/bin/bash
# psi4polaritonic's CQED_RHF.py example (H2O/cc-pVDZ, lambda = (0, 0, 0.05)); prints its reference value.
source "$(dirname "$0")/_common.sh" psi4polaritonic
python "$R/src/psi4polaritonic/CQED_RHF.py"
