#!/bin/bash
# qed-ci's shortest test (LiH/STO-3G FCI RDMs, no cavity), run in the built copy build/qed-ci.
source "$(dirname "$0")/_common.sh" qed-ci
cd "$R/build/qed-ci"
python -m pytest -p no:cacheprovider -q "tests/test_helperPFCI.py::test_lih_fci_sto3g_rdm_builds_no_cavity"
