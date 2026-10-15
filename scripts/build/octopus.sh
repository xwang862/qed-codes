#!/bin/bash
# Build Octopus (serial, no OpenMP, OCTOPUS_DEBUG=OFF) out of tree in build/octopus and install to
# install/octopus. Libxc and Spglib come from Octopus's own pinned submodules (third_party/) instead of
# FetchContent downloads. Run via `pixi run -e qed-compiled build-octopus`.
set -euo pipefail
R=${PIXI_PROJECT_ROOT:?run through pixi}
CC=${CC:-cc}; CXX=${CXX:-c++}; FC=${FC:-gfortran}     # conda-forge compilers no longer export these
S=$R/src/octopus
CPP_FLAG=()
if [ "$(uname -s)" = Darwin ]; then
  # Octopus preprocesses Fortran with GNU cpp; the env's plain `cpp` is clang's, the gfortran toolchain's is GNU
  CPP_FLAG=(-DCPP_EXECUTABLE="$(ls "$CONDA_PREFIX"/bin/*-apple-darwin*-cpp | head -1)")
fi
cmake -S "$S" -B "$R/build/octopus" -G Ninja \
  -DCMAKE_BUILD_TYPE=Release -DOCTOPUS_DEBUG=OFF -DOCTOPUS_MPI=OFF -DOCTOPUS_OpenMP=OFF \
  -DCMAKE_INSTALL_PREFIX="$R/install/octopus" -DCMAKE_PREFIX_PATH="$CONDA_PREFIX" \
  -DFETCHCONTENT_SOURCE_DIR_LIBXC="$S/third_party/Libxc" \
  -DFETCHCONTENT_SOURCE_DIR_SPGLIB="$S/third_party/Spglib" \
  -DFETCHCONTENT_TRY_FIND_PACKAGE_MODE=NEVER \
  -DFETCHCONTENT_FULLY_DISCONNECTED=ON \
  -DCMAKE_C_COMPILER="$CC" -DCMAKE_CXX_COMPILER="$CXX" -DCMAKE_Fortran_COMPILER="$FC" "${CPP_FLAG[@]}"
cmake --build "$R/build/octopus" -j "${JOBS:-6}"
cmake --install "$R/build/octopus"
ls -l "$R/install/octopus/bin/octopus"
