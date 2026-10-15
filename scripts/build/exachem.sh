#!/bin/bash
# Inside the container (qed-linux env): TAMM v0.1.0 then ExaChem v0.1.0, release triple with -DCMSB_TAG=v0.1.0.
# Sources are read-only (/qed-codes/src); build trees and the install prefix are on the work volume.
# -DALLOW_CONDA=ON because their CMake refuses to configure when CONDA_PREFIX is set (pixi sets it).
set -euo pipefail
R=${PIXI_PROJECT_ROOT:?run through pixi}
W=${EXACHEM_WORK:-/work}
P=$W/install/exachem
export CC=gcc CXX=g++ FC=gfortran
command -v ar >/dev/null || { echo "no ar on PATH (binutils missing from the qed-linux env?)"; exit 1; }
if [ "${EXACHEM_CLEAN:-0}" = 1 ]; then
  echo "== EXACHEM_CLEAN=1: removing $W/build/tamm $W/build/exachem $P"
  rm -rf "$W/build/tamm" "$W/build/exachem" "$P"
fi
FLAGS=(-DCMAKE_INSTALL_PREFIX="$P" -DMODULES="CC" -DCMSB_TAG=v0.1.0 -DALLOW_CONDA=ON
       -DLINALG_VENDOR=OpenBLAS -DCMAKE_BUILD_TYPE=Release -DBUILD_TESTS=OFF)
echo "== TAMM ($(date))"
cmake -S "$R/src/TAMM" -B "$W/build/tamm" "${FLAGS[@]}"
cmake --build "$W/build/tamm" -j "${JOBS:-4}" --target install
echo "== ExaChem ($(date))"
cmake -S "$R/src/exachem" -B "$W/build/exachem" "${FLAGS[@]}"
cmake --build "$W/build/exachem" -j "${JOBS:-4}" --target install
ls -l "$P/bin/ExaChem"
echo "== done ($(date))"
