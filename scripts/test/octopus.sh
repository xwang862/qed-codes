#!/bin/bash
# Octopus's own short QEDFT tests (photon KLI in 1D; pxLDA hydrogen in 3D) via ctest in build/octopus.
source "$(dirname "$0")/_common.sh" octopus
cd "$R/build/octopus"
ctest -N | /usr/bin/grep -iE "oep-photons|qedft-breit" || true
ctest --output-on-failure -R 'functionals/(17-oep-photons|21-qedft-breit-3d)'
