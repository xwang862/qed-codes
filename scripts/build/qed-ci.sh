#!/bin/bash
# Build qed-ci's ctypes library out of tree: copy src/qed-ci to build/qed-ci (its Makefile builds in place
# and the repo ships prebuilt objects), then make there. Run via `pixi run -e qed-psi4 build-qed-ci`.
set -euo pipefail
R=${PIXI_PROJECT_ROOT:?run through pixi}
CC=${CC:-cc}; CXX=${CXX:-c++}; FC=${FC:-gfortran}     # conda-forge compilers no longer export these
B=$R/build/qed-ci
mkdir -p "$B"
rsync -a --delete --exclude .git "$R/src/qed-ci/" "$B/"
cd "$B"
rm -f src/*.o src/cfunctions.so
if [ "$(uname -s)" = Darwin ]; then
  make CC="$CC" BACKEND=accelerate
else
  make CC="$CC" BACKEND=openblas OPENBLAS_PREFIX="$CONDA_PREFIX"
fi
ls -l src/cfunctions.so
