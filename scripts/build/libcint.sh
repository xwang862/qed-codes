#!/bin/bash
# Static libcint for eT, built as eT's README prescribes (-DPYPZPX=1 -DMIN_EXPCUTOFF=0.0, static), from the
# pinned submodule src/deps/libcint, out of tree in build/libcint, installed to install/libcint.
# (conda-forge libcint is shared and built without PYPZPX.) Run via `pixi run -e qed-compiled build-libcint`.
set -euo pipefail
R=${PIXI_PROJECT_ROOT:?run through pixi}
CC=${CC:-cc}; CXX=${CXX:-c++}; FC=${FC:-gfortran}     # conda-forge compilers no longer export these
cmake -S "$R/src/deps/libcint" -B "$R/build/libcint" -G Ninja \
  -DCMAKE_BUILD_TYPE=Release -DBUILD_SHARED_LIBS=0 -DPYPZPX=1 -DMIN_EXPCUTOFF=0.0 \
  -DCMAKE_C_COMPILER="$CC" -DCMAKE_INSTALL_PREFIX="$R/install/libcint" -DCMAKE_INSTALL_LIBDIR=lib
cmake --build "$R/build/libcint" -j "${JOBS:-6}" --target install
ls -l "$R/install/libcint/lib/libcint.a"
