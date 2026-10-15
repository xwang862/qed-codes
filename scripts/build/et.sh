#!/bin/bash
# Build eT out of tree: copy src/eT (with its runtest/pFUnit submodules) to build/eT/src, because setup.py
# autogenerates Fortran files inside src/; configure there with libcint (install/libcint), 32-bit integers
# and OpenBLAS; build directory build/eT/build. Run via `pixi run -e qed-compiled build-et`.
set -euo pipefail
R=${PIXI_PROJECT_ROOT:?run through pixi}
CC=${CC:-cc}; CXX=${CXX:-c++}; FC=${FC:-gfortran}     # conda-forge compilers no longer export these
B=$R/build/eT
mkdir -p "$B"
rsync -a --delete --exclude .git "$R/src/eT/" "$B/src/"
OMP=--omp
if [ "$(uname -s)" = Darwin ]; then
  OMP=--no-omp     # clang C/C++ with gfortran: avoid mixing libomp and libgomp
fi
cd "$B/src"
python ./setup.py "$B/build" -clean -type Release -int-lib libcint -lc "$R/install/libcint" --int32 $OMP \
  --blas-type OPENBLAS -FC "$FC" -CC "$CC" -CXX "$CXX" \
  -cmake-flags "-DCMAKE_PREFIX_PATH=$CONDA_PREFIX"
cmake --build "$B/build" -j "${JOBS:-6}"
ls -l "$B/build/eT" "$B/build/eT_launch.py" 2>/dev/null || ls -l "$B/build" | head
