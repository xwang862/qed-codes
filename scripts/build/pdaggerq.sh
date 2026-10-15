#!/bin/bash
# Build pdaggerq's extension out of tree: copy src/pdaggerq to build/pdaggerq/src (setup.py builds in the
# source tree), then build_ext --inplace there; PYTHONPATH gets build/pdaggerq/src (scripts/activate/pdaggerq.sh).
# CMake FetchContent downloads pybind11 v2.11.1 (pinned tag). Run via `pixi run -e qed-psi4 build-pdaggerq`.
set -euo pipefail
R=${PIXI_PROJECT_ROOT:?run through pixi}
B=$R/build/pdaggerq/src
mkdir -p "$B"
rsync -a --delete --exclude .git --exclude build "$R/src/pdaggerq/" "$B/"
cd "$B"
CMAKE_BUILD_PARALLEL_LEVEL=${JOBS:-6} python setup.py build_ext --inplace
ls -l pdaggerq/_pdaggerq*.so
