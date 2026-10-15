#!/bin/bash
# Build the hilbert Psi4 plugin against the qed-psi4 env's Psi4 (run via `pixi run -e qed-psi4 build-hilbert`).
# Out of tree: build/hilbert/objdir. Importable package: build/hilbert/pkg/hilbert (symlinks to the
# source __init__.py / pymodule.py plus the built hilbert.so), put on PYTHONPATH by scripts/activate/hilbert.sh.
# libsdp and liblbfgs come from the pinned submodules in src/deps (the upstream liblbfgs fetch has no tag);
# TiledArray (WITH_TA) is fetched at its pinned commit. Rebuild whenever pixi.lock changes psi4.
set -euo pipefail
R=${PIXI_PROJECT_ROOT:?run through pixi}
S=$R/src/hilbert
B=$R/build/hilbert
JOBS=${JOBS:-6}
EXTRA_CXX=""
if [ "$(uname -s)" = Darwin ]; then
  EXTRA_CXX="-stdlib=libc++ -D_LIBCPP_ENABLE_CXX20_REMOVED_SHARED_PTR_UNIQUE"   # as in hilbert's BUILD_MACOS.md
  # BTAS (fetched by TiledArray) specializes std::make_unsigned; clang >= 21 rejects that by default
  EXTRA_CXX="$EXTRA_CXX -Wno-invalid-specialization"
fi
mkdir -p "$B"
echo "== configure ($(date))"
cmake -C "$CONDA_PREFIX/share/cmake/psi4/psi4PluginCache.cmake" \
  -DCMAKE_PREFIX_PATH="$CONDA_PREFIX" \
  -DCMAKE_BUILD_TYPE=Release \
  -DWITH_TA=ON \
  -DFETCHCONTENT_SOURCE_DIR_LIBSDP_EXTERNAL="$R/src/deps/libsdp" \
  -DFETCHCONTENT_SOURCE_DIR_LIBLBFGS_EXTERNAL="$R/src/deps/liblbfgs" \
  -DFETCHCONTENT_UPDATES_DISCONNECTED=ON \
  -DCMAKE_C_COMPILER="$(which mpicc)" -DCMAKE_CXX_COMPILER="$(which mpicxx)" -DCMAKE_Fortran_COMPILER="$(which mpifort)" \
  -DCMAKE_CXX_FLAGS="$EXTRA_CXX" \
  -DCMAKE_INSTALL_PREFIX="$B/unused-install" \
  -G Ninja -S "$S" -B "$B/objdir"
echo "== build -j$JOBS ($(date))"
cmake --build "$B/objdir" -j "$JOBS"
echo "== assemble package ($(date))"
mkdir -p "$B/pkg/hilbert"
ln -sf "$S/__init__.py" "$S/pymodule.py" "$B/pkg/hilbert/"
so=$(find "$B/objdir" -maxdepth 1 -name 'hilbert*.so' | head -1)
[ -n "$so" ] || { echo "hilbert.so not found in $B/objdir"; exit 1; }
ln -sf "$so" "$B/pkg/hilbert/hilbert.so"
ls -l "$B/pkg/hilbert"
echo "== done ($(date))"
