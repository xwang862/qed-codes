#!/bin/bash
# eT's own shortest QED tests via ctest/runtest in the build copy: qed_hf_polarization and sc_qed_hf.
source "$(dirname "$0")/_common.sh" et
cd "$R/build/eT/build"
ctest --output-on-failure -R '^(qed_hf_polarization|sc_qed_hf)$'
